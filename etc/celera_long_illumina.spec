###################################################################### 
#
# $HeadURL: https://bss-srv4.bioinformatics.ic.ac.uk/svn/BugBuilder/trunk/etc/celera_long_illumina.spec $ 
# $Author: jamesa $
# $Date: 2013-09-14 12:53:43 +0100 (Sat, 14 Sep 2013) $
# $Revision: 75 $
#
# Specfile for running long illumina based assemblies with the
# Celera assembler
#
# The available spec-file options are listed in the Celera WGS RunCA 
# documentation:
# http://sourceforge.net/apps/mediawiki/wgs-assembler/index.php?title=RunCA
# 
###################################################################### 

#0-overlaptrim-overlap
overlapper = ovl
ovlThreads = 8
ovlConcurrency = 4
# merylThreads defines the number of threads used for initial 
# kmer database construction
merylThreads  = 8
# parallelisation for overlap correction
frgCorrConcurrency = 4
frgCorrThreads     = 2
ovlCorrConcurrency = 8
#unitigger 
unitigger     = bogart
utgBubblePopping = 0
batMemory = 32
#consensus building parallelisation
cnsConcurrency = 8
