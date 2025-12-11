# Feeding BED: Dump tables with taxonomic information from NCBI

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
dumpNcbiTax(
  reDumpThr,
  ddir,
  toDump = c("names.dmp"),
  env = parent.frame(n = 1),
  curDate
)
```

## Arguments

- reDumpThr:

  time difference threshold between 2 downloads

- ddir:

  path to the directory where the data should be saved

- toDump:

  the list of tables to load

- env:

  the R environment in which to load the tables when downloaded

- curDate:

  current date as given by
  [Sys.Date](https://rdrr.io/r/base/Sys.time.html)
