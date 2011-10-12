package Dancer::Exception;

use strict;
use warnings;
use Carp;

use Dancer::Exception::Base;

use base qw(Exporter);

our @EXPORT_OK = (qw(try catch continuation register_exception registered_exceptions raise));
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Try::Tiny ();

sub try (&;@) {
    goto &Try::Tiny::try;
}

sub catch (&;@) {
	my ( $block, @rest ) = @_;

    my $continuation_code;
    my @new_rest = grep { ref ne 'Try::Tiny::Catch' or $continuation_code = $$_, 0 } @rest;
    $continuation_code
      and return ( bless( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? $continuation_code->(@_) : $block->(@_);
      },  'Try::Tiny::Catch') , @new_rest);

    return ( bless ( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? die($_) : $block->(@_) ;
      }, 'Try::Tiny::Catch'), @new_rest );
}

sub continuation (&;@) {
	my ( $block, @rest ) = @_;

    my $catch_code;
    my @new_rest = grep { ref ne 'Try::Tiny::Catch' or $catch_code = $$_, 0 } @rest;
    $catch_code 
      and return ( bless( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? $block->(@_) : $catch_code->(@_);
      },  'Try::Tiny::Catch') , @new_rest);

    return ( bless ( \ sub {
          ref && $_->isa('Dancer::Continuation')
            ? $block->(@_) : die($_);
      }, 'Try::Tiny::Catch'), @new_rest );
}

sub raise ($;@) {
    my $exception_name = shift;
    my $exception;
    if ($exception_name =~ s/^\+//) {
        $exception = $exception_name->new(@_);
    } else {
        $exception = "Dancer::Exception::$exception_name"->new(@_);
    }
    $exception->throw();
}

sub register_exception {
    my ($exception_name, %params) = @_;
    my $exception_class = 'Dancer::Exception::' . $exception_name;
    my $path = $exception_class; $path =~ s|::|/|g; $path .= '.pm';

    if (exists $INC{$path}) {
        local $Carp::CarpLevel = $Carp::CarpLevel++;
        'Dancer::Exception::Base::Internal'
            ->new("register_exception failed: $exception_name is already defined")
            ->throw;
    }

    my $message_pattern = $params{message_pattern};
    my $composed_from = $params{composed_from};
    my @composition = map { 'Dancer::Exception::' . $_ } @$composed_from;

    $INC{$path} = __FILE__;
    eval "\@${exception_class}::ISA=qw(Dancer::Exception::Base " . join (' ', @composition) . ');';

    if (defined $message_pattern) {
        no strict 'refs';
        *{"${exception_class}::_message_pattern"} = sub { $message_pattern };
    }

}

sub registered_exceptions {
    sort map { s|/|::|g; s/\.pm$//; $_ } grep { s|^Dancer/Exception/||; } keys %INC;
}

register_exception(@$_) foreach (
    ['Core', message_pattern => 'core - %s'],
    ['Fatal', message_pattern => 'fatal - %s'],
    ['Internal', message_pattern => 'internal - %s'],
);

1;

__END__

=pod

=head1 NAME

Dancer::Exception - class for throwing and catching exceptions

=head1 SYNOPSIS

    use Dancer::Exception qw(:all);

    register_exception('DataProblem',
                        message_pattern => "test message : %s"
                      );

    sub do_stuff {
      raise DataProblem => "we've lost data!";
    }

    try {
      do_stuff()
    } catch {
      # an exception was thrown
      my ($exception) = @_;
      if ($exception->does('DataProblem')) {
        # handle the data problem
        my $message = $exception->message();
      } else {
        $exception->rethrow
      }
    };



=head1 DESCRIPTION

Dancer::Exception is based on L<Try::Tiny>. You can try and catch exceptions,
like in L<Try::Tiny>.

Exceptions are objects, from subclasses of L<Dancer::Exception::Base>.

However, for internal Dancer usage, we introduce a special class of exceptions,
called L<Dancer::Continuation>. Exceptions that are from this class are not
caught with a C<catch> block, but only with a C<continuation>. That's a cheap
way to implement a I<workkflow interruption>. Dancer users should dafely ignore
this feature.

=head2 What it means for Dancer users

Users can throw and catch exceptions, using C<try> and C<catch>. They can reuse
some Dancer core exceptions (C<Dancer::Exception::Base::*>), but they can also
create new exception classes, and use them for their own usage. That way it's
easy to use custom exceptions in a Dancer application. Have a look at
C<register_exception>, C<raise>, and the methods in L<Dancer::Exception::Base>.

=head1 METHODS

=head2 try

Same as in L<Try::Tiny>

=head2 catch

Same as in L<Try::Tiny>. The exception can be retrieved as the first parameter:

    try { ... } catch { my ($exception) = @_; };

=head2 continuation

To be used by Dancer developers only, in Dancer core code.

=head2 raise

  # raise Dancer::Exception::Base::MyException
  raise MyException => "user $username is unknown";

  # raise My::Own::Exception
  raise '+My::Own::Exception' => "user $username is unknown";

raise provides an easy way to throw an exception. First parameter is the name
of the exception class, without the C<Dancer::Exception::Base::> prefix. other
parameters are stored as I<raising arguments> in the exception. Usually the
parameters is an exception message, but it's left to the exception class
implementation.

If the exception calss name starts with a C<+>, then the
C<Dancer::Exception::Base::> won't be added. This allows to build their own
exception class herarchy, but you should first look at C<register_exception>
before implementing your own class hierarchy. If you really wish to build your
own exception class hierarchy, we recommend that all exceptions inherits of
L<Dancer::Exception::Base>. Or at least it should implement its methods

=head2 register_exception

This method allows to register custom exceptions, usable by Dancer users in
their route code (actually pretty much everywhere).

  # simple exception
  register_exception ('InvalidCredentials',
                      message_pattern => "invalid credentials : %s",
                     );

This registers a new custom exception. To use it, do:

  raise InvalidCredentials => "user Herbert not found";

The exception message can be retrieved with the C<$exception->message> method, and we'll be
C<"invalid credentials : user Herbert not found"> (see methods in L<Dancer::Exception::Base>)

  # complex exception
  register_exception ('InvalidLogin',
                      composed_from => [qw(Fatal InvalidCredentials)],
                      message_pattern => "wrong login or password",
                   );

In this example, the C<InvalidLogin> is built as a composition of the C<Fatal>
and C<InvalidCredentials> exceptions. See the C<does> method in
L<Dancer::Exception::Base>.

=head2 registered_exceptions

  my @exception_classes = registered_exceptions;

Returns the list of exception class names. It will list core exceptions C<and>
custom exceptions (except the one you've registered with a leading C<+>, see
C<register_exception>). The list is sorted.
