# author: joe.zheng

package Ptk::Manifest;
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
has _dom          => sub { Mojo::DOM->new };
has _default      => sub { {} };
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

  return $self->_dom($self->_parse($path));
}

sub save { shift->save_unified(@_) }

sub save_unified {
  my $self = shift;
  my $path = shift // $self->path;

  # handy subs
  # get sorted attributes
  my $SA = sub {
    map { ($_, $_[0]->{$_}) } sort keys %{$_[0]};
  };

  # generate sort sub by an attribute
  my $GS = sub {
    my $n = $_[0];
    return sub { $a->{$n} cmp $b->{$n} };
  };

  my $out = _p($path)->open('w');
  my $wtr = XML::Writer->new(
    OUTPUT      => $out,
    ENCODING    => 'UTF-8',
    UNSAFE      => 1,
    DATA_MODE   => 1,
    DATA_INDENT => 4,
  );
  $wtr->xmlDecl;
  $wtr->startTag('manifest');

  for my $n (sort +$self->list_remote_names) {
    my $item = $self->get_remote($n);
    $wtr->emptyTag('remote', $SA->($item));
  }
  $wtr->characters("\n");

  my $default = $self->_default;
  $wtr->emptyTag('default', $SA->($default));
  $wtr->characters("\n");

  my %tags_sort_by
    = (annotation => 'name', copyfile => 'src', linkfile => 'src',);
  for my $n (sort +$self->list_project_names) {
    my $item = $self->get_project($n);
    $wtr->emptyTag('project', $SA->($item)) and next
      unless $item->children->size;

    $wtr->startTag('project', $SA->($item));
    for my $t (sort keys %tags_sort_by) {
      $item->find($t)->sort($GS->($tags_sort_by{$t}))->each(
        sub {
          $wtr->emptyTag($t, $SA->($_));
        }
      );
    }
    $wtr->endTag;
  }

  $wtr->endTag;
  $wtr->end;
  $out->close;

  return $self;
}

sub _NE {
  my $tag = shift or croak('no tag');
  my $attr = shift;

  my $e = Mojo::DOM->new("<$tag></$tag>")->at("$tag");
  $e->attr($attr) if $attr;

  return $e;
}

sub _AM {
  $_[0]->at('manifest');
}

sub add_project {
  my $self = shift;
  my $name = shift or croak('no name');
  my $attr = shift or croak('no atrr');
  my $opts = shift // {};

  # fix the attr if no "name"
  $attr->{name} = $name unless $attr->{name};

  # insert a project element into the DOM
  my $proj = _NE('project', $attr);
  while (my ($k, $v) = each %$opts) {
    my $c = _NE($k, $v);
    $proj->append_content($c);
  }
  _AM($self->_dom)->append_content($proj);

  return $self->_add_project($proj);
}

sub _add_project {
  my $self = shift;
  my $that = shift or croak('no object provided');

  my $name = $that->{name};

  # there is no "path" defined for mirror project
  my $path = $that->{path} || $name;
  my $data = $self->_project_data;

  push @{$self->_projects}, $name unless $data->{$name};
  $data->{$name} = $that;

  $self->_path_to_name->{$path} = $name;

  return $self;
}

sub del_project {
  my $self = shift;
  my $name = shift or croak('no name');

  # remove project element from the DOM
  my $q = join ', ',
    map {"$_\[name=$name]"} qw/project remove-project extend-project/;
  $self->_dom->find($q)->map('remove');

  return $self->_del_project($name);
}

sub _del_project {
  my $self = shift;
  my $name = shift or croak('no name');

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
  my $name = shift or croak('no name');

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
  my $name = shift or croak('no name');

  my $p = $self->get_project($name);
  return $p unless $p;

  # real name
  $name = $p->{name};

  my $resolved = $self->stash('resolved_projects') || {};
  unless ($resolved->{$name}) {
    my $d = $self->_default;
    my $n = $p->{remote} || $d->{remote};
    my $r = $self->get_remote($n);
    my $m = {%$d, %$r, %$p};

    # clone the project and resolve the attributes
    my $t = Mojo::DOM->new($p)->at("project")->attr($m);

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
  my $name = shift or croak('no name');
  my $attr = shift or croak('no attr');

  # fix the attr if no "name"
  $attr->{name} = $name unless $attr->{name};

  # insert a remote element into the DOM
  my $remote = _NE('remote', $attr);
  _AM($self->_dom)->append_content($remote);

  return $self->_add_remote($remote);
}

sub _add_remote {
  my $self = shift;
  my $that = shift or croak('no object provided');

  my $name = $that->{name};
  my $data = $self->_remote_data;

  push @{$self->_remotes}, $name unless $data->{$name};
  $data->{$name} = $that;

  return $self;
}

sub get_remote { $_[0]->_remote_data->{$_[1]} }

sub list_remote_names { @{shift->_remotes} }

sub _parse {
  my $self = shift;
  my $file = shift or croak('no file');

  croak("can't access manifest: $file") unless -e $file;

  my $dom = Mojo::DOM->new(_p($file)->slurp);
  for my $e (_AM($dom)->children->each) {
    my $t = $e->tag;
    if ($t eq 'include') {

      # relative to the folder of the root manifest
      my $f = _p($self->path)->sibling($e->{name});
      push @{$self->include}, $f;

      # parse included manifest
      my $d = $self->_parse($f);

      # and append the parsed manifest
      $e->append_content($d);
    }
    elsif ($t eq 'default') {
      $self->_default($e);
    }
    elsif ($t eq 'remote') {
      $self->_add_remote($e);
    }
    elsif ($t eq 'project') {
      $self->_add_project($e);
    }
    elsif ($t eq 'remove-project') {
      $self->_del_project($e->{name});
    }
    else {
      # skip
    }
  }

  return $dom;
}

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Manifest - Manifest file for repo tool

=head1 SYNOPSIS

  use Ptk::Manifest;

  # load manifest and print out the "path" of each project
  my $m = Ptk::Manifest->new('.repo/manifests/default.xml');
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
