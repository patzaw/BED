# Feeding BED: Load names associated to BEIDs

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadBENames(d, be = "Gene", dbname)
```

## Arguments

- d:

  a data.frame with information about the names to be loaded. It should
  contain the following fields: "id", "name" and "canonical" (optional).

- be:

  a character corresponding to the BE type (default: "Gene")

- dbname:

  the DB of BEID
