# Feeding BED: Load homology between BE IDs

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadIsHomologOf(d, db1, db2, be = "Gene")
```

## Arguments

- d:

  a data.frame with information about the homologies to be loaded. It
  should contain the following fields: "id1" and "id2".

- db1:

  the DB of id1

- db2:

  the DB of id2

- be:

  a character corresponding to the BE type (default: "Gene")
