# author: joe.zheng

package Ptk::Chdir;
use Ptk::Base -base;

use Cwd qw/getcwd/;
use overload
  '""'     => sub { shift->to_string },
  fallback => 1;

sub new {
  shift->SUPER::new(@_)->tap(sub { $_->{stack} = [] });
}

sub to_string { shift->cwd }

sub cwd {getcwd}

sub pushd {
  my $self = shift;
  my $d    = shift;

  my $o = $self->cwd;

  my $r = chdir $d;
  if ($r) {
    push @{$self->{stack}}, $o;
  }

  return $r;
}

sub popd {
  my $self = shift;

  my $d = pop @{$self->{stack}};
  my $r = 0;
  if ($d) {
    $r = chdir $d;
  }

  return $r;
}

sub DESTROY {
  my $self = shift;

  while (@{$self->{stack}}) {
    $self->popd;
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Chdir - a safer way to change directories

=head1 SYNOPSIS

  {
    my $cd = Ptk::Chdir->new;
    if ($cd->pushd('/var/log')) {
      say 'current directory is ' . $cd->cwd;
    }
  }
  # back to the old directory automatically

=head1 DESCRIPTION

L<Ptk::Chdir> change directory temporarily for a limited scope that can be
automatically reverted

=head1 METHODS

L<Ptk::Chdir> inherits all methods from L<Ptk::Base> and implements the
following new ones.

=head2 cwd

  $cd->cwd;

Get the current working directory

=head2 pushd

  $cd->pushd('/var/log');

Change to the target directory and save the old directory into the stash.
It returns true on success, false otherwise.

=head2 popd

  $cd->popd;

Pop the saved directory from the stash, then change the directory to it.
It returns true on success, false otherwise.

=head1 SEE ALSO

L<Ptk>, L<Ptk::Chdir>, L<https://github.com/joez/ptk>.

=cut
