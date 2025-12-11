# Explore BE identifiers

This function uses visNetwork to draw all the identifiers corresponding
to one BE (including ProbeID and BESymbol)

## Usage

``` r
exploreBe(
  id,
  source,
  be,
  showBE = FALSE,
  showProbes = FALSE,
  showLegend = TRUE
)
```

## Arguments

- id:

  one ID for the BE

- source:

  the ID source database. **Guessed if not provided**

- be:

  the type of BE. **Guessed if not provided**

- showBE:

  boolean. If TRUE the Biological Entity corresponding to the id is
  shown. If id is isolated (not mapped to any other ID or symbol) BE is
  shown anyway.

- showProbes:

  boolean. If TRUE, probes targeting any BEID are shown.

- showLegend:

  boolean. If TRUE the legend is displayed.

## Examples

``` r
if (FALSE) { # \dontrun{
exploreBe("Gene", "100", "EntrezGene")
} # }
```
