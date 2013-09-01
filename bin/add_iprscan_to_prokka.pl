#!/usr/bin/perl

######################################################################
#
# Script to parse interpro outputs and merge with EMBL record....
# 
# $HeadURL: https://bss-srv4.bioinformatics.ic.ac.uk/svn/BugBuilder/trunk/bin/add_iprscan_to_prokka.pl $
# $Author: jamesa $
# $Revision: 38 $
# $Date: 2013-08-28 09:36:57 +0100 (Wed, 28 Aug 2013) $
#
######################################################################

use warnings;
use strict;

use XML::Twig;
use Bio::SeqIO;
use GO::Parser;
use Data::Dumper;

{

    my $xml_file = '/data/sriskandan/gap_closure/annotation/H293.xml';
    my $prokka_file =
'/data/sriskandan/gap_closure/annotation/PROKKA_02282013/PROKKA_02282013.embl';
    my $go_obo = "/data/databases/go/gene_ontology_ext.obo";
    my $out = "/data/sriskandan/gap_closure/annotation/H293_with_interpro.embl";

    my %ipr;

    print "Parsing GO...\n";
    my $parser = new GO::Parser( { handler => 'obj' } );
    $parser->parse($go_obo);
    my $graph = $parser->handler->graph;

    print "\nParsing iprscan output...\n";
    my $twig = XML::Twig->new();
    $twig->parsefile($xml_file);
    $twig->set_pretty_print('indented');
    my $root = $twig->root();

    foreach my $protein ( $root->children('protein') ) {
        my $id = ( $protein->children('xref') )[0]->{'att'}->{'id'};
        my ( %res, %go, %pathway );
        foreach my $match ( ( $protein->children('matches') )[0]->children() ) {
            my $signature = ( $match->children('signature') )[0];
            if ( my $entry = ( $signature->children('entry') )[0] ) {
                my $acc  = $entry->{'att'}->{'ac'};
                my $desc = $entry->{'att'}->{'desc'};
                $res{$acc} = $desc;
                foreach my $go ( $entry->children('go-xref') ) {
                    my $id   = $go->{'att'}->{'id'};
                    my $term = $graph->get_term($id);
                    if ( defined($term) ) {
                        my $ancestor_terms =
                          $graph->get_recursive_parent_terms( $term->acc );
                        my $ontology;
                        foreach my $anc_term (@$ancestor_terms) {
                            if ( $anc_term->is_root() ) {
                                $ontology = $anc_term->name();
                            }
                        }

                        $go{$id} = $term->name() . " ($ontology)";
                    }
                }
                foreach my $kegg ( $entry->children('pathway-xref') ) {
                    my $db   = $kegg->{'att'}->{'db'};
                    my $id   = $kegg->{'att'}->{'id'};
                    my $name = $kegg->{'att'}->{'name'};
                    $pathway{"$db:$id"} = $name;
                }
            }
        }

        $ipr{$id} = { 'ipr' => \%res, 'go' => \%go, 'pathway' => \%pathway };

        $protein->purge();
    }

    print "\nParsing embl record...\n";
    my $embl  = Bio::SeqIO->new( -format => 'embl', -file => $prokka_file );
    my $outIO = Bio::SeqIO->new( -format => 'embl', -file => ">$out" );
    my $seq   = $embl->next_seq();
    my $out_seq = $seq;

    print "\nProcessing data...\n";

    foreach my $feat ( $seq->get_all_SeqFeatures ) {
        print $feat->primary_tag(), "\n";
        if ( $feat->primary_tag eq 'CDS' ) {
            my $locus_tag = ( $feat->get_tag_values('locus_tag') )[0];
            my $iprdata   = $ipr{$locus_tag};

            my $iprs = $iprdata->{'ipr'};
            foreach my $ipr ( keys(%$iprs) ) {
                $feat->add_tag_value( 'inference',
                                      "protein motif:InterPro:$ipr" );
            }
            my $gos = $iprdata->{'go'};
            foreach my $go ( keys(%$gos) ) {
                $feat->add_tag_value( 'db_xref', $go );
            }

            $out_seq->add_SeqFeature($feat);
        }
        else {
            $out_seq->add_SeqFeature($feat);
        }
    }
    print "\nWriting output....\n";
    $outIO->write_seq($out_seq);
}
