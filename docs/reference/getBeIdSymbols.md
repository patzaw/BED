# Get symbols of Biological Entity identifiers

Get symbols of Biological Entity identifiers

## Usage

``` r
getBeIdSymbols(ids, be, source, organism, limForCache = 4000, ...)
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

  if there are more ids than limForCache. Results are collected for all
  IDs (beyond provided ids) and cached for futur queries. If not,
  results are collected only for provided ids and not cached.

- ...:

  params for the
  [getBeIdSymbolTable](https://patzaw.github.io/BED/reference/getBeIdSymbolTable.md)
  function

## Value

a data.frame with the following fields:

- **id**: the from BE ID

- **symbol**: the BE symbol

- **canonical**: true if the symbol is canonical for the direct BE ID

- **direct**: false if the symbol is not directly associated to the BE
  ID

- **preferred**: true if the id is the preferred identifier for the BE

- **entity**: (optional) the technical ID of to BE

## See also

[getBeIdSymbolTable](https://patzaw.github.io/BED/reference/getBeIdSymbolTable.md),
[getBeIdNames](https://patzaw.github.io/BED/reference/getBeIdNames.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdSymbols(
   ids=c("10", "100"),
   be="Gene",
   source="EntrezGene",
   organism="human"
)
} # }
```
