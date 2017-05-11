use Ptk::Base -strict;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Cwd qw/getcwd/;
use File::Temp ();
use Ptk::Chdir;

my $cd  = Ptk::Chdir->new;
my $td1 = File::Temp->newdir();
my $td2 = File::Temp->newdir();
my $old = getcwd;

# API
can_ok $cd, qw/cwd pushd popd/;

# Normal usage
is $cd->cwd, $old, 'get cwd';
ok $cd->pushd($td1), 'pushd';
ok !$cd->pushd('no_such_folder'), 'pushd to non-exist dir';
is $cd->cwd, getcwd, 'get new cwd';
ok $cd->popd, 'popd';
ok !$cd->popd, 'no dir to pop';
is $cd->cwd, $old, 'revert to old cwd';

# Automatic revert
{
  my $c = Ptk::Chdir->new;

  ok $c->pushd($td1), 'auto pushd';
  ok $c->pushd($td2), 'auto pushd again';
}
is $cd->cwd, $old, 'auto revert to old cwd';

done_testing();
