# author: joe.zheng

package Ptk::Base::Matcher;
use Ptk::Base -base;

has 'pattern';

sub match {
  my $self = shift;
  my $info = shift;

  return 0 unless $info;

  my $pattern = $self->pattern;
  return 1 unless $pattern;

  my $re = $self->stash('pattern');
  unless ($re) {
    $re = qr/$pattern/;
    $self->stash('pattern', $re);
  }

  return $info =~ $re;
}

1;
__END__
