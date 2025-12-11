# Get description of genes corresponding to Biological Entity identifiers

This description can be used for annotating tables or graph based on BE
IDs.

## Usage

``` r
getGeneDescription(
  ids,
  be,
  source,
  organism,
  gsource = largestBeSource(be = "Gene", organism = organism, rel = "is_known_as",
    restricted = TRUE),
  limForCache = 2000
)
```

## Arguments

- ids:

  list of identifiers

- be:

  one BE. **Guessed if not provided**

- source:

  the BE ID database. **Guessed if not provided**

- organism:

  organism name. **Guessed if not provided**

- gsource:

  the source of the gene IDs to use. It's chosen automatically by
  default.

- limForCache:

  The number of ids above which the description is gathered for all be
  IDs and cached for futur queries.

## Value

a data.frame providing for each BE IDs (row.names are provided BE IDs):

- **id**: the BE ID

- **gsource**: the Gene ID the column name provides the source of the
  used identifier

- **symbol**: the associated gene symbols

- **name**: the associated gene names

## See also

[getBeIdDescription](https://patzaw.github.io/BED/reference/getBeIdDescription.md),
[getBeIdNames](https://patzaw.github.io/BED/reference/getBeIdNames.md),
[getBeIdSymbols](https://patzaw.github.io/BED/reference/getBeIdSymbols.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getGeneDescription(
   ids=c("1438_at", "1552335_at"),
   be="Probe",
   source="GPL570",
   organism="human"
)
} # }
```
