# Feeding BED: Load history of BEIDs

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadHistory(d, dbname, be = "Gene")
```

## Arguments

- d:

  a data.frame with information about the history. It should contain the
  following fields: "old" and "new".

- dbname:

  the DB of BEID

- be:

  a character corresponding to the BE type (default: "Gene")
