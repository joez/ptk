# author: joe.zheng

package Ptk::Log;
use base 'Mojo::Log';
use Ptk::Base -base;

use Data::Dumper;
use Mojo::File;
use Mojo::Util qw/encode/;


my $_dumper
  = Data::Dumper->new([])->Terse(1)->Deepcopy(1)->Indent(0)->Pair(':');

has level => sub { $ENV{PTK_LOG_LEVEL} // $ENV{MOJO_LOG_LEVEL} // 'debug' };
has format => sub { \&_format };
has handle => sub {

  # STDERR
  return \*STDERR unless my $path = shift->path;

  # File
  my $file = Mojo::File->new($path);
  $file->dirname->make_path;
  return $file->open('>>');
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
