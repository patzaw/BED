# Lists all the databases taken into account in the BED database for a biological entity (BE)

Lists all the databases taken into account in the BED database for a
biological entity (BE)

## Usage

``` r
listBeIdSources(
  be = listBe(),
  organism,
  direct = FALSE,
  rel = NA,
  restricted = FALSE,
  recache = FALSE,
  verbose = FALSE,
  exclude = c()
)
```

## Arguments

- be:

  the BE on which to focus

- organism:

  the name of the organism to focus on.

- direct:

  a logical value indicating if only "direct" BE identifiers should be
  considered

- rel:

  a type of relationship to consider in the query (e.g. "is_member_of")
  in order to focus on specific information. If NA (default) all be are
  taken into account whatever their available relationships.

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned. There
  is no impact if direct is set to TRUE.

- recache:

  boolean indicating if the CQL query should be run even if the table is
  already in cache

- verbose:

  boolean indicating if the CQL query should be shown.

- exclude:

  database to exclude from possible selection. Used to filter out
  technical database names such as "BEDTech_gene" and
  "BEDTech_transcript" used to manage orphan IDs (not linked to any gene
  based on information taken from sources)

## Value

A data.frame indicating the number of ID in each available database with
the following fields:

- **database**: the database name

- **nbBe**: number of distinct entities

- **nbId**: number of identifiers

- **be**: the BE under focus

## See also

[listBe](https://patzaw.github.io/BED/reference/listBe.md),
[largestBeSource](https://patzaw.github.io/BED/reference/largestBeSource.md)

## Examples

``` r
if (FALSE) { # \dontrun{
listBeIdSources(be="Transcript", organism="mouse")
} # }
```
