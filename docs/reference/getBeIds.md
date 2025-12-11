# Get biological entities identifiers

Get biological entities identifiers

## Usage

``` r
getBeIds(
  be = c(listBe(), "Probe"),
  source,
  organism = NA,
  restricted,
  entity = TRUE,
  attributes = NULL,
  verbose = FALSE,
  recache = FALSE,
  filter = NULL,
  caseSensitive = FALSE,
  limForCache = 100,
  bef = NULL
)
```

## Arguments

- be:

  one BE or "Probe"

- source:

  the BE ID database or "Symbol" if BE or the probe platform if Probe

- organism:

  organism name

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned.

- entity:

  boolean indicating if the technical ID of BE should be returned

- attributes:

  a character vector listing attributes that should be returned.

- verbose:

  boolean indicating if the CQL query should be displayed

- recache:

  boolean indicating if the CQL query should be run even if the table is
  already in cache

- filter:

  character vector on which to filter id. If NULL (default), the result
  is not filtered: all IDs are taken into account.

- caseSensitive:

  if TRUE the case of provided symbols is taken into account. This
  option will only affect "Symbol" source (default:
  caseSensitive=FALSE).

- limForCache:

  if there are more filter than limForCache results are collected for
  all IDs (beyond provided ids) and cached for futur queries. If not,
  results are collected only for provided ids and not cached.

- bef:

  For internal use only

## Value

a data.frame mapping BE IDs with the following fields:

- **id**: the BE ID

- **preferred**: true if the id is the preferred identifier for the BE

- **BE**: IF entity is TRUE the technical ID of BE

- **db.version**: IF be is not "Probe" and source not "Symbol" the
  version of the DB

- **db.deprecated**: IF be is not "Probe" and source not "Symbol" a
  value if the BE ID is deprecated or FALSE if it's not

- **canonical**: IF source is "Symbol" TRUE if the symbol is canonical

- **organism**: IF be is "Probe" the organism of the targeted BE

If attributes are part of the query, additional columns for each of
them. Scope ("be", "source" and "organism") is provided as a named list
in the "scope" attributes: `attr(x, "scope")`

## See also

[listPlatforms](https://patzaw.github.io/BED/reference/listPlatforms.md),
[listBeIdSources](https://patzaw.github.io/BED/reference/listBeIdSources.md)

## Examples

``` r
if (FALSE) { # \dontrun{
beids <- getBeIds(be="Gene", source="EntrezGene", organism="human", restricted=TRUE)
} # }
```
