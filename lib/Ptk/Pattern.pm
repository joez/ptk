# author: joe.zheng

package Ptk::Pattern;
use Ptk::Base -base;

has 'query';

sub new {
  my $class = shift;
  my $query = shift;

  my $self = $class->SUPER::new(@_);
  $self->query($query) if defined $query;

  return $self;
}

sub match {
  my $self = shift;
  my $info = shift;

  return 0 unless $info;

  my $query = $self->query;
  return 1 unless $query;

  my $re = $self->stash('query');
  unless ($re) {
    $re = qr/$query/;
    $self->stash('query', $re);
  }

  return $info =~ $re;
}

1;
__END__
