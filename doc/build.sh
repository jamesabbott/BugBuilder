#/bin/bash


# $HeadURL: https://bss-srv4.bioinformatics.ic.ac.uk/svn/BugBuilder/trunk/doc/build.sh $
# $Author: jamesa $
# $Date: 2013-08-31 23:30:38 +0100 (Sat, 31 Aug 2013) $
# $Revision: 54 $
#
# Script to build the pdf documentation ..

# Convert pod to latex format for command reference...

pod2latex -h1level 2 -sections '!SYNOPSIS|!DESCRIPTION|!NAME|!AUTHOR' -o command_reference.tex ../bin/BugBuilder 

# Make the document...
pdflatex BugBuilder_User_Guide.tex

