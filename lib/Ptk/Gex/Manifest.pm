# author: joe.zheng

package Ptk::Gex::Manifest;
use Ptk::Base -base;
use Ptk::Gex::Matcher;

use Carp 'croak';

use XML::Reader qw/XML::Parsepp/;
use XML::Writer;

has files        => sub { ['.repo/manifests/default.xml'] };
has includes     => sub { [] };
has projects     => sub { [] };
has project_data => sub { {} };
has path_to_name => sub { {} };
has remotes      => sub { [] };
has remote_data  => sub { {} };
has default      => sub { {} };

sub init {
  my $self = shift->SUPER::init;

  for my $file (@{$self->files}) {
    $self->_parse($file);
  }

  return $self;
}

sub add_project {
  my $self = shift;
  my $name = shift or die;
  my $attr = shift or die;

  # there is no "path" defined for mirror project
  my $path = $attr->{path} || $name;
  my $data = $self->project_data;

  push @{$self->projects}, $name unless $data->{$name};
  $data->{$name} = $attr;

  $self->path_to_name->{$path} = $name;

  return $self;
}

sub del_project {
  my $self = shift;
  my $name = shift or die;

  my $data     = $self->project_data;
  my $projects = $self->projects;

  if (my $p = delete $data->{$name}) {
    my $path = $p->{path};
    $self->projects([grep { $_ ne $name } @$projects]);
    delete $self->path_to_name->{$path};
  }

  return $self;
}

sub get_project_name_by_path { $_[0]->path_to_name->{$_[1]} }

sub get_project {
  my $self = shift;
  my $name = shift or die;

  my $data = $self->project_data;

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

  return @{$self->projects} unless $query;

  my $matcher = Ptk::Gex::Matcher->new->pattern($query)->init;
  my @result  = ();
  for (@{$self->projects}) {
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

  my $data = $self->remote_data;

  push @{$self->remotes}, $name unless $data->{$name};
  $data->{$name} = $attr;

  return $self;
}

sub get_remote { $_[0]->remote_data->{$_[1]} }

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
          my $m = catfile(dirname($file), $attr->{name});
          push @{$self->includes}, $m;

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
