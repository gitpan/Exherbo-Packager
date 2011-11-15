
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'ExtUtils::MakeMaker' => '6.30',
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Generates exheres for perl modules',
  'dist_author' => [
    'William Orr <will@worrbase.com>'
  ],
  'dist_name' => 'Exherbo-Packager',
  'dist_version' => '1.113190',
  'license' => 'mit',
  'module_name' => 'Exherbo::Packager',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {},
  'script_files' => [
    'bin/ex-packer'
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
