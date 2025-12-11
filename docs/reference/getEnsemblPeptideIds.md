# Feeding BED: Download Ensembl DB and load peptide information in BED

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
getEnsemblPeptideIds(organism, release, gv, ddir, dbCref, canChromosomes)
```

## Arguments

- organism:

  character vector of 1 element corresponding to the organism of
  interest (e.g. "Homo sapiens")

- release:

  the Ensembl release of interest (e.g. "83")

- gv:

  the genome version (e.g. "38")

- ddir:

  path to the directory where the data should be saved

- dbCref:

  a named vector of characters providing cross-reference DB of interest.
  These DB are also used to find indirect ID associations.

- canChromosomes:

  canonical chromosmomes to be considered as preferred ID (e.g. c(1:22,
  "X", "Y", "MT") for human)
