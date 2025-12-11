# Get reference URLs for BE IDs

Get reference URLs for BE IDs

## Usage

``` r
getBeIdURL(ids, databases)
```

## Arguments

- ids:

  the BE ID

- databases:

  the databases from which each ID has been taken (if only one database
  is provided it is chosen for all ids)

## Value

A character vector of the same length than ids corresponding to the
relevant URLs. NA is returned is there is no URL corresponding to the
provided database.

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdURL(c("100", "ENSG00000145335"), c("EntrezGene", "Ens_gene"))
} # }
```
