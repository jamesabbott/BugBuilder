#/bin/bash


#
# Script to build the pdf documentation ..

# Convert pod to latex format for command reference...

pod2latex -h1level 2 -sections '!SYNOPSIS|!DESCRIPTION|!NAME|!AUTHOR' -o command_reference.tex ../bin/BugBuilder 

# Make the document...
pdflatex BugBuilder_User_Guide.tex

