# author: joe.zheng

package Ptk::Base::Log;
use base 'Mojo::Log';
use Ptk::Base -base;

use Carp 'croak';
use Data::Dumper;
use File::Path qw/make_path/;
use File::Basename qw/dirname/;

use Mojo::Util qw/encode/;

has dumper => sub { Data::Dumper->new([])->Terse(1)->Deepcopy(1)->Indent(0)->Pair(':') };
has append => 1;

my $LEVEL = {debug => 1, info => 2, warn => 3, error => 4, fatal => 5};

sub is_level {
  my ($self, $level) = @_;
  return $LEVEL->{lc $level} >= $LEVEL->{$ENV{PTK_LOG_LEVEL} || $self->level};
}

has handle => sub {
  my $self = shift;

  # File
  if (my $path = $self->path) {
    my $dir = dirname($path);
    make_path($dir) unless -e $dir;

    open my $fh, $self->append ? '>>' : '>', $path
      or croak qq/Can't open log file "$path": $!/;
    return $fh;
  }

  # STDERR
  return \*STDERR;
};

sub format {
  my ($self, $level, @msgs) = @_;

  my $msg = @msgs < 1 ? '' : @msgs == 1
    && !ref $msgs[0] ? $msgs[0] : $self->_dump(@msgs);

  return encode 'UTF-8', '[' . _timestamp() . "] [$level] " . $msg . "\n";
}

sub _timestamp {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;

  return
    sprintf('%02d-%02d %02d:%02d:%02d', $mon + 1, $mday, $hour, $min, $sec);
}

sub _dump { join ', ', shift->dumper->Values(\@_)->Dump }

1;
__END__
