use Ptk::Base -strict;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Ptk::Base::Loader;

package MyLoaderTest::Foo::Bar;

package MyLoaderTest::Foo::Baz;

package main;

my $ldr = Ptk::Base::Loader->new;

# Single character core module
ok !$ldr->load_class('B'), 'loaded';
ok !!UNIVERSAL::can(B => 'svref_2object'), 'method found';

# Search packages
my @pkgs = $ldr->find_packages('MyLoaderTest::Foo');
is_deeply \@pkgs, ['MyLoaderTest::Foo::Bar', 'MyLoaderTest::Foo::Baz'],
  'found the right packages';
is_deeply [$ldr->find_packages('MyLoaderTest::DoesNotExist')], [], 'no packages found';

done_testing();
