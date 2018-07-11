###################################################################### 
#
#
# Specfile for running 454/ionTorrent based assemblies with the
# Celera assembler
#
# The available spec-file options are listed in the Celera WGS RunCA 
# documentation:
# http://sourceforge.net/apps/mediawiki/wgs-assembler/index.php?title=RunCA
# 
###################################################################### 

#0-overlaptrim-overlap
# The mer overlapper is more forgiving of homopolymers in 
# overlaps, but seems to have a rather more significant memory footprint
# but the ovl overlapper is still ok with 454 type data
overlapper = ovl
ovlThreads = 8
ovlConcurrency = 4
#overlapper    = mer
merOverlapperSeedBatchSize = 10000
merOverlapperExtendBatchSize = 10000
merOverlapperSeedConcurrency = 8
merOverlapperExtendConcurrency = 8
merOverlapperThreads = 2
# merylThreads defines the number of threads used for initial 
# kmer database construction
merylThreads  = 8
# parallelisation for overlap correction
frgCorrConcurrency = 4
frgCorrThreads     = 2
ovlCorrConcurrency = 8
#unitigger 
unitigger     = bog
utgErrorRate  = 0.03
utgBubblePopping = 0
#consensus building parallelisation
cnsConcurrency = 8
