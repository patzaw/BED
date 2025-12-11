# Feeding BED: Dump table from the Ensembl core database

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
dumpEnsCore(
  organism,
  release,
  gv,
  ddir,
  toDump = c("attrib_type", "gene_attrib", "transcript", "external_db", "gene",
    "translation", "external_synonym", "object_xref", "xref", "stable_id_event"),
  env = parent.frame(n = 1)
)
```

## Arguments

- organism:

  the organism to download (e.g. "Homo sapiens").

- release:

  Ensembl release (e.g. "83")

- gv:

  version of the genome (e.g. "38")

- ddir:

  path to the directory where the data should be saved

- toDump:

  the list of tables to download

- env:

  the R environment in which to load the tables when downloaded
