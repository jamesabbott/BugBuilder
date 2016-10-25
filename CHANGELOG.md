# Change Log
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
