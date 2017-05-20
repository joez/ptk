# author: joe.zheng

package Ptk::Gex::Manifest;
use Ptk::Base -base;
use Ptk::Gex::Pattern;

use Carp 'croak';

use File::Basename;
use File::Spec::Functions qw/catfile/;

use XML::Writer;

use Mojo::DOM;
use Mojo::File;

# avoid name colission
sub _p { Mojo::File::path(@_) }

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
  my $out = _p($path)->open('w');
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

  # fix the attr if no "name"
  $attr->{name} = $name unless $attr->{name};

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

  my $pattern = Ptk::Gex::Pattern->new($query);
  my @result  = ();
  for (@{$self->_projects}) {
    push @result, $_ if $pattern->match($self->get_resolved_project($_));
  }

  return @result;
}

sub list_project_paths {
  my $self    = shift;
  my $pattern = shift;

  return
    map { $self->get_resolved_project($_)->{path} }
    $self->list_project_names($pattern);
}

sub add_remote {
  my $self = shift;
  my $name = shift or die;
  my $attr = shift or die;

  # fix the attr if no "name"
  $attr->{name} = $name unless $attr->{name};

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

  my $dom = Mojo::DOM->new(_p($file)->slurp);
  for my $e ($dom->at('manifest')->children->each) {
    my $t = $e->tag;
    if ($t eq 'include') {

      # relative to the main manifest file
      my $f = _p(_p($self->path)->dirname, $e->{name});
      push @{$self->include}, $f;

      # parse included manifest
      $self->_parse($f);
    }
    elsif ($t eq 'default') {
      $self->default($e);
    }
    elsif ($t eq 'remote') {
      $self->add_remote($e->{name}, $e);
    }
    elsif ($t eq 'project') {
      $self->add_project($e->{name}, $e);
    }
    elsif ($t eq 'remove-project') {
      $self->del_project($e->{name});
    }
    else {
      $log->debug('skip element: ' . $e);
    }
  }

  return $self;
}

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Gex::Manifest - Manifest file for repo tool

=head1 SYNOPSIS

  use Ptk::Gex::Manifest;

  # load manifest and print out the "path" of each project
  my $m = Ptk::Gex::Manifest->new('.repo/manifests/default.xml');
  for my $n ($m->list_project_names) {
    my $r = $m->get_resolved_project($n);
    say $r->{path};
  }

=head1 DESCRIPTION

L<Ptk::Manifest> is a class for loading, parsing and saving manifest file used
by L<repo|https://gerrit.googlesource.com/git-repo> tool.

=head1 ATTRIBUTES

L<Ptk::Manifest> inherits all attributes from L<Ptk::Base> and implements the
following new ones.

=head2 path

  my path = $m->path;
  my $m   = $m->path('path');

The file path of the manifest, defaults to '.repo/manifests/default.xml'.

=head1 METHODS

L<Ptk::Manifest> inherits all methods from L<Ptk::Base> and implements the
following new ones.

=head2 load

  $m->load;
  $m->load('path');

Load the manifest with the given file path or default one.

=head2 save

  $m->save;
  $m->save('path');

Save the manifest into the file, or save-as the given file path.

The target file will be a flattened manifest.

=head2 add_project

  $m = $m->add_project('foo', { name => 'foo', path => 'bar' });

Add a project with its C<name> and a hash reference for attributes.

The B<name> attribute is mandatory for a project, will be fixed automatically
if it is missing.

=head2 del_project

  $m = $m->del_project('foo');

Delete a project with its C<name>.

=head2 get_project

  my $p = $m->get_project('foo');

Get a project with its C<name> or C<path>.

=head2 get_resolved_project

  my $p = $m->get_resolved_project('foo');

Get a resolved project with its C<name> or C<path>.

A resolved project means that all of its default values are resolved, such as
remote URL, etc.

=head2 get_project_name_by_path

  my $n = $m->get_project_name_by_path('foo');

Get the C<name> of the project given its C<apth>.

=head2 list_project_names

  my $ns = $m->list_project_names;

Get an arrary reference including all the project's names.

=head2 list_project_paths

  my $ps = $m->list_project_paths;

Get an arrary reference including all the project's paths.

=head2 add_remote

  $m = $m->add_remote('foo', { name => 'foo', fetch => 'bar' });

Add a remote with its C<name> and a hash reference for attributes.

The B<name> attribute is mandatory for a remote, will be fixed automatically
if it is missing.

=head2 get_remote

  my $r = $m->get_remote('foo');

Get a remote with its C<name>.

=head2 list_remote_names

  my $rns = $m->list_remote_names;

Get an arrary reference including all the remote's name.

=head1 SEE ALSO

L<Ptk>, L<Ptk::Gex>, L<https://github.com/joez/ptk>.

=cut
