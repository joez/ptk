# author: joe.zheng

package Ptk::Base::Chdir;
use Ptk::Base -base;

use Cwd qw/getcwd/;
use overload
  '""'     => sub { shift->to_string },
  fallback => 1;

has stack => sub { [] };

sub to_string { shift->cwd }

sub cwd {getcwd}

sub pushd {
  my $self = shift;
  my $d    = shift;

  my $o = $self->cwd;

  my $r = chdir $d;
  if ($r) {
    push @{$self->stack}, $o;
  }

  return $r;
}

sub popd {
  my $self = shift;

  my $d = pop @{$self->stack};
  my $r = 0;
  if ($d) {
    $r = chdir $d;
  }

  return $r;
}

sub DESTROY {
  my $self = shift;

  while (@{$self->stack}) {
    $self->popd;
  }
}

1;
__END__
