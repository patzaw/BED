# Feeding BED: Load taxonomic information from NCBI

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadNcbiTax(reDumpThr, ddir, orgOfInt = c("human", "rat", "mouse"), curDate)
```

## Arguments

- reDumpThr:

  time difference threshold between 2 downloads

- ddir:

  path to the directory where the data should be saved

- orgOfInt:

  organisms of interest: a character vector

- curDate:

  current date as given by
  [Sys.Date](https://rdrr.io/r/base/Sys.time.html)
