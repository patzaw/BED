# Feeding BED: Download NCBI gene DATA and load gene, transcript and peptide information in BED

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
getNcbiGeneTransPep(organism, reDumpThr = 1e+05, ddir, curDate)
```

## Arguments

- organism:

  character vector of 1 element corresponding to the organism of
  interest (e.g. "Homo sapiens")

- reDumpThr:

  time difference threshold between 2 downloads

- ddir:

  path to the directory where the data should be saved

- curDate:

  current date as given by
  [Sys.Date](https://rdrr.io/r/base/Sys.time.html)
