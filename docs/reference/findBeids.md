# Find Biological Entity identifiers

Find Biological Entity identifiers

## Usage

``` r
findBeids(toGene = TRUE, ...)
```

## Arguments

- toGene:

  focus on gene entities (default=TRUE): matches from other BE are
  converted to genes.

- ...:

  parameters for
  [beidsServer](https://patzaw.github.io/BED/reference/beidsServer.md)

## Value

NULL if not any result, or a data.frame with the selected values and the
following column:

- **value**: the BE identifier

- **preferred**: preferred identifier for the same BE in the same scope

- **be**: the type of biological entity

- **source**: the source of the identifier

- **organism**: the organism of the BE

- **canonical** (if toGene==TRUE): canonical gene product? (if known)

- **symbol**: the symbol of the identifier (if any)
