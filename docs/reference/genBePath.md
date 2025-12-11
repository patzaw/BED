# Construct CQL sub-query to map 2 biological entity

Internal use

## Usage

``` r
genBePath(from, to, onlyR = FALSE)
```

## Arguments

- from:

  one biological entity (BE)

- to:

  one biological entity (BE)

- onlyR:

  logical. If TRUE (default: FALSE) it returns only the names of the
  relationships and not the cypher sub-query

## Value

A character value corresponding to the sub-query. Or, if onlyR, a
character vector with the names of the relationships.

## See also

[genProbePath](https://patzaw.github.io/BED/reference/genProbePath.md),
[listBe](https://patzaw.github.io/BED/reference/listBe.md)
