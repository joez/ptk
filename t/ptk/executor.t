use Ptk::Base -strict;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Ptk::Executor;
use Storable qw/dclone/;

my $workers  = 3;
my @tasks    = (1 .. 4);
my $context  = {start => [], done => [], ok => []};
my $command  = sub { my ($idx, $ctx, $task, $exit) = @_; $exit->(0, \$idx) };
my $on_start = sub {
  my ($idx, $ctx) = @_;
  push @{$ctx->{start}}, $idx;
};
my $on_finish = sub {
  my ($idx, $ctx, $code, $data) = @_;
  if (!$code) {
    push @{$ctx->{ok}}, $idx;
    push @{$ctx->{done}}, $$data if defined $data;
  }
};

my $executor = Ptk::Executor->new(
  workers   => $workers,
  command   => $command,
  context   => dclone($context),
  on_start  => $on_start,
  on_finish => $on_finish,
);

# Public API
can_ok $executor, qw/workers context command on_start on_finish execute/;

# Normal usage
is $executor->workers,        $workers,   'get workers';
is_deeply $executor->context, $context,   'get context';
is $executor->command,        $command,   'get command';
is $executor->on_start,       $on_start,  'get on_start';
is $executor->on_finish,      $on_finish, 'get on_finish';

$executor->execute(@tasks);
is scalar @{$executor->context->{start}}, scalar @tasks, 'tasks started';
is scalar @{$executor->context->{done}},  scalar @tasks, 'tasks done';
is_deeply $executor->context->{ok}, $executor->context->{done}, 'ok and done';

# Do nothing in the command
$executor->context(dclone($context))->command(sub { })->execute(@tasks);
is scalar @{$executor->context->{start}}, scalar @tasks,
  'tasks started with nop';
is scalar @{$executor->context->{ok}}, scalar @tasks, 'tasks ok with nop';
is scalar @{$executor->context->{done}}, 0, 'tasks done with nop';

# Exit 0 in the command
$executor->context(dclone($context))->command(sub {exit})->execute(@tasks);
is scalar @{$executor->context->{start}}, scalar @tasks,
  'tasks started with exit';
is scalar @{$executor->context->{ok}}, scalar @tasks, 'tasks ok with exit';
is scalar @{$executor->context->{done}}, 0, 'tasks done with exit';

# Exit -1 in the command
$executor->context(dclone($context))->command(sub { exit(-1) })
  ->execute(@tasks);
is scalar @{$executor->context->{start}}, scalar @tasks,
  'tasks started with exit -1';
is scalar @{$executor->context->{ok}},   0, 'tasks ok with exit -1';
is scalar @{$executor->context->{done}}, 0, 'tasks done with exit -1';

done_testing();
