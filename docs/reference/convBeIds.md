# Converts BE IDs

Converts BE IDs

## Usage

``` r
convBeIds(
  ids,
  from,
  from.source,
  from.org,
  to,
  to.source,
  to.org,
  caseSensitive = FALSE,
  canonical = FALSE,
  prefFilter = FALSE,
  restricted = TRUE,
  recache = FALSE,
  limForCache = 2000
)
```

## Arguments

- ids:

  list of identifiers

- from:

  a character corresponding to the biological entity or Probe. **Guessed
  if not provided**

- from.source:

  a character corresponding to the ID source. **Guessed if not
  provided**

- from.org:

  a character corresponding to the organism. **Guessed if not provided**

- to:

  a character corresponding to the biological entity or Probe

- to.source:

  a character corresponding to the ID source

- to.org:

  a character corresponding to the organism

- caseSensitive:

  if TRUE the case of provided symbols is taken into account during
  search. This option will only affect the conversion from "Symbol"
  (default: caseSensitive=FALSE). All the other conversion will be case
  sensitive.

- canonical:

  if TRUE, only returns the canonical "Symbol". (default: FALSE)

- prefFilter:

  boolean indicating if the results should be filter to keep only
  preferred BEID of BE when they exist (default: FALSE). If there are
  several preferred BEID of a BE, all are kept. If there are no
  preferred BEID of a BE, all non-preferred BEID are kept.

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned:
  **Depending on history it can take a very long time to return** **a
  very large result!**

- recache:

  a logical value indicating if the results should be taken from cache
  or recomputed

- limForCache:

  if there are more ids than limForCache. Results are collected for all
  IDs (beyond provided ids) and cached for futur queries. If not,
  results are collected only for provided ids and not cached.

## Value

a data.frame with the following columns:

- **from**: the input IDs

- **to**: the corresponding IDs in `to.source`

- **to.preferred**: boolean indicating if the to ID is a preferred ID
  for the corresponding entity.

- **to.entity**: the entity technical ID of the `to` IDs

This data.frame can be filtered in order to remove duplicated
from/to.entity associations which can lead information bias. Scope
("be", "source" and "organism") is provided as a named list in the
"scope" attributes: `attr(x, "scope")`

## See also

[getBeIdConvTable](https://patzaw.github.io/BED/reference/getBeIdConvTable.md),
[convBeIdLists](https://patzaw.github.io/BED/reference/convBeIdLists.md),
[convDfBeIds](https://patzaw.github.io/BED/reference/convDfBeIds.md)

## Examples

``` r
if (FALSE) { # \dontrun{
oriId <- c("10", "100")
convBeIds(
   ids=oriId,
   from="Gene",
   from.source="EntrezGene",
   from.org="human",
   to.source="Ens_gene"
)
convBeIds(
   ids=oriId,
   from="Gene",
   from.source="EntrezGene",
   from.org="human",
   to="Peptide",
   to.source="Ens_translation"
)
convBeIds(
   ids=oriId,
   from="Gene",
   from.source="EntrezGene",
   from.org="human",
   to="Peptide",
   to.source="Ens_translation",
   to.org="mouse"
)
} # }
```
