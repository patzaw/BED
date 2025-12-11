# Feeding BED: Load BE ID associations

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadIsAssociatedTo(d, db1, db2, be = "Gene")
```

## Arguments

- d:

  a data.frame with information about the associations to be loaded. It
  should contain the following fields: "id1" and "id2". At the end id1
  is associated to id2 (this way and not the other).

- db1:

  the DB of id1

- db2:

  the DB of id2

- be:

  a character corresponding to the BE type (default: "Gene")

## Details

When associating one id1 to id2, the BE identified by id1 is deleted
after that its production edges have been transferred to the BE
identified by id2. After this operation all id "corresponding_to" id1 do
not directly identify any BE as they are supposed to do. Thus, to run
this function with id1 involved in "corresponds_to" edges.
