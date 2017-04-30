# author: joe.zheng

package Ptk::Loader;
use Ptk::Base -base;

use Mojo::Util qw/monkey_patch/;

# we don't want to import any functions
require Mojo::Loader;

my @subs
  = qw/data_section file_is_binary load_class find_modules find_packages/;
for my $m (@subs) {
  no strict 'refs';
  my $s = \&{"Mojo::Loader::$m"};
  monkey_patch(__PACKAGE__, $m, sub { shift; $s->(@_) });
}

1;
__END__

=encoding utf8

=head1 NAME

Ptk::Loader - Load all kinds of things

=head1 SYNOPSIS

  use Ptk::Loader;

  my $ldr = Ptk::Loader->new;
  # Find modules in a namespace
  for my $module ($ldr->find_modules('Some::Namespace')) {

    # Load them safely
    my $e = $ldr->load_class($module);
    warn qq{Loading "$module" failed: $e} and next if ref $e;

    # And extract files from the DATA section
    say $ldr->data_section($module, 'some_file.txt');
  }

=head1 DESCRIPTION

L<Ptk::Loader> is a class wrapper of L<Mojo::Loader>

=head1 SEE ALSO

L<Ptk>, L<Mojo::Loader>, L<https://github.com/joez/ptk>.

=cut
