use strict;
use warnings;
use Test::More 0.88;
# This is a relatively nice way to avoid Test::NoWarnings breaking our
# expectations by adding extra tests, without using no_plan.  It also helps
# avoid any other test module that feels introducing random tests, or even
# test plans, is a nice idea.
our $success = 0;
END { $success && done_testing; }

# List our own version used to generate this
my $v = "\nGenerated by Dist::Zilla::Plugin::ReportVersions::Tiny v1.10\n";

eval {                     # no excuses!
    # report our Perl details
    my $want = '5.006';
    $v .= "perl: $] (wanted $want) on $^O from $^X\n\n";
};
defined($@) and diag("$@");

# Now, our module version dependencies:
sub pmver {
    my ($module, $wanted) = @_;
    $wanted = " (want $wanted)";
    my $pmver;
    eval "require $module;";
    if ($@) {
        if ($@ =~ m/Can't locate .* in \@INC/) {
            $pmver = 'module not found.';
        } else {
            diag("${module}: $@");
            $pmver = 'died during require.';
        }
    } else {
        my $version;
        eval { $version = $module->VERSION; };
        if ($@) {
            diag("${module}: $@");
            $pmver = 'died during VERSION check.';
        } elsif (defined $version) {
            $pmver = "$version";
        } else {
            $pmver = '<undef>';
        }
    }

    # So, we should be good, right?
    return sprintf('%-45s => %-10s%-15s%s', $module, $pmver, $wanted, "\n");
}

eval { $v .= pmver('Carp','any version') };
eval { $v .= pmver('Cwd','any version') };
eval { $v .= pmver('Data::Dumper','any version') };
eval { $v .= pmver('Devel::Hide','any version') };
eval { $v .= pmver('Encode','any version') };
eval { $v .= pmver('Exporter','any version') };
eval { $v .= pmver('ExtUtils::MakeMaker','any version') };
eval { $v .= pmver('Fcntl','any version') };
eval { $v .= pmver('File::Basename','any version') };
eval { $v .= pmver('File::Copy','any version') };
eval { $v .= pmver('File::Path','any version') };
eval { $v .= pmver('File::Spec','any version') };
eval { $v .= pmver('File::Spec::Functions','any version') };
eval { $v .= pmver('File::Temp','any version') };
eval { $v .= pmver('File::stat','any version') };
eval { $v .= pmver('FindBin','any version') };
eval { $v .= pmver('Getopt::Long','any version') };
eval { $v .= pmver('HTTP::Body','any version') };
eval { $v .= pmver('HTTP::Cookies','any version') };
eval { $v .= pmver('HTTP::Date','any version') };
eval { $v .= pmver('HTTP::Headers','any version') };
eval { $v .= pmver('HTTP::Request','any version') };
eval { $v .= pmver('HTTP::Server::Simple::PSGI','any version') };
eval { $v .= pmver('Hash::Merge::Simple','any version') };
eval { $v .= pmver('IO::File','any version') };
eval { $v .= pmver('IO::Handle','any version') };
eval { $v .= pmver('IPC::Open3','any version') };
eval { $v .= pmver('LWP::UserAgent','any version') };
eval { $v .= pmver('MIME::Types','any version') };
eval { $v .= pmver('Module::Runtime','any version') };
eval { $v .= pmver('POSIX','any version') };
eval { $v .= pmver('Plack::Builder','any version') };
eval { $v .= pmver('Pod::Usage','any version') };
eval { $v .= pmver('Scalar::Util','any version') };
eval { $v .= pmver('Test::Builder','any version') };
eval { $v .= pmver('Test::More','0.88') };
eval { $v .= pmver('Time::HiRes','any version') };
eval { $v .= pmver('Try::Tiny','any version') };
eval { $v .= pmver('URI','any version') };
eval { $v .= pmver('URI::Escape','any version') };
eval { $v .= pmver('YAML','any version') };
eval { $v .= pmver('base','any version') };
eval { $v .= pmver('bytes','any version') };
eval { $v .= pmver('constant','any version') };
eval { $v .= pmver('lib','any version') };
eval { $v .= pmver('overload','any version') };
eval { $v .= pmver('parent','any version') };
eval { $v .= pmver('strict','any version') };
eval { $v .= pmver('utf8','any version') };
eval { $v .= pmver('vars','any version') };
eval { $v .= pmver('warnings','any version') };


# All done.
$v .= <<'EOT';

Thanks for using my code.  I hope it works for you.
If not, please try and include this output in the bug report.
That will help me reproduce the issue and solve your problem.

EOT

diag($v);
ok(1, "we really didn't test anything, just reporting data");
$success = 1;

# Work around another nasty module on CPAN. :/
no warnings 'once';
$Template::Test::NO_FLUSH = 1;
exit 0;
