package Exherbo::Packager;

# ABSTRACT: Generates exheres for perl modules

=pod

=head1 NAME

Exherbo::Packager

=head1 SYNOPSIS

 use Exherbo::Packager qw/init_config gen_template/;
 my $config_loc = "/etc/exherbo-packager.yml"
 init_config($config_loc);
 gen_template("Exherbo::Packager");

=head1 DESCRIPTION

This module exports two functions, one to initialize the configuration of the
packager, and the other to generate the exheres. Currently, this package only
generates Exheres for Perl modules, but support for other languages is coming
soon.

An OO version of this module is also planned, since exporting things into the
global namespace is icky.

=head2 gen_template($modname)

gen_template takes one argument, and that is the name of the perl module you
wish to generate. It will output the exheres in your current directory, in a
subdirectory named by the category it chooses.

This will B<die> with an error if the exheres already exists.

=head2 init_config

=head2 init_config($config_loc)

init_config can optionally take one argument, that being the location of the
config file you wish to use for this run of the packager. Once run, it will get
all of the configuration information for calls to C<gen_template()>.

=head1 BUGS

=over 1
=item No OO interface
=item Not very generic or extendable
=item Little error checking
=back

=head1 AUTHOR

William Orr <will@worrbase.com>

=cut


use strict;
use warnings;
use 5.010;

use DateTime;
use Exporter;
use MetaCPAN::API;
use Ouch;
use YAML::Any qw/LoadFile DumpFile/;

our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/init_config gen_template/;

use constant CONFIG_LOC => $ENV{HOME}."/.exherbo-packager.yml";

my $mcpan;
my $config;


sub gen_template {
    my ($name) = @_;

    my $mod = _get_module_info($name);
    my $release = _get_release_info($mod);
    my $outfile = _get_outfile_name($mod);
    my $dt = DateTime->now();

    _prep_env($outfile);
    ouch(400, "Exheres already exists at $outfile!") if ( -f $outfile);

    open(my $fh, '>', $outfile) or ouch(400, "Could not open $outfile for
        write");
    
    if (not $config) { $config = _get_config(); }
    my $year = $dt->year;

    unless ($mod->{description}) {
        bleep("No description available");
        $mod->{description} = "Describe me!"
    }

    print $fh <<EOF
# Copyright $year $config->{name} <$config->{email}>
# Distributed under the terms of the GNU General Public License v2

require perl-module [ module_author=$mod->{author} ]

SUMMARY="$mod->{abstract}"
DESCRIPTION="
$mod->{description}
"

SLOT="0"
PLATFORMS="$config->{platforms}"
MYOPTIONS=""

DEPENDENCIES="
    build+run:
EOF
;
    my $deps = _gen_deps($release->{dependency});
    foreach my $k (sort { uc $a cmp uc $b } keys %$deps) {
        say $fh "        dev-perl/$deps->{$k}"
    }
    print $fh <<EOF
"

BUGS_TO="$config->{email}"

EOF
;

    close($fh);
}

sub _get_module_info {
    my ($name) = @_;

    $mcpan //= MetaCPAN::API->new();
    my $mod = $mcpan->module($name);

    ouch(404, "Module $name not found") if (not $mod);
    return $mod;
}

sub _get_release_info {
    my ($mod) = @_;

    my $rel = $mcpan->release(distribution => $mod->{distribution}, release => $mod->{release});
    ouch(404, "Release $mod->{distribution} not found") if (not $rel);
    return $rel;
}

sub _get_config {
    my $lconfig = CONFIG_LOC;
    $lconfig = shift if (@_);
    eval {
        return $config //= LoadFile($lconfig);
    } or ouch(400, "Could not read config");
}

sub _get_outfile_name {
    my $mod = shift;
    return "dev-perl/$mod->{release}.exheres-0";
}

sub _prep_env {
    my ($outfile) = @_;

    my $dir = $outfile;
    $dir =~ s/\/.+//;
    if (not -d $dir) {
        mkdir($dir) or ouch(403, 'Cannot create directory');
    }
}

sub _gen_deps {
    my ($deps) = @_;
    my $rel_deps = {};

    foreach my $dep (@{$deps}) {
        if ($dep->{relationship} eq 'requires' and $dep->{module} ne 'perl') {
            my $rel = _get_release_info(_get_module_info($dep->{module}));
            next if ($rel->{distribution} eq 'perl');
            $rel_deps->{$rel->{distribution}} = $rel->{name};
        }
    }

    return $rel_deps;
}

sub init_config {
    my $lconfig = CONFIG_LOC;
    $lconfig = shift if (@_);

    if ( -f $lconfig ) {
        print "Are you sure you want to overwrite your config? ";
        return if (*STDIN->getline !~ /^y$/i);
    }

    my $conf_info = { };
    print "What's your name? ";
    $conf_info->{name} = _sane_chomp(*STDIN->getline);

    print "What's your email address? ";
    $conf_info->{email} = _sane_chomp(*STDIN->getline);

    print "Give me a valid arch string to use by default for new packages: ";
    $conf_info->{platforms} = _sane_chomp(*STDIN->getline);
    print "\n";

    eval {
        if ( not -f $lconfig ) {
            open(my $fh, '>', $lconfig) or die;
            close($fh);
        }
        DumpFile($lconfig, $conf_info) 
    } or ouch 400, "Could not open config file for writing";
}

sub _sane_chomp {
    my $str = shift;
    chomp $str;
    return $str;
}

1;
