# Feeding BED: Load correspondance between genes and transcripts as expression events

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadIsExpressedAs(d, gdb, tdb)
```

## Arguments

- d:

  a data.frame with information about the expression events. It should
  contain the following fields: "gid", "tid" and "canonical" (optional).

- gdb:

  the DB of Gene IDs

- tdb:

  the DB of Transcript IDs
