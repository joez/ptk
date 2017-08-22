requires 'perl', '5.010001';

requires 'local::lib'            => '2.0';
requires 'Mojolicious'           => '7.0';
requires 'Parallel::ForkManager' => '1.12';
requires 'XML::Writer'           => '0.61';

# for gex
requires 'Git::Repository::Log'  => '1.31';
requires 'Archive::Zip'          => '1.46';
requires 'System::Command'       => '1.111';
requires 'Excel::Writer::XLSX'   => '0.67';

on test => sub {
    requires 'Test::More';
};

on develop => sub {
    requires 'Perl::Tidy'            => '2016';
};
