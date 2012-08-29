
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Generates exheres for perl modules",
  "dist_author" => [
    "William Orr <will\@worrbase.com>"
  ],
  "dist_name" => "Exherbo-Packager",
  "dist_version" => "1.122420",
  "license" => "mit",
  "module_name" => "Exherbo::Packager",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "DateTime" => 0,
    "File::Copy" => 0,
    "Getopt::Long" => 0,
    "MetaCPAN::API" => 0,
    "Ouch" => 0,
    "Pod::Usage" => 0,
    "Test::More" => 0,
    "YAML::Any" => 0
  },
  "script_files" => [
    "bin/ex-packer"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
