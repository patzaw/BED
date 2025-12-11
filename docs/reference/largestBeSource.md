# Autoselect source of biological entity identifiers

The selection is based on direct identifiers

## Usage

``` r
largestBeSource(
  be,
  organism,
  rel = NA,
  restricted = TRUE,
  exclude = c("BEDTech_gene", "BEDTech_transcript")
)
```

## Arguments

- be:

  the biological entity under focus

- organism:

  the organism under focus

- rel:

  a type of relationship to consider in the query (e.g. "is_member_of")
  in order to focus on specific information. If NA (default) all be are
  taken into account whatever their available relationships.

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also taken into
  account.

- exclude:

  database to exclude from possible selection. Used to filter out
  technical database names such as "BEDTech_gene" and
  "BEDTech_transcript" used to manage orphan IDs (not linked to any gene
  based on information taken from sources)

## Value

The name of the selected source. The selected source will be the one
providing the largest number of current identifiers.

## See also

[listBeIdSources](https://patzaw.github.io/BED/reference/listBeIdSources.md)

## Examples

``` r
if (FALSE) { # \dontrun{
largestBeSource(be="Gene", "Mus musculus")
} # }
```
