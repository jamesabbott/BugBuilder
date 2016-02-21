######################################################################
#
# $HeadURL: https://bss-srv4.bioinformatics.ic.ac.uk/svn/BugBuilder/trunk/etc/PBcR_MinION.spec $
# $Author: jamesa $
# $Revision: 119 $
# $Date: 2015-11-01 16:14:14 +0000 (Sun, 01 Nov 2015) $
#
# Sample MinIon spec file based on that from wgs-assembler.sourceforge.net
#
######################################################################

ovlMemory = 32                                                                                                                                               
ovlStoreMemory= 32000                                                                                                                                        
ovlThreads = 8
merylMemory = 32000                                                                                                                                          
merylMemory   = -segments 32 -threads 8
merylThreads  = 8

merSize=14
falconForce=1
falconOptions=--max_n_read 200 --min_idt 0.50 --output_multi --local_match_count_threshold 0
asmOvlErrorRate = 0.3
asmUtgErrorRate = 0.3
asmCgwErrorRate = 0.3
asmCnsErrorRate = 0.3
asmOBT=0
batOptions=-RS -CS
utgGraphErrorRate = 0.3
utgMergeErrorRate = 0.3
