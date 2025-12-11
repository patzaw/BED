# Check biological entities (BE) identifiers

This function takes a vector of identifiers and verify if they can be
found in the provided source database according to the BE type and the
organism of interest. If an ID is in the DB but not linked directly nor
indirectly to any entity then it is considered as not found.

## Usage

``` r
checkBeIds(ids, be, source, organism, stopThr = 1, caseSensitive = FALSE)
```

## Arguments

- ids:

  a vector of identifiers to be checked

- be:

  biological entity. See
  [getBeIds](https://patzaw.github.io/BED/reference/getBeIds.md).
  **Guessed if not provided**

- source:

  source of the ids. See
  [getBeIds](https://patzaw.github.io/BED/reference/getBeIds.md).
  **Guessed if not provided**

- organism:

  the organism of interest. See
  [getBeIds](https://patzaw.github.io/BED/reference/getBeIds.md).
  **Guessed if not provided**

- stopThr:

  proportion of non-recognized IDs above which an error is thrown.
  Default: 1 ==\> no check

- caseSensitive:

  if FALSE (default) the case is not taken into account when checking
  ids.

## Value

invisible(TRUE). Stop if too many (see stopThr parameter) ids are not
found. Warning if any id is not found.

## See also

[getBeIds](https://patzaw.github.io/BED/reference/getBeIds.md),
[listBeIdSources](https://patzaw.github.io/BED/reference/listBeIdSources.md),
[getAllBeIdSources](https://patzaw.github.io/BED/reference/getAllBeIdSources.md)

## Examples

``` r
if (FALSE) { # \dontrun{
checkBeIds(
   ids=c("10", "100"), be="Gene", source="EntrezGene", organism="human"
)
checkBeIds(
   ids=c("10", "100"), be="Gene", source="Ens_gene", organism="human"
)
} # }
```
