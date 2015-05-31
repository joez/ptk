# author: joe.zheng

package Ptk::Gex::Manifest;
use Ptk::Base -base;
use Ptk::Gex::Matcher;

use Carp 'croak';

use File::Basename;
use File::Spec::Functions qw/catfile/;

use XML::Reader qw/XML::Parsepp/;
use XML::Writer;
use IO::File;

has path          => '.repo/manifests/default.xml';
has include       => sub { [] };
has default       => sub { {} };
has _projects     => sub { [] };
has _project_data => sub { {} };
has _path_to_name => sub { {} };
has _remotes      => sub { [] };
has _remote_data  => sub { {} };

sub new {
  my $class = shift;
  my $path  = shift;

  my $self = $class->SUPER::new(@_);
  $self->path($path) if defined $path;

  return $self->load;
}

sub load {
  my $self = shift;
  my $path = shift // $self->path;

  $self->path($path)->include([]);

  $self->_parse($self->path);

  return $self;
}

sub save {
  my $self = shift;
  my $path = shift // $self->path;

  # TODO
  my $out = IO::File->new($path, 'w');
  my $wtr = XML::Writer->new(
    OUTPUT      => $out,
    ENCODING    => 'UTF-8',
    UNSAFE      => 1,
    DATA_MODE   => 1,
    DATA_INDENT => 4,
  );
  $wtr->xmlDecl();
  $wtr->startTag('manifest');

  for my $n (sort +$self->list_remote_names) {
    my $item = $self->get_remote($n);
    my @attr = map { ($_, $item->{$_}) } sort keys %$item;
    $wtr->emptyTag('remote', @attr);
  }
  $wtr->characters("\n");

  my $default = $self->default;
  $wtr->emptyTag('default', map { ($_, $default->{$_}) } sort keys %$default);
  $wtr->characters("\n");

  for my $n (sort +$self->list_project_names) {
    my $item = $self->get_project($n);
    my @attr = map { ($_, $item->{$_}) } sort keys %$item;
    $wtr->emptyTag('project', @attr);
  }

  $wtr->endTag('manifest');
  $wtr->end();

  $out->close();

  return $self;
}

sub add_project {
  my $self = shift;
  my $name = shift or die;
  my $attr = shift or die;

  # there is no "path" defined for mirror project
  my $path = $attr->{path} || $name;
  my $data = $self->_project_data;

  push @{$self->_projects}, $name unless $data->{$name};
  $data->{$name} = $attr;

  $self->_path_to_name->{$path} = $name;

  return $self;
}

sub del_project {
  my $self = shift;
  my $name = shift or die;

  my $data     = $self->_project_data;
  my $projects = $self->_projects;

  if (my $p = delete $data->{$name}) {
    my $path = $p->{path};
    $self->_projects([grep { $_ ne $name } @$projects]);
    delete $self->_path_to_name->{$path};
  }

  return $self;
}

sub get_project_name_by_path { $_[0]->_path_to_name->{$_[1]} }

sub get_project {
  my $self = shift;
  my $name = shift or die;

  my $data = $self->_project_data;

  # first by name, then by path
  my $r = $data->{$name};
  unless ($r) {
    $name = $self->get_project_name_by_path($name);
    $r = $data->{$name} if $name;
  }

  return $r;
}

sub get_resolved_project {
  my $self = shift;
  my $name = shift or die;

  my $p = $self->get_project($name);
  return $p unless $p;

  # real name
  $name = $p->{name};

  my $resolved = $self->stash('resolved_projects') || {};
  unless ($resolved->{$name}) {
    my $d = $self->default;
    my $n = $p->{remote} || $d->{remote};
    my $r = $self->get_remote($n);
    my $t = {%$d, %$r, %$p};

    # there is no "path" defined for mirror project
    $t->{path} = $t->{name} unless $t->{path};

    $resolved->{$name} = $t;
    $self->stash('resolved_projects', $resolved);
  }

  return $resolved->{$name};
}

sub list_project_names {
  my $self  = shift;
  my $query = shift;

  return @{$self->_projects} unless $query;

  my $matcher = Ptk::Gex::Matcher->new($query);
  my @result  = ();
  for (@{$self->_projects}) {
    push @result, $_ if $matcher->match($self->get_resolved_project($_));
  }

  return @result;
}

sub list_project_paths {
  my $self    = shift;
  my $matcher = shift;

  return
    map { $self->get_resolved_project($_)->{path} }
    $self->list_project_names($matcher);
}

sub add_remote {
  my $self = shift;
  my $name = shift or die;
  my $attr = shift or die;

  my $data = $self->_remote_data;

  push @{$self->_remotes}, $name unless $data->{$name};
  $data->{$name} = $attr;

  return $self;
}

sub get_remote { $_[0]->_remote_data->{$_[1]} }

sub list_remote_names { @{shift->_remotes} }

sub _parse {
  my $self = shift;
  my $file = shift or die;

  my $log = $self->log;

  $log->debug("parse manifest: $file");
  unless (-e $file) {
    $log->warn("can't access manifest: $file");
    return $self;
  }

  my %xpath = (
    manifest         => '/manifest',
    remote           => '/manifest/remote',
    include          => '/manifest/include',
    default          => '/manifest/default',
    project          => '/manifest/project',
    'remove-project' => '/manifest/remove-project',
  );
  my $rdr = XML::Reader->new($file, {mode => 'attr-in-hash'});

  while ($rdr->iterate) {
    if ($rdr->is_start) {
      my $path = $rdr->path;
      my $attr = $rdr->att_hash;

      if ($path eq $xpath{include}) {
        if ($attr->{name}) {

          # relative to the main manifest file
          my $m = catfile(dirname($self->path), $attr->{name});
          push @{$self->include}, $m;

          # parse included manifest
          $self->_parse($m);
        }
      }
      elsif ($path eq $xpath{remote}) {
        $self->add_remote($attr->{name}, $attr);
      }
      elsif ($path eq $xpath{default}) {
        $self->default($attr);
      }
      elsif ($path eq $xpath{project}) {
        $self->add_project($attr->{name}, $attr);
      }
      elsif ($path eq $xpath{'remove-project'}) {
        $self->del_project($attr->{name});
      }
      else {
        $log->debug('skip node: ' . $rdr->path);
      }
    }
    if ($rdr->is_text) {
    }

    if ($rdr->is_end) {
    }
  }

  return $self;
}

1;
__END__
