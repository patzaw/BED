# Feeding BED: Load correspondance between genes and objects as coding events

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadCodesFor(d, gdb, odb)
```

## Arguments

- d:

  a data.frame with information about the coding events. It should
  contain the following fields: "gid" and "oid"

- gdb:

  the DB of Gene IDs

- odb:

  the DB of Object IDs
