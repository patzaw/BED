# Feeding BED: Load correspondance between transcripts and peptides as translation events

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadIsTranslatedIn(d, tdb, pdb)
```

## Arguments

- d:

  a data.frame with information about the translation events. It should
  contain the following fields: "tid", "pid" and "canonical" (optional).

- tdb:

  the DB of Transcript IDs

- pdb:

  the DB of Peptide IDs
