# Feeding BED: Load probes targeting BE IDs

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadProbes(d, be = "Transcript", platform, dbname)
```

## Arguments

- d:

  a data.frame with information about the entities to be loaded. It
  should contain the following fields: "id" and "probeID".

- be:

  a character corresponding to the BE targeted by the probes (default:
  "Transcript")

- platform:

  the plateform gathering the probes

- dbname:

  the DB from which the BE ID are taken
