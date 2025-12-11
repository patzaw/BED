# Feeding BED: Dump tables from the NCBI gene DATA

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
dumpNcbiDb(
  taxOfInt,
  reDumpThr,
  ddir,
  toLoad = c("gene_info", "gene2ensembl", "gene_group", "gene_orthologs", "gene_history",
    "gene2refseq"),
  env = parent.frame(n = 1),
  curDate
)
```

## Arguments

- taxOfInt:

  the organism to download (e.g. "9606").

- reDumpThr:

  time difference threshold between 2 downloads

- ddir:

  path to the directory where the data should be saved

- toLoad:

  the list of tables to load

- env:

  the R environment in which to load the tables when downloaded

- curDate:

  current date as given by
  [Sys.Date](https://rdrr.io/r/base/Sys.time.html)
