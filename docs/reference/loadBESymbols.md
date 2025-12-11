# Feeding BED: Load symbols associated to BEIDs

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadBESymbols(d, be = "Gene", dbname)
```

## Arguments

- d:

  a data.frame with information about the symbols to be loaded. It
  should contain the following fields: "id", "symbol" and "canonical"
  (optional).

- be:

  a character corresponding to the BE type (default: "Gene")

- dbname:

  the DB of BEID
