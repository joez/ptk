use Ptk::Base -strict;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Basename;
use File::Spec::Functions qw/catfile/;
use File::Temp ();
use Ptk::Manifest;

my $path = catfile(dirname($0), qw/manifest default.xml/);
my $tdir = File::Temp->newdir();
my $save = catfile($tdir, 'default.xml');

# API
my @public = qw(
  path load save add_project del_project get_project get_resolved_project get_project_name_by_path
  list_project_names list_project_paths add_remote get_remote list_remote_names
);
can_ok 'Ptk::Manifest', @public;

my $m = Ptk::Manifest->new($path);

# Normal usage
is_deeply [$m->list_project_names], [qw/copyfile linkfile project1 project2/],
  'list project names';
is_deeply [$m->list_project_paths], [qw/copyfile linkfile project1 modified/],
  'list project paths';
is_deeply [$m->list_remote_names], [qw/remote1 remote2/], 'list remote names';
ok $m->get_project('project1'), 'get project';
ok !$m->get_project('invalid-project'), 'get invalid project';
is $m->get_project('project1')->{path}, 'project1', 'get project path';
ok !$m->get_project('project1')->{remote}, 'get project remote';
ok $m->get_remote('remote1'), 'get remote';
is $m->get_remote('remote1')->{fetch}, 'https://source.remote1.org',
  'get remote fetch';
is $m->get_project_name_by_path('modified'), 'project2',
  'get project name by path';
is $m->get_project('modified'), $m->get_project('project2'),
  'get project by name or path';
is $m->get_resolved_project('modified')->{fetch},
  'https://source.remote1.org', 'get resolved project fetch';
is $m->get_resolved_project('modified')->{revision}, 'develop',
  'get resolved project revision';

# add remote will fix missing name field
$m->add_remote('remote.add', {});
is $m->get_remote('remote.add')->{name}, 'remote.add', 'add remote';

# delete project
$m->del_project('project1');
ok !$m->get_project('project1'), 'del project';
ok $m->get_project('project2'), 'get project';

# add project
$m->add_project('project.add', {remote => 'remote2'});
is $m->get_resolved_project('project.add')->{fetch},
  'https://source.remote2.org/', 'add project';

# save and load
$m->save($save);
my $new = Ptk::Manifest->new($save);
is_deeply $new->get_resolved_project('project.add'),
  $m->get_resolved_project('project.add'), 'save and load resolved project';

done_testing();
