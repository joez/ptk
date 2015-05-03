# author: joe.zheng

package Ptk::Gex::Matcher;
use Ptk::Base 'Ptk::Base::Matcher';

# there are multiple query items in the pattern
# if one of the items match, the result is true
# if all the items fail to match, the result is false
#
# for each item, there are multiple keys to match
# if one of the key is not match, the whole item fails
sub match {
  my $self = shift;
  my $info = shift;

  return 0 unless $info;

  my $pattern = $self->pattern;
  return 1 unless $pattern;

  my $p = $self->stash('pattern');
  unless ($p) {
    $p = [];

    for my $item (split /\s+/, $pattern) {
      my $i = [];
      for (split ',', $item) {
        my ($k, $v) = split ':';
        my $reverse = ($k =~ s/^!\s*//);

        push @$i, {k => $k, q => qr/$v/i, r => $reverse,};
      }
      push @$p, $i;
    }

    $self->stash('pattern', $p);
  }

  return 1 unless @$p;

ITEM: for my $query (@$p) {
    for my $item (@$query) {
      my ($k, $q, $r) = @{$item}{qw/k q r/};
      my $v = $info->{$k} || '';

      next ITEM unless ($r ? $v !~ $q : $v =~ $q);
    }
    return 1;
  }

  return 0;
}

1;
__END__
