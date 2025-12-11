# Explore the shortest convertion path between two identifiers

This function uses visNetwork to draw all the shortest convertion paths
between two identifiers (including ProbeID).

## Usage

``` r
exploreConvPath(
  from.id,
  to.id,
  from,
  from.source,
  to,
  to.source,
  edgeDirection = FALSE,
  showLegend = TRUE,
  verbose = FALSE
)
```

## Arguments

- from.id:

  the first identifier

- to.id:

  the second identifier

- from:

  the type of entity:
  [`listBe()`](https://patzaw.github.io/BED/reference/listBe.md) or
  Probe. **Guessed if not provided**

- from.source:

  the identifier source: database or platform. **Guessed if not
  provided**

- to:

  the type of entity:
  [`listBe()`](https://patzaw.github.io/BED/reference/listBe.md) or
  Probe. **Guessed if not provided**

- to.source:

  the identifier source: database or platform. **Guessed if not
  provided**

- edgeDirection:

  a logical value indicating if the direction of the edges should be
  drawn.

- showLegend:

  boolean. If TRUE the legend is displayed.

- verbose:

  if TRUE the cypher query is shown

## Examples

``` r
if (FALSE) { # \dontrun{
exploreConvPath(
   from.id="ENST00000413465",
   from="Transcript", from.source="Ens_transcript",
   to.id="ENSMUST00000108658",
   to="Transcript", to.source="Ens_transcript"
)
} # }
```
