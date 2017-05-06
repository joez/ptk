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

=encoding utf8

=head1 NAME

Ptk::Pattern - Pattern to match

=head1 SYNOPSIS

  use Ptk::Pattern;

  my $obj = Ptk::Pattern->new($query);
  say 'matched' if $obj->match($data);

=head1 DESCRIPTION

L<Ptk::Pattern> is a pattern can be used to match some data

=head1 ATTRIBUTES

L<Ptk::Pattern> inherits all attributes from L<Ptk::Base> and implements the
following new ones.

=head2 query

  my $q = $obj->query;
  $obj  = $obj->query('regex');

The query string to be used, it will be built into regex internally

=head1 METHODS

L<Ptk::Pattern> inherits all methods from L<Ptk::Base> and implements the
following new ones.

=head2 match

  my $matched = $obj->match('data to be check');

Check whether the string is matched by the pattern.

=head1 SEE ALSO

L<Ptk>, L<Ptk::Base>, L<https://github.com/joez/ptk>.

=cut
