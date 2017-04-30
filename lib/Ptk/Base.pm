# author: joe.zheng

package Ptk::Base;
use Mojo::Base -base;

use Mojo::Util;

has log => sub { require Ptk::Log;    Ptk::Log->new };
has ldr => sub { require Ptk::Loader; Ptk::Loader->new };

sub clone { $_[0]->new($_[0]) }

sub stash { Mojo::Util::_stash(stash => @_) }

sub reset_stash { $_[0]->{stash} = {} and $_[0] }

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Base - Base class for Ptk projects

=head1 SYNOPSIS

  package Cat;
  use Ptk::Base -base;

  has name => 'Nyan';
  has ['age', 'weight'] => 4;

  package Tiger;
  use Ptk::Base 'Cat';

  has friend  => sub { Cat->new };
  has stripes => 42;

  package main;
  use Ptk::Base -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

  my $rawr = Tiger->new(stripes => 38, weight => 250);
  say $rawr->tap(sub { $_->friend->name('Tacgnol') })->weight;

=head1 DESCRIPTION

L<Ptk::Base> is based on L<Mojo::Base>, see L<Mojo::Base> for details

=head1 ATTRIBUTES

L<Ptk::Base> inherits all attributes from L<Mojo::Base> and implements the
following new ones.

=head2 log

  my $log = $obj->log;
  $obj    = $obj->log(Ptk::Log->new);

The logging layer of the object, defaults to a L<Ptk::Log> object.

=head2 ldr

  my $ldr = $obj->ldr;
  $obj    = $obj->ldr(Ptk::Loader->new);

The loader of the object, defaults to a L<Ptk::Loader> object.

=head1 METHODS

L<Ptk::Base> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 clone

  my $new = $obj->clone;

Clone a new object.

=head2 stash

  my $hash = $obj->stash;
  my $foo  = $obj->stash('foo');
  $obj     = $obj->stash({foo => 'bar', baz => 23});
  $obj     = $obj->stash(foo => 'bar', baz => 23);

Object's private storage

  # Remove value
  my $foo = delete $obj->stash->{foo};

  # Assign multiple values at once
  $obj->stash(foo => 'test', bar => 23);

=head2 reset_stash

  $obj = $obj->reset_stash;

Clear the object's private storage

=head1 SEE ALSO

L<Ptk>, L<Mojo::Base>, L<https://github.com/joez/ptk>.

=cut
