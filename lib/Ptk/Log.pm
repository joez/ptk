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

=encoding utf8

=head1 NAME

Ptk::Log - Simple and convenient logger

=head1 SYNOPSIS

  use Ptk::Log;

  # Log to STDERR
  my $log = Ptk::Log->new;

  # Customize log file location and minimum log level
  my $log = Ptk::Log->new(path => '/var/log/ptk.log', level => 'warn');

  # Log messages
  $log->debug('Let us dig further');
  $log->info('FYI');
  $log->warn('This might be a problem');
  $log->error('I am sure it is wrong');
  $log->fatal('WTF');

=head1 DESCRIPTION

L<Ptk::Log> is based on L<Mojo::Log>, with shorter output and current PID,
and support creating parent directories for the log file and dumping
complicated data structure automatically

You can override the default log level with environment variable
PTK_LOG_LEVEL or MOJO_LOG_LEVEL

=head1 SEE ALSO

L<Ptk>, L<Mojo::Log>, L<https://github.com/joez/ptk>.

=cut
