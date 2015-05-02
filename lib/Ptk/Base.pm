# author: joe.zheng

package Ptk::Base;
use Mojo::Base -base;

use Ptk::Base::Log;
use Ptk::Base::Loader;

has log    => sub { Ptk::Base::Log->new };
has loader => sub { Ptk::Base::Loader->new };

sub tap {
  my ($self, $cb) = (shift, shift);
  $_->$cb(@_) for $self;
  return $self;
}

sub clone {
  my $self = shift;
  return $self->new($self);
}

sub init { shift->reset_stash }

sub stash { shift->_dict(stash => @_) }

sub reset_stash { shift->_reset_dict('stash') }

sub _dict {
  my ($self, $name) = (shift, shift);

  # Hash
  $self->{$name} ||= {};
  return $self->{$name} unless @_;

  # Get
  return $self->{$name}->{$_[0]} unless @_ > 1 || ref $_[0];

  # Set
  my $values = ref $_[0] ? $_[0] : {@_};
  $self->{$name} = {%{$self->{$name}}, %$values};

  return $self;
}

sub _reset_dict {
  my ($self, $name) = (shift, shift);

  $self->{$name} = {};
  return $self;
}

1;
__END__
