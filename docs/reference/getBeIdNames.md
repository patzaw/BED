# Get names of Biological Entity identifiers

Get names of Biological Entity identifiers

## Usage

``` r
getBeIdNames(ids, be, source, organism, limForCache = 4000, ...)
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

- limForCache:

  if there are more ids than limForCache results are collected for all
  IDs (beyond provided ids) and cached for futur queries. If not,
  results are collected only for provided ids and not cached.

- ...:

  params for the
  [getBeIdNameTable](https://patzaw.github.io/BED/reference/getBeIdNameTable.md)
  function

## Value

a data.frame mapping BE IDs and names with the following fields:

- **id**: the BE ID

- **name**: the corresponding name

- **canonical**: true if the name is canonical for the direct BE ID
  (often FALSE for backward compatibility)

- **direct**: true if the name is directly related to the BE ID

- **preferred**: true if the id is the preferred identifier for the BE

- **entity**: (optional) the technical ID of to BE

## See also

[getBeIdNameTable](https://patzaw.github.io/BED/reference/getBeIdNameTable.md),
[getBeIdSymbols](https://patzaw.github.io/BED/reference/getBeIdSymbols.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdNames(
   ids=c("10", "100"),
   be="Gene",
   source="EntrezGene",
   organism="human"
)
} # }
```
