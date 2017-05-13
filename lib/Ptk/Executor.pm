# author: joe.zheng

package Ptk::Executor;
use Ptk::Base -base;

use Parallel::ForkManager;

has workers => 1;
has context => sub { {} };
has command => sub {
  sub { }
};
has [qw/on_start on_finish/] => sub {
  sub { }
};

sub execute {
  my $self = shift;

  my $ttl = scalar(@_);
  return unless $ttl > 0;

  my $fm = Parallel::ForkManager->new($self->workers);

  # ($idx);
  $fm->run_on_start(sub { $self->_on_start($_[1]) });

  # ($idx, $exit_code, $data);
  $fm->run_on_finish(sub { $self->_on_finish(@_[qw/2 1 5/]) });

  # ($exit_code, $data_reference)
  my $exit = sub { $fm->finish(@_) };

  for (my $idx = 0; $idx < $ttl; $idx++) {
    my $job = $_[$idx];

    $fm->start($idx) and next;

    # child process here
    # your change in $context will not reflect in parent
    $self->command->($idx, $self->context, $job, $exit);

    # child exit if not yet
    $exit->(0);
  }

  return $fm->wait_all_children;
}

sub _on_start {
  my $self = shift;

  my ($idx) = @_;

  return $self->on_start->($idx, $self->context);
}

sub _on_finish {
  my $self = shift;

  my ($idx, $exit_code, $data) = @_;

  return $self->on_finish->($idx, $self->context, $exit_code, $data);
}

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Executor - execute tasks in the workers

=head1 SYNOPSIS

  use Ptk::Executor;

  my @tasks     = (1 .. 10);
  my $context   = { ok => [], done => [] };
  my $command   = sub {
    my ($idx, $ctx, $task, $exit) = @_;
    $exit->(0, [$idx]);
  };
  my $on_finish = sub {
    my ($idx, $ctx, $code, $data) = @_;
    if (!$code) {
      push @{$ctx->{ok}}, $idx;
      push @{$ctx->{done}}, $data->[0] if defined $data;
    }
  };

  my $executor = Ptk::Executor->new(
    workers   => 5,
    context   => $context,
    command   => $command,
    on_finish => $on_finish,
  )->execute(@tasks);

  say 'ok: '   . join(', ', @{$context->{ok}});
  say 'done: ' . join(', ', @{$context->{done}});

=head1 DESCRIPTION

L<Ptk::Executor> execute tasks in a limited number of workers and get the
results

=head1 ATTRIBUTES

L<Ptk::Executor> inherits all attributes from L<Ptk::Base> and implements the
following new ones.

=head2 command

  my $cmd = sub {
    my ($idx, $ctx, $task, $exit) = @_;

    say "worker ($idx) is doing $task ...";

    # finish the task, return the exit code and data
    $exit->(0, \$idx);
  };

  $executor->command($cmd);
  $executor->command;

The callback to run for the tasks, it will be executed in the workers
(B<child processes>), with for following parameters:

=over 2

=item *

C<$idx> - the index of the tasks

=item *

C<$ctx> - the L<context>

=item *

C<$task> - the given task

=item *

C<$exit> - a callback to finish the worker, with optional parameters
B<exit code> and B<data reference> (any valid reference should be OK)

=back

=head2 context

  $executor->context({ ttl => 10 });
  $executor->context;

The context which can be accessed when execute the C<command>

Because the workers are running in the child processes, changes made on
context when execute the C<command>, can't be accessed by parent process

=head2 on_start

  my $on_start = sub {
    my ($idx, $ctx) = @_;

    say "worker ($idx) is started ...";
  };

  $executor->on_start($on_start);
  $executor->on_start;

The callback called when a task is started

=head2 on_finish

  my $on_finish = sub {
    my ($idx, $ctx, $code, $data) = @_;

    say "worker ($idx) is finished with exit code $code";
  };

  $executor->on_finish($on_finish);
  $executor->on_finish;

The callback called when a task is finished, providing the B<exit code> and
B<data> (a reference) return from the worker

=head2 workers

  $executor->workers(5);
  $executor->workers;

The maximum number of workers, the default is 1.

=head1 METHODS

L<Ptk::Executor> inherits all methods from L<Ptk::Base> and implements the
following new ones.

=head2 execute

  $executor->execute(1 .. 10);

Execute the given tasks

=head1 SEE ALSO

L<Ptk>, L<Ptk::Base>, L<https://github.com/joez/ptk>.

=cut
