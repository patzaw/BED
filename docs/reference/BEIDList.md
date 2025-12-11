# Create a BEIDList

Create a BEIDList

## Usage

``` r
BEIDList(l, metadata, scope)
```

## Arguments

- l:

  a named list of BEID vectors

- metadata:

  a data.frame with rownames or a column "**.lname**" all in names of l.
  If missing, the metadata is constructed with **.lname** being the
  names of l.

- scope:

  a list with 3 character vectors of length one named "be", "source" and
  "organism". If missing, it is guessed from l.

## Value

A BEIDList object which is a list of BEID vectors with 2 additional
attributes:

- **metadata**: a data.frame with metadata about list elements. The
  "**.lname**" column correspond to the names of the BEIDList.

- **scope**: the BEID scope ("be", "source" and "organism")

## Examples

``` r
if (FALSE) { # \dontrun{
bel <- BEIDList(
   l=list(
      kinases=c("117283", "3706", "3707", "51447", "80271", "9807"),
      phosphatases=c(
         "130367", "249", "283871", "493911", "57026", "5723", "81537"
      )
   ),
   scope=list(be="Gene", source="EntrezGene", organism="Homo sapiens")
)
scope(bel)
metadata(bel)
metadata(bel) <- dplyr::mutate(
   metadata(bel),
   "description"=c("A few kinases", "A few phosphatases")
)
metadata(bel)
} # }
```
