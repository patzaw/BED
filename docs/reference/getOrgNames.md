# Get organism names from taxonomy IDs

Get organism names from taxonomy IDs

## Usage

``` r
getOrgNames(taxID = NULL)
```

## Arguments

- taxID:

  a vector of taxonomy IDs. If NULL (default) the function lists all
  taxonomy IDs available in the DB.

## Value

A data.frame mapping taxonomy IDs to organism names with the following
fields:

- **taxID**: the taxonomy ID

- **name**: the organism name

- **nameClass**: the class of the name

## See also

[getTaxId](https://patzaw.github.io/BED/reference/getTaxId.md),
[listOrganisms](https://patzaw.github.io/BED/reference/listOrganisms.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getOrgNames(c("9606", "10090"))
getOrgNames("9606")
} # }
```
