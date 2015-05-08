# author: joe.zheng

package Ptk::Base::Executor;
use Ptk::Base -base;

use Parallel::ForkManager;

has max_workers => 1;
has cmd         => sub {
  sub { }
};
has [qw/on_start on_finish/] => sub {
  sub { }
};

sub execute {
  my $self = shift;

  my $ttl = scalar(@_);
  return unless $ttl > 0;

  my $fm = Parallel::ForkManager->new($self->max_workers);

  # ($idx, $ttl);
  $fm->run_on_start(sub { $self->_on_start($_[1], $ttl) });

  # ($idx, $exit_code, $data);
  $fm->run_on_finish(sub { $self->_on_finish(@_[qw/2 1 5/]) });

  # ($exit_code, $data_reference)
  my $yield = sub { $fm->finish(@_) };

  for (my $idx = 0; $idx < $ttl; $idx++) {
    my $job = $_[$idx];

    $fm->start($idx) and next;

    $self->cmd->($job, $yield, $idx, $ttl);
  }

  return $fm->wait_all_children;
}

sub _on_start {
  my $self = shift;

  my ($idx, $ttl) = @_;

  return $self->on_start->($idx, $ttl);
}

sub _on_finish {
  my $self = shift;

  my ($idx, $exit_code, $data) = @_;

  return $self->on_finish->($idx, $exit_code, $data);
}
1;
__END__
