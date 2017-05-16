# author: joe.zheng

package Ptk::Gex::Pattern;
use Ptk::Base 'Ptk::Pattern';

sub match {
  my $self = shift;
  my $info = shift;

  return 0 unless $info;

  my $query = $self->query;
  return 1 unless $query;

  my $p = $self->stash('query');
  unless ($p) {
    $p = [];

    for my $item (split /\s+/, $query) {
      my $i = [];
      for (split ',', $item) {
        my ($k, $v) = split ':';
        my $reverse = ($k =~ s/^!\s*//);

        push @$i, {k => $k, q => qr/$v/i, r => $reverse,};
      }
      push @$p, $i;
    }

    $self->stash('query', $p);
  }

  return 1 unless @$p;

ITEM: for my $item (@$p) {
    for my $i (@$item) {
      my ($k, $q, $r) = @{$i}{qw/k q r/};
      my $v = $info->{$k} || '';

      next ITEM unless ($r ? $v !~ $q : $v =~ $q);
    }
    return 1;
  }

  return 0;
}

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Gex::Pattern - Pattern to match

=head1 SYNOPSIS

  use Ptk::Pattern;

  my $obj = Ptk::Pattern->new('remote:aosp name:platform,!path:vendor');
  say 'matched' if $obj->match($object);

=head1 DESCRIPTION

L<Ptk::Gex::Pattern> is a pattern can be used to match a object, with a query
specifying which fields must match what patterns

There will be multiple query items in the query, separated with B<SPACE>, if
one of them match, the result is true, if B<all> of them fail to match, the
result is false

For each item, there will be multiple fields to match, separated with "B<,>",
the field name and pattern are separated with "B<:>", if one of the field does
not match, the whole item fails

Here is an example: C<remote:aosp name:platform,!path:vendor>

Which means:

=over 4

=item *

If the object's field C<remote> matches "aosp", the object matches

=item *

B<OR> if the object's field C<name> matches "platform" B<AND> field C<path>
does not match "vendor", then the object matches

=item *

Otherwise the object is failed to match

=back

=head1 ATTRIBUTES

L<Ptk::Gex::Pattern> inherits all attributes from L<Ptk::Pattern>.

=head1 METHODS

L<Ptk::Gex::Pattern> inherits all methods from L<Ptk::Pattern> and overrides
the following ones.

=head2 match

  my $matched = $obj->match({name => 'platform/build', path => 'build'});

Check whether the object is matched by the pattern.

=head1 SEE ALSO

L<Ptk>, L<Ptk::Pattern>, L<https://github.com/joez/ptk>.

=cut
