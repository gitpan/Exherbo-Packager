#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use File::Copy qw/cp mv/;
use Test::More;
use YAML::Any qw/LoadFile/;

use constant TESTFILE => 'Mouse-0.97.exheres-0';

BEGIN { use_ok('Exherbo::Packager') }
use Exherbo::Packager;

my $test_pkg = "Test::More";

ok(Exherbo::Packager::_get_module_info($test_pkg));
my $mod = Exherbo::Packager::_get_module_info($test_pkg);

is($mod->{distribution}, 'Test-Simple');
like($mod->{version}, qr/\d+\.\d+/);
is($mod->{author}, 'MSCHWERN');

my $rel = Exherbo::Packager::_get_release_info($mod);
is($rel->{author}, 'MSCHWERN');
is($rel->{maturity}, 'released');

like(Exherbo::Packager::_get_outfile_name($mod), qr/dev\-perl\/Test\-Simple\-\d+\.\d+\.exheres\-0/, "Test outfile name");
my $outfile = Exherbo::Packager::_get_outfile_name($mod);

ok(Exherbo::Packager::_get_config('t/config.yml'), 'test config loading');

chdir('t');
ok(Exherbo::Packager::_prep_env($outfile));
ok( -d 'dev-perl/');
chdir('..');
rmdir('t/dev-perl');

{
    open(FH, 't/input.1') or die $!;
    local *STDIN;
    *STDIN = *FH;
    Exherbo::Packager::init_config('t/config.yml');
    close(FH);
}

cp('config.yml', 'config.yml.old');

my $config = LoadFile('t/config.yml');
is($config->{name}, 'Will Orr', 'testing config');
is($config->{platforms}, '~amd64', 'testing config');
is($config->{email}, 'will@worrbase.com', 'testing config');

my ($deps, @deps);
ok($deps = Exherbo::Packager::_gen_deps($rel->{dependency}));
@deps = keys %$deps;
is_deeply(\@deps, ['ExtUtils-MakeMaker', 'Test-Harness']);

chdir('t');
ok(Exherbo::Packager::gen_template('Mouse'));
open(my $fh, '<', 'dev-perl/'.TESTFILE);
my @gen_text = <$fh>;
close($fh);

open($fh, '<', TESTFILE);
my @orig_text = <$fh>;
close($fh);

is_deeply(\@gen_text, \@orig_text);

chdir('..');

unlink('t/dev-perl/'.TESTFILE);
rmdir('t/dev-perl');
mv('t/config.yml.old', 't/config.yml');

done_testing;
