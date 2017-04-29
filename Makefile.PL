use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Ptk',
  VERSION_FROM => 'lib/Ptk.pm',
  ABSTRACT     => 'My private toolkit',
  AUTHOR       => 'Joe Zheng',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime => {requires => {perl => '5.010001'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/joez/ptk/issues'},
      homepage => 'http://joez.github.com/ptk',
      license  => ['http://www.opensource.org/licenses/artistic-license-2.0'],
      repository => {
        type => 'git',
        url  => 'https://github.com/joez/ptk.git',
        web  => 'https://github.com/joez/ptk',
      },
    },
  },
  PREREQ_PM => {
    'local::lib'            => '2.0',
    'Perl::Tidy'            => '2016',
    'Mojolicious'           => '7.0',
    'Parallel::ForkManager' => '1.12',
    'XML::Reader'           => '0.49',
    'XML::Writer'           => '0.61',
    'XML::Parsepp'          => '0.08',

    # for gex
    'Git::Repository::Log' => '1.31',
    'Archive::Zip'         => '1.46',
    'System::Command'      => '1.111',
    'Excel::Writer::XLSX'  => '0.67',
  },
  BUILD_REQUIRES => {'Test::More' => '1.30',},
  EXE_FILES      => ['bin/gex'],
  test           => {TESTS        => 't/*.t t/*/*.t'}
);
