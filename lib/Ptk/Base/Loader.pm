# author: joe.zheng

package Ptk::Base::Loader;
use base 'Mojo::Loader';
use Ptk::Base -base;

Mojo::Loader->import(qw/data_section file_is_binary load_class find_modules/);

sub data      { shift; data_section(@_) }
sub is_binary { shift; file_is_binary(@_) }
sub load      { shift; load_class(@_) }
sub search { shift; [find_modules(@_)] }

1;
__END__
