BugBuilder
==========

Hands-free microbial genome assembly

BugBuilder is a pipeline to facilitate assembly and annotation of database submission-ready,
draft-quality microbial genomes from high-throughput sequencing data. It utilises a range of
existing tools to produce an annotated genome assembly (optionally scaffolded against a reference
genome), outputting EMBL formatted records describing the assembled contigs, and AGP v2 files
describing the scaffolds. Required inputs are fastq format reads from either a fragmment of 
paired-end sequencing run, and optionally a reference genome sequence in fasta format.

BugBuilder is implemented in Perl and is distributed under the Artistic License v2.0

Installation
============

A virtual machine image preconfigured with the freely redistributable
prerequistite packages is available from
http://web.bioinformatics.ic.ac.uk/BugBuilder/BugBuilder_current.vdi

The latest version of the software can be downloaded by running:
<code>git clone git://github.com/jamesabbott/BugBuilder/</code>

Full installation and configuration instructions are available in the user
guide, which can be obtained from
http://www.imperial.ac.uk/bioinformatics-support-service/resources/software/BugBuilder/,
or if you have latex installed on your machine you can build the documentation
locally:

<code>
[jamesa@codon ~]$ cd BugBuilder/doc
[jamesa@codon ~]$ ./build.sh
</code>



