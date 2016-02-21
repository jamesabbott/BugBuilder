#!/usr/bin/perl

######################################################################
#
# Script to check BugBuilder configuration is valid
# Based on Test::More since it...tests...more....
#
# $HeadURL: https://bss-srv4.bioinformatics.ic.ac.uk/svn/BugBuilder/trunk/bin/check_config.pl $
# $Author: jamesa $
# $Revision: 154 $
# $Date: 2016-02-09 16:35:28 +0000 (Tue, 09 Feb 2016) $
#
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
use Test::Exception;
use File::stat;

print "\nChecking availability of Perl modules...\n\n";

# Start by checking we can load the prerequisite Perl modules
my @modules = qw( FindBin Getopt::Long Pod::Usage YAML::XS Archive::Zip Carp
  Cwd File::Temp File::Path File::Copy File::Copy::Recursive File::Basename
  File::Find::Rule File::Tee PerlIO::gzip Parallel::ForkManager Bio::SeqIO
  Bio::SearchIO Bio::Seq Bio::SeqFeature::Generic Bio::DB::Fasta Text::ASCIITable
  DateTime Statistics::Basic HTML::Template);

foreach my $module (@modules) {
    use_ok($module);
}

print "\nLoading configuration files...\n";
my ($config, $packages);

use YAML::XS qw(LoadFile);

ok( -e "$FindBin::Bin/../etc/BugBuilder.yaml", "BugBuilder.yaml file exists");
ok( $config = LoadFile("$FindBin::Bin/../etc/BugBuilder.yaml"), "BugBuilder configuration parsed ok");
ok(-e "$FindBin::Bin/../etc/package_info.yaml", "package_info.yaml file exists");
ok( $packages = LoadFile("$FindBin::Bin/../etc/package_info.yaml"), "package_info.yaml parsed ok");

print "\nChecking temporary directory...\n";

my $tmp_dir = $config->{'tmp_dir'};
ok(defined($tmp_dir), "tmp_dir is defined...");
ok(-d $tmp_dir, "$tmp_dir directory exists...");
ok(-r $tmp_dir, "$tmp_dir is readable..."); 
ok(-w $tmp_dir, "$tmp_dir is writable..."); 

print "\nChecking java...\n";
my $java = $config->{'java'};
ok(defined($java), "java is defined...");
lives_ok{`$java -version 2>&1 >/dev/null`}, "$java runs ok";

print "\nChecking package installations...\n";
foreach my $package ( @{ $packages->{'packages'} } ) {
	my $bin_dir       = $package->{'bin_dir'};
	my $lib_dir       = $package->{'lib_dir'};
        my $binary        = $package->{'binary'};
		my $lib           = $package->{'lib'};
        my $name          = $package->{'name'};
	my $key = $package->{'key'};
	my $version_test = $package->{'version_test'};
	$version_test=~s/__BBDIR__/$FindBin::Bin\/..\// if ($version_test);
	my @versions = $package->{'version'};
	my $path = $config->{$key};

	print "\n$name\n=====================================\n";

	ok(-d $path, "$name installation directory set");
	if (-d $path) {	
	if ($binary) {
	my $bin_path = (File::Find::Rule->file()->name($binary)->in($path))[0] ;
	ok(-e $bin_path, "$name binary $bin_path found ok...") if ($binary);
	version_test($name, \@versions, $version_test, $bin_path) if ($version_test);	

	print "\n";
	} elsif ($lib) {
	    my $lib_path = (File::Find::Rule->file()->name($lib)->in($path))[0];
	    ok(-e $lib_path, "$name library found ok...($lib_path)") if ($lib);
		my $lib_dir = (fileparse($lib_path))[1];

		version_test($name, \@versions, $version_test, $lib_dir);	
	}
	}

}

sub version_test {

	my $name = shift;
	my $versions = shift;
	my $version_test = shift;
	my $path = shift;

	my $bin_ver;
	# skip version tests if versions not defined
	if ($versions->[0]) {
	$version_test=~s/__BINARY__/$path/;
	lives_ok {$bin_ver=`$version_test`} "$name binary runs ok....";
	chomp $bin_ver;
	
	my $ver_ok=0;
	foreach my $version(@$versions) {
		foreach my $v(@$version) {
		if ($v eq $bin_ver) {
			$ver_ok++;
		}	
	}
	ok($ver_ok > 0, "$name version ok($bin_ver)");

    }
}
}
