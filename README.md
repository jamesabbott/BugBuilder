BugBuilder
==========

Hands-free microbial genome assembly

BugBuilder is a pipeline to facilitate assembly and annotation of database submission-ready, draft-quality microbial genomes from high-throughput sequencing data. It utilises a range of existing tools to produce an annotated genome assembly (optionally scaffolded against a reference genome), outputting EMBL formatted records describing the assembled contigs, and AGP v2 files describing the scaffolds. Required inputs are paired-end reads obtained from a modern sequencing instrument (i.e. Illumina MiSeq), and optionally a reference genome sequence in fasta format.

BugBuilder is implemented in Perl and is distributed under the Artistic License v2.0

Prerequisites
=============

BugBuilder requires a considerable number of packagegs to be available, many of which have prerequisites of their own. The specified versions of these packages are those with which it has been tested - other versions may well work fine, however. The following need to be installed prior to running BugBuilder:

* fastqident (https://github.com/DarwinAwardWinner/fastqident)
* sickle 1.2 (https://github.com/najoshi/sickle)
* spades 2.3.0 (http://bioinf.spbau.ru/spades) NB latest release is 2.5.0
* abyss 1.3.4 (http://www.bcgsc.ca/platform/bioinfo/software/abyss) NB latest release is 1.3.6
* AMOS 3.1.0 (http://sourceforge.net/apps/mediawiki/amos/index.php?title=AMOS)
* samtools 0.1.18 (http://samtools.sourceforge.net/)
* picard 1.56 (http://picard.sourceforge.net/)
* SIS (http://marte.ic.unicamp.br:8747/)
* GapFiller 1.10 (http://www.baseclear.com/landingpages/basetools-a-wide-range-of-bioinformatics-solutions/gapfiller/) NB Not open source, but free for academic use
* Prokka 1.5.2 (http://www.vicbioinformatics.com/software.prokka.shtml)
* MUMmer 3.22 (http://mummer.sourceforge.net/)

BugBuilder also requires some non-core Perl modules to be available.

* File::Copy::Recursive
* Parallel::ForkManager
* BioPerl (1.6.901)

Installation
============

Obtain the latest version of the software by running:
<code>git clone git://github.com/jamesabbott/BugBuilder/</code>

The paths to the prerequisite packages are defined within a %config hash at the top of the script. Edit these to reflect your setup.



