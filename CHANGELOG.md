# Change Log
## - 3 Dec 2016
  - Added id_check sub to verify %id of reference to assembly before attempting scaffolding

## - 1 Nov 2016
  - Added pilon as new finishing method

## - 31 Oct 2016
  - Added GFinsher as alternate assembly merging method
  - Added 'finishing' module, with options for GapFiller and abyss-sealer moved
    from main script to separate wrappers

## - 25 October 2016
  - BUGFIX: Coverage estimates incorrect for fragmented reference sequences,
    leading to excessive downsampling and failed assemblies

## - 19 October 2016
  - Added support for MaSuRCA assembler, for long illumina and hybrid assemblies
  - A few fixes to improve handling of hybrid assemblies

## - 12 October 2016
  - Added 'assembly_gap' features to EMBL format scaffold record. ENA
    submissions can be made with scaffolds like this instead of needing the AGP
    file

## - 9 October 2016
  - Bugfix: scaffolded assemblies were not correctly splitting scaffolds into contigs.fasta

## [1.0.1]  - 31 July 2016
### Added
 - support for Abyss gapsealer as alternative gap closure method (Andrey Tovchigrechko)
 - perl 5.22 support (Andrey Tovchigrechko)

### Fixed
 - whitespace resulting in invalid code  (Andrey Tovchigrechko)
 - hard-coded path in run_scaffolder (Andrey Tovchigrechko)
 - cope with asn2gb line wrapping isssue (Andrey Tovchigrechko)
 - only load amosvalidate features where outputs files present (Andrey Tovchigrechko)
 - suppress 'inapproriate ioctl for device' messages in run_circleator (Andrey Tovchigrechko)
