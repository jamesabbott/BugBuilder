#!/bin/env perl

######################################################################
#
# Script to configure BugBuilder installation
#
# $HeadURL: https://bss-srv4.bioinformatics.ic.ac.uk/svn/BugBuilder/trunk/bin/configure.pl $
# $Author: jamesa $
# $Revision: 179 $
# $Date: 2016-03-10 10:32:17 +0000 (Thu, 10 Mar 2016) $
#
# This file is part of BugBuilder (https://github.com/jamesabbott/BugBuilder)
# and is distributed under the Artistic License 2.0 - see accompanying LICENSE
# file for details
#
#
######################################################################

=pod

=head1 NAME

configure.pl

=head1 SYNOPSIS

  configure.pl [--auto] [--help] [--manual]

=head1 DESCRIPTION

    Configuration script for BugBuilder

=head1 OPTIONAL ARGUMENTS

=over 4

=item B<auto>: Do not prompt but assume default settings

=item B<help>: display short help text

=item B<man>: display full help text

=back

=head1 REPORTING BUGS

Please report any bugs/issues via github:
https://github.com/jamesabbott/BugBuilder/issues/new

=head1 AUTHOR - James Abbott

Email j.abbott@imperial.ac.uk

=cut

use warnings;
use strict;

use Term::ReadKey;
use FindBin;
use CPAN;
use local::lib "$FindBin::Bin/..";

#  Some Perl depndencies are needed by this script, so install them before getting into
#  the  main installation....

BEGIN {
    require CPAN;
    foreach my $module (
                         qw(Test::More YAML::XS File::Copy::Recursive  Perl4::CoreLibs
                         Parallel::ForkManager Archive::Extract Archive::Tar Archive::Zip
                         Digest::MD5 File::Tee SVG Text::CSV Log::Log4perl JSON Time::Piece
                         CGI HTML::Template Clone)
                       )
    {
        eval "require $module";
        if ( $@ ne "" ) {
            print "\nThe perl $module module used by this script was not found\n";
            print "\nInstalling this module requires write access to your perl installation,
		or the perl 'local::lib' module to be available\n";

            # print "\nInstall this module within the BugBuilder installation [yN] ?\n";

            # ReadMode 'cbreak';
            # my $key = ReadKey(0);
            # ReadMode 'normal';
            #if ( $key =~ /y/i ) {

            #CPAN::install("$module");
            my $ret = CPAN->install("$module");
            print "ret = $ret\n";

            #    eval { require "$module" };
            #    if ( $@ ne "" ) {
            #        print "\nInstall returned $@....\n";
            #        print "$module may not be installed correctly.\n"
            #          . "Please verify your perl configuration then rerun configure.pl\n\n";
            #
            #                    #      exit(1);
            #                }
            print "\n";

            #}
            #           else {
            #                print "\n\nCan not proceed without $module module...\n";
            #                exit;
            #            }
        }
    }
}

use Getopt::Long;
use Pod::Usage;
use File::Which;
use File::Tee qw(tee);
use File::Path qw(rmtree);
use File::Copy;
use File::Basename;
use File::Find::Rule;
use Cwd;
use Term::ReadLine;
use Term::ANSIColor qw(:constants);
use YAML::XS qw(LoadFile);
use Archive::Extract;
use Archive::Tar;
use HTML::Template;

{
    my ( $man, $help, $auto );
    my $res = GetOptions(
                          'auto' => \$auto,
                          'man'  => \$man,
                          'help' => \$help,
                        );

    pod2usage( verbose => 2 ) if ($man);
    pod2usage( verbose => 1, message => "Usage: configure.pl [--auto] [--man] [--help]" ) if ($help);

    my $bin_dir = $FindBin::Bin;
    my $etc_dir = "$FindBin::Bin/../etc";
    my $bb_dir  = "$FindBin::Bin/../";

    $Archive::Extract::PREFER_BIN = 1;
    $ENV{'PATH'} = $FindBin::Bin . ":" . $ENV{'PATH'};

    my $packages = LoadFile("$FindBin::Bin/../etc/package_info.yaml");

    install_bioperl();

    my $term = Term::ReadLine->new("BugBuilder Install");
    my $OUT = $term->OUT() || *STDOUT;

    my $response;
    if ( !$auto ) {
        print "BugBuilder requires a number of packages to be available. We can attempt to install these
	    automatically into the BugBuilder installation\n";

        $response = $term->readline("Install prerequisites from src directory? [Yn]");
    }
    if ( ( $response && $response =~ /[yY]/ ) || ($auto) ) {
        install_prerequisites($packages);
    }

    my $sam2afg_url = "https://sourceforge.net/p/amos/code/ci/master/tree/src/Converters/sam2afg.pl";
    print "Downloading sam2afg from AMOS sourceforge repository...\n";
    my $cmd = "curl -o $bin_dir/samtoafg $sam2afg_url";
    system($cmd) == 0 or die "Error downloading sam2afg: $!";

    my $tmp_dir = $term->readline("Enter path to working directory [/tmp]");
    $tmp_dir = "/tmp/" unless ($tmp_dir);

    my $found_java = which('java');
    my $java       = $term->readline("Enter path to java [Found $found_java]");
    $java = $found_java if ( $java eq "" );

    my $path_config;

    foreach my $package ( @{ $packages->{'packages'} } ) {
        my $binary        = $package->{'binary'};
        my $name          = $package->{'name'};
        my $inst_location = find_package($package);
        if ( $inst_location eq "" ) {
            if ( $binary && !$auto ) {
                $inst_location =
                  $term->readline("Enter path to the $binary file in your $name installation...[Enter to skip]");
                $inst_location = dirname($inst_location);
                chomp($inst_location);
                $inst_location =~ s/[\*\@ ]*$//;    #readline can add some additional decoration
            }
            elsif ( !$auto ) {
                $inst_location = $term->readline("Enter path to your $name installation...[Enter to skip]");
                chomp($inst_location);
                $inst_location =~ s/[\*\@ ]*$//;    #readline can add some additional decoration
            }
            if ( $inst_location eq "" ) {
                print RED, "\n\nWARNING: ", RESET, "$binary installation not found...\n";
            }
        }
        if ($inst_location) {
            my $good_version = check_version( $package, $inst_location );
            print "\t", $package->{'name'} . " path configured as $inst_location...\n";
            $path_config .= $name . "_dir: $inst_location/\n";

            # A patch is required to sam2afg, which has been accepted by both the AMOS and ABySS
            # projects, but has yet to make it into a 'real' release. Until then we'll have to
            # apply it here...
            # 	JCA 220216 - this requires abyss to be installed, which is optional. Instead we'll try retreiving
            # 	from directly from the amos git repo... somewhere up there ^
            #if ( $name eq 'abyss' ) {
            #    copy( "$inst_location/abyss-samtoafg", "$FindBin::Bin/samtoafg" ) or die "Error copying samtoafg: $!";
            #    my $cmd = "patch $FindBin::Bin/samtoafg $FindBin::Bin/../src/sam2afg.patch";
            #    system($cmd) == 0 or die "Error patching sam2afg: $!";
            #    $path_config .= "sam2afg: $FindBin::Bin/samtoafg\n";
            #}
        }
    }

    my $perl_lib = $FindBin::Bin;
    $perl_lib =~ s/bin$/lib\/perl5/;
    $path_config .= "\nperl_lib_path: $perl_lib";

    my $fh     = \*DATA;
    my $config = HTML::Template->new_filehandle($fh);
    $config->param( 'TMP_DIR',       $tmp_dir );
    $config->param( 'JAVA',          $java );
    $config->param( 'INSTALL_PATHS', $path_config );

    open CONFIG, ">$FindBin::Bin/../etc/BugBuilder.yaml"
      or die "Could not open $FindBin::Bin/../etc/BugBuilder.test.yaml: $!";
    print CONFIG $config->output();
    close CONFIG;

}

######################################################################
#
# test_module
#
# Checks if a module is installed
#
# Required params : $ (module name)
#
# Returns         ; $ (1 if installed, 0 otherwsie)
#
######################################################################

sub test_module {

    my $module = shift;

    eval("use $module");
    ( $@ eq "" ) ? return (1) : return (0);

}

######################################################################
#
# get_yn
#
# Obtains a y/n response from the keyboard.
#
# Required params : none
#
# Returns         ; $ (1 if y/Y pressed, 0 otherwsie)
#
######################################################################

sub get_yn {

    ReadMode 'cbreak';
    my $key = ReadKey(0);
    ReadMode 'normal';
    ( $key =~ /y/i ) ? ( return 1 ) : return (0);

}

######################################################################
#
# add_inst_to_path
#
# Adds a directory entry to the path,  if it is not already present...
#
# required params: $ (dir to add)
#
# returns :(0);
#
######################################################################

sub add_inst_to_path {

    my $inst_dir = shift;

    my @dirs = split( /:/, $ENV{'PATH'} );

    $inst_dir =~ s/\/$//;    #make sure paths don't have a trailing slash

    my $found = 0;
    foreach my $dir (@dirs) {
        $found++ if ( $dir eq $inst_dir );
    }
    unless ($found) {
        push @dirs, $inst_dir;
        $ENV{'PATH'} = join( ':', @dirs );
    }
    return (0);
}

######################################################################
#
# install_bioperl
#
# Installs bioperl within the BugBuilder installation if it not present
# on the system
#
# required params: none
#
# returns        : none
#
######################################################################

sub install_bioperl {

    eval "require Bio::SeqIO";
    if ( $@ ne "" ) {
        print "\nBioperl is required by BugBuilder, but was not found\n";
        print "\nInstalling BioPerl requires write access to your perl installation,
		or the perl 'local::lib' module to be available\n";

        print "\nInstall BioPerl within the BugBuilder installation [yN] ?\n";

        ReadMode 'cbreak';
        my $key = ReadKey(0);
        ReadMode 'normal';
        if ( $key =~ /y/i ) {
            CPAN::install("C/CJ/CJFIELDS/BioPerl-1.6.910.tar.gz");
            eval { require Bio::SeqIO };
            if ( $@ ne "" ) {
                print "\nBioperl could not be installed.\n"
                  . "Please verify your perl configuration then rerun configure.pl\n\n";
                exit(1);
            }

            #Bio::FeatureIO now seems to be packaged separately
            CPAN::install("C/CJ/CJFIELDS/Bio-FeatureIO-1.6.905.tar.gz");
            eval { require Bio::FeatureIO };
            if ( $@ ne "" ) {
                print "\nBioperl could not be installed.\n"
                  . "Please verify your perl configuration then rerun configure.pl\n\n";
                exit(1);
            }
            print "\n";
        }
    }
    return;
}

######################################################################
#
# install_prerequistites
#
# unpack and install prerequisites found in src directory
#
# required params: $ (package info hashref)
#                : $ (bin directory)
#
# returns:         $ (0)
#
######################################################################

sub install_prerequisites {

    my $packages = shift;

    my $bin_dir = $FindBin::Bin;
    my $bb_dir  = $bin_dir;
    $bb_dir =~ s/\/bin$//;
    my $pack_dir = $bb_dir . '/packages';

    if ( !-d "$bb_dir/install_logs" ) {
        mkdir "$bb_dir/install_logs" or die "Error creating $bb_dir/install_logs...: $!";
    }
    if ( !-d "$pack_dir" ) {
        mkdir "$pack_dir" or die "Error creating $pack_dir: $!";
    }
    if ( !-d "$pack_dir/bin" ) {
        mkdir "$pack_dir/bin" or die "Error creating $pack_dir/bin: $!";
    }
    if ( !-d "$pack_dir/lib" ) {
        mkdir "$pack_dir/lib" or die "Error creating $pack_dir/lib: $!";
    }

  PACKAGE: foreach my $package ( @{ $packages->{'packages'} } ) {

        my $name         = $package->{'name'};
        my $inst_source  = $package->{'inst_source'};
        my $build_cmd    = $package->{'build_cmd'};
        my $download_url = $package->{'download_url'};
        my $pack_bin_dir = $package->{'bin_dir'};
        my $pack_lib_dir = $package->{'lib_dir'};
        my $installed;

        if ( $pack_bin_dir || $pack_lib_dir ) {
            add_inst_to_path("$pack_dir/$pack_bin_dir") if ( $pack_bin_dir && $pack_bin_dir ne "" );
            $installed = find_package($package);
        }

        if ( !$installed ) {

            my $orig_dir = cwd();

            open LOG, ">$bb_dir/install_logs/$name.log"
              or die "Error creating $bb_dir/install_logs/$name.log: $!";

            $build_cmd =~ s/__BBDIR__/$bin_dir\//g    if ($build_cmd);
            $build_cmd =~ s/__PACKDIR__/$pack_dir\//g if ($build_cmd);
            print LOG "\n\nbuild_cmd = $build_cmd\n\n" if ($build_cmd);

            if ( $inst_source eq 'git' ) {
                print "$name will be downloaded from git repository...\n";
            }
            elsif ( $inst_source && not -e "$FindBin::Bin/../src/$inst_source" ) {
                print YELLOW, "The $name software was not found in $FindBin::Bin/../src\n",                    RESET;
                print YELLOW, "\nIf you wish to use this package within BugBuilder, please download \n",       RESET;
                print YELLOW, "if from  $download_url  and copy the installation file ($inst_source) into \n", RESET;
                print YELLOW, " $FindBin::Bin/../src/\n",                                                      RESET;
                print YELLOW, "\nOnce the software distribution is in place, press 'Y' to install it\n",       RESET;
                print YELLOW, "or 'N' to skip installation of $name\n\n",                                      RESET;

                ReadMode 'cbreak';
                my $key = ReadKey(0);
                ReadMode 'normal';
                if ( $key =~ /n/i ) {
                    next PACKAGE;
                }
            }

            if ( $inst_source && -e "$FindBin::Bin/../src/$inst_source" ) {
                print LOG "\nUnpacking $inst_source...\n";

                # archive;;extract doesn't handle .Z compressed tarfiles nicely, so kludge these with Archive::Tar
                if ( $inst_source =~ /tar\.Z$/ ) {
                    open Z, "zcat $FindBin::Bin/../src/$inst_source |" or die "Error opening piped filehandle: $!";
                    mkdir "$FindBin::Bin/../src/$name" or die "Error creatinig $FindBin::Bin/../src/$name: $!";
                    chdir "$FindBin::Bin/../src/$name" or die "Error chdiring $FindBin::Bin/../src/$name: $!";
                    print LOG "\n\n...now in $FindBin::Bin/../src/$name\n\n";
                    my $extract = Archive::Tar->new( \*Z );
                    $extract->extract();
                    close Z;
                }
                elsif ( $inst_source !~ /.jar$/ ) {

                    my $extract = Archive::Extract->new( archive => "$FindBin::Bin/../src/$inst_source" );
                    print LOG "\n\n...extracting to $FindBin::Bin/../src/$name\n";
                    $extract->extract( to => "$FindBin::Bin/../src/$name" );
                }
                elsif ( $inst_source eq 'git' ) {
                    print LOG"\n\nGit installation...no tarball to extract...\n";
                }
            }
            print "\nBuilding $name...\n\nlogging installation to $bb_dir/install_logs/$name.log\n";
            print LOG "\nBuilding $name...\n";
            open BUILD, "$build_cmd 2>&1 |" if ($build_cmd);
            while (<BUILD>) {
                print LOG;
            }
            close BUILD;
            chdir $orig_dir or warn "Could not chdir to $orig_dir: $!";
            rmtree("$bin_dir/../src/$name");

            $installed = find_package($package);
            unless ($installed) {
                print RED,
                  "\n$name does not seem to have been installed correctly. Please check log file for details...\n",
                  RESET;
            }
        }
        else {
            print LOG "\nInstallation package for $name not found...skipping...\n";
        }
        close LOG;
    }

}

######################################################################
#
# find_package
#
# Checks availability of package on the system,
#
# required params: $ (package data)
#
# returns        : $ (0 on success)
#
######################################################################

sub find_package {

    my $package = shift;

    my $name   = $package->{'name'};
    my $binary = $package->{'binary'};
    my $lib    = $package->{'lib'};
    my $location;

    print "\nLooking for $name installation...";

    if ( defined($binary) ) {

        $location = which($binary);
        if ($location) {
            print GREEN, "\n\t$binary found", RESET, " ($location)...\n";
        }
        else {
            print "not found...\n";
        }
    }
    elsif ( defined($lib) ) {
        my $lib_path = ( File::Find::Rule->file()->name($lib)->in("$FindBin::Bin/../packages") )[0];
        if ($lib_path) {
            $location = ( fileparse($lib_path) )[1];
            print GREEN, "\n\t$lib found", RESET, "($location)...\n";
        }
    }
    my $path;
    ($location) ? ( $path = dirname($location) ) : ( $path = "" );
    if ($lib) {
        return ($location);
    }
    else {
        return ($path);
    }
}

######################################################################
#
# check_version
#
# Compares version of installed software with known 'good' versions
#
# required parametesr: $ (package hashref)
#                      $ (location to test)
#
######################################################################

sub check_version {

    my $package  = shift;
    my $location = shift;
    $location .= "/" . $package->{'binary'} if ( $package->{'binary'} );

    my $known_version = $package->{'version'};
    my $version_test  = $package->{'version_test'};
    my $name          = $package->{'name'};
    my $good          = 0;

    if ( $known_version && $version_test ) {
        $version_test =~ s/__BINARY__/$location/;
        $version_test =~ s/__BBDIR__/$FindBin::Bin\/../;
        my $ret = `$version_test`;
        if ($ret) {
            chomp($ret);
            print "\tfound version $ret...";    # unless ( $name eq 'tbl2asn' );
            foreach my $version (@$known_version) {
                if ( $ret eq $version ) {
                    print "ok\n";
                    $good++;
                }
            }
            if ( $good == 0 ) {

                #tbl2asn 'goes off' after a year, so if it is too old regardless of versioning, shout...
                if ( $name eq 'tbl2asn' ) {
                    $ret = `$location --help 2>&1|head -n1`;
                    if ( $ret =~ /more than a year/ ) {
                        print RED, "\nERROR: ", RESET;
                        print "your tbl2asn installation is more than a"
                          . " year old, and will therefore not run correctly. Please update this\n", RESET;
                    }
                    $location = "";    # pretend we didn't find it...
                }
                else {
                    print YELLOW, "\n\nWARNING: ", RESET;
                    print "Your $name installation reports itself as $ret,"
                      . " whereas BugBuilder has been tested against @$known_version.\n", RESET;
                }
            }
        }
    }
    return ($good);
}
__DATA__
######################################################################
#
# BugBuilder configuration in YAML format
#
# This file defines the BugBuilder configuration. See the BugBuilder 
# User Guide for details of the dependencies which need to be installed.
#
######################################################################
---
# tmp_dir specifies the location on the machine where working directories will be created
tmp_dir: <TMPL_VAR NAME=TMP_DIR>
# java specifies the java binary
java: <TMPL_VAR NAME=JAVA>

<TMPL_VAR NAME=INSTALL_PATHS>

<TMPL_VAR NAME=APPEND_PATH>

# Definition of assembly categories, and platforms
# These are used for automated assembler selection based on assesment of the 
# provided reads. These should ideally not overlap or the choice of category
# may become a bit random
assembler_categories:
  - name: 'short_illumina'
    min_length: 25
    max_length: 100
    single_fastq: 'optional' 
    paired_fastq: 'optional'
    platforms:
      - 'illumina'
    assemblers:
      - spades
      - abyss
    scaffolders:
      - mauve
      - SIS
      - sspace
  - name: 'long_illumina'
    min_length:  75
    max_length: 250
    single_fastq: 'optional'
    paired_fastq: 'optional'
    platforms:
      - 'illumina'
    assemblers:
      - spades
      - celera
    scaffolders:
      - mauve
      - SIS
      - sspace
  - name: '454_IonTorrent'
    min_length: 100
    max_length: 1000
    single_fastq: 'optional'
    paired_fastq: 'optional'
    platforms:
      - '454'
      - 'iontorrent'
    assemblers:
      - celera
    scaffolders:
      - mauve
      - SIS
  - name: 'long'
    min_length: 500
    max_length: 50000
    long_fastq: 'required'
    platforms:
      - 'PacBio'
      - 'MinION'
    assemblers: 
      - PBcR
  - name: 'hybrid'
    min_length: 75
    max_length: 50000
    platforms: 
      - hybrid
    paired_fastq: 'required'
    long_fastq: 'required'
    assemblers:
      - masurca
      - spades
    scaffolders:
      - mauve

#Assembler configuration
assemblers:
   - name: abyss 
     create_dir: 1
     max_length: 200
     command_pe: __BUGBUILDER_BIN__/run_abyss --tmpdir __TMPDIR__ --fastq1 __FASTQ1__ --fastq2 __FASTQ2__ --read_length __READ_LENGTH__
     contig_output: __TMPDIR__/abyss/abyss-contigs.fa
     scaffold_output: __TMPDIR__/abyss/abyss-scaffolds.fa
     downsample_reads: 1
   - name: spades
     create_dir: 0
     max_length: 300
     command_se: __ASMDIR__/spades.py -s __FASTQ1__ -o __TMPDIR__/spades
     command_pe: __ASMDIR__/spades.py -1 __FASTQ1__ -2 __FASTQ2__ -o __TMPDIR__/spades
     command_hybrid: __ASMDIR__/spades.py -1 __FASTQ1__ -2 __FASTQ2__ --pacbio __LONGFASTQ__ -o __TMPDIR__/spades
     contig_output: __TMPDIR__/spades/contigs.fasta
     scaffold_output: __TMPDIR__/spades/scaffolds.fasta
     default_args: -t 8 --careful
     downsample_reads: 1
   - name: celera
     create_dir: 1
     min_length: 75
     command_se: __BUGBUILDER_BIN__/run_celera --fastq1 __FASTQ1__ --tmpdir __TMPDIR__ --category __CATEGORY__ --encoding __ENCODING__ --genome_size __GENOME_SIZE__
     command_pe: __BUGBUILDER_BIN__/run_celera --fastq1 __FASTQ1__ --fastq2 --tmpdir __TMPDIR__ --category __CATEGORY__ --encoding __ENCODING__ --genome_size __GENOME_SIZE__
     contig_output: __TMPDIR__/celera/output/9-terminator/BugBuilder.ctg.fasta
     scaffold_output: __TMPDIR__/celera/output/9-terminator/BugBuilder.scf.fasta
     downsample_reads: 0
   - name: PBcR
     create_dir: 1
     min_length: 500
     command_se: __BUGBUILDER_BIN__/run_PBcR --fastq __LONGFASTQ__ --tmpdir __TMPDIR__ --genome_size __GENOME_SIZE__ --platform __PLATFORM__
     contig_output: __TMPDIR__/PBcR/BugBuilder/9-terminator/asm.ctg.fasta
     scaffold_output: __TMPDIR__/PBcR/BugBuilder/9-terminator/asm.scf.fasta
     downsample_reads: 0
     # masurca works best with untrimmed reads, so use __ORIG_FASTQ1__ nad __ORIG_FASTQ2__
   - name: masurca
     create_dir: 1                                                                                                                                                                                             
     command_pe: __BUGBUILDER_BIN__/run_masurca --fastq1 __ORIG_FASTQ1__ --fastq2 __ORIG_FASTQ2__ --tmpdir __TMPDIR__ --category __CATEGORY__ --insert_size __INSSIZE__ --insert_stddev __INSSD__
     command_hybrid: __BUGBUILDER_BIN__/run_masurca --fastq1 __ORIG_FASTQ1__ --fastq2 __ORIG_FASTQ2__ --longfastq __LONGFASTQ__ --tmpdir __TMPDIR__ --category __CATEGORY__ --insert_size __INSSIZE__ --insert_stddev __INSSD__
     contig_output: __TMPDIR__/masurca/contigs.fasta
     scaffold_output: __TMPDIR__/masurca/scaffolds.fasta 
     default_args: --threads 8                                                                                                                                                                                 
     downsample_reads: 0 

scaffolders:
   - name: SIS
     linkage_evidence: align_genus
     command: __BUGBUILDER_BIN__/run_sis --reference __REFERENCE__ --contigs __CONTIGS__ --tmpdir __TMPDIR__ --scaff_dir __SCAFFDIR__
     scaffold_output: scaffolds.fasta
     unscaffolded_output: unplaced_contigs.fasta
     create_dir: 1
     priority: 2
   - name: mauve
     linkage_evidence: align_genus
     command: __BUGBUILDER_BIN__/run_mauve --reference __REFERENCE__ --run __RUN__ --contigs __CONTIGS__ --tmpdir __TMPDIR__ --scaff_dir __SCAFFDIR__
     create_dir: 1
     priority: 1
     scaffold_output: scaffolds.fasta
   - name: sspace
     linkage_evidence: paired-ends
     command: __BUGBUILDER_BIN__/run_sspace --tmpdir __TMPDIR__ --scaff_dir __SCAFFDIR__ --contigs __CONTIGS__ --insert_size __INSSIZE__ --insert_sd __INSSD__ 
     scaffold_output: BugBuilder.scaffolds.fasta
     create_dir: 1
     priority: 3

merge_tools:
   - name: gfinisher
     command: __BUGBUILDER_BIN__/run_gfinisher --tmpdir __TMPDIR__  --assembler __ASSEMB1__ --assembler __ASSEMB2__ --reference __REFERENCE__
     contig_output: renamed.fasta
     create_dir: 1
     priority: 1
     allow_scaffolding: 1
   - name: minimus
     command: __BUGBUILDER_BIN__/run_minimus --tmpdir __TMPDIR__  --assembler __ASSEMB1__ --assembler __ASSEMB2__
     contig_output: renumbered.fasta
     create_dir: 1
     priority: 2
     allow_scaffolding: 1

finishers:
   - name: gapfiller
     command: __BUGBUILDER_BIN__/run_gapfiller --tmpdir __TMPDIR__ --insert_size __INSSIZE__ --insert_sd __INSSD__
     create_dir: 1
     ref_required: 0
     paired_reads: 1
     priority: 2
   - name: abyss-sealer
     command: __BUGBUILDER_BIN__/run_abyss-sealer --tmpdir __TMPDIR__ --encoding __ENCODING__ --threads __THREADS__
     create_dir: 1
     ref_required: 0
     paired_reads: 1
     priority: 3
   - name: pilon
     command: __BUGBUILDER_BIN__/run_pilon --tmpdir __TMPDIR__
     create_dir: 1
     ref_required: 0
     paired_reads: 1
     priority: 1

varcallers:
   - name: pilon
     command: __BUGBUILDER_BIN__/run_pilon_var --tmpdir __TMPDIR__ --threads __THREADS__
     ref_required: 1
     create_dir: 1
     priority: 1
