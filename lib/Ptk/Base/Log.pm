# author: joe.zheng

package Ptk::Base::Log;
use base 'Mojo::Log';
use Ptk::Base -base;

use Carp 'croak';
use Data::Dumper;
use File::Path qw/make_path/;
use File::Basename qw/dirname/;

use Mojo::Util qw/encode/;

has level => sub { $ENV{PTK_LOG_LEVEL} // 'debug' };
has format => sub { \&_format };

my $_dumper
  = Data::Dumper->new([])->Terse(1)->Deepcopy(1)->Indent(0)->Pair(':');

has handle => sub {
  my $self = shift;

  # File
  if (my $path = $self->path) {
    my $dir = dirname($path);
    make_path($dir) unless -e $dir;

    open my $fh, '>>', $path or croak qq/Can't open log file "$path": $!/;
    return $fh;
  }

  # STDERR
  return \*STDERR;
};

sub _format {
  my ($time, $level, @msgs) = @_;

  my $msg
    = @msgs < 1 ? '' : @msgs == 1 && !ref $msgs[0] ? $msgs[0] : _dump(@msgs);

  return _timestamp($time) . " $level $$: " . $msg . "\n";
}

sub _timestamp {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime $_[0];

  return
    sprintf('%02d-%02d %02d:%02d:%02d', $mon + 1, $mday, $hour, $min, $sec);
}

sub _dump { join ', ', $_dumper->Values(\@_)->Dump }

1;
__END__
