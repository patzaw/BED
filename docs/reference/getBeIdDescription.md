# Get description of Biological Entity identifiers

This description can be used for annotating tables or graph based on BE
IDs.

## Usage

``` r
getBeIdDescription(ids, be, source, organism, ...)
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

- ...:

  further arguments for
  [getBeIdNames](https://patzaw.github.io/BED/reference/getBeIdNames.md)
  and
  [getBeIdSymbols](https://patzaw.github.io/BED/reference/getBeIdSymbols.md)
  functions

## Value

a data.frame providing for each BE IDs (row.names are provided BE IDs):

- **id**: the BE ID

- **symbol**: the BE symbol

- **name**: the corresponding name

## See also

[getBeIdNames](https://patzaw.github.io/BED/reference/getBeIdNames.md),
[getBeIdSymbols](https://patzaw.github.io/BED/reference/getBeIdSymbols.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdDescription(
   ids=c("10", "100"),
   be="Gene",
   source="EntrezGene",
   organism="human"
)
} # }
```
