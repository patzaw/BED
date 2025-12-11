# Connect to a neo4j BED database

Connect to a neo4j BED database

## Usage

``` r
connectToBed(
  url = NULL,
  username = NULL,
  password = NULL,
  connection = 1,
  remember = FALSE,
  useCache = NA,
  importPath = NULL,
  .opts = list()
)
```

## Arguments

- url:

  a character string. The host and the port are sufficient (e.g:
  "localhost:5454")

- username:

  a character string

- password:

  a character string

- connection:

  the id of the connection already registered to use. By default the
  first registered connection is used.

- remember:

  if TRUE connection information is saved localy in a file and used to
  automatically connect the next time. The default is set to FALSE. All
  the connections that have been saved can be listed with
  [lsBedConnections](https://patzaw.github.io/BED/reference/lsBedConnections.md)
  and any of them can be forgotten with
  [forgetBedConnection](https://patzaw.github.io/BED/reference/forgetBedConnection.md).

- useCache:

  if TRUE the results of large queries can be saved locally in a file.
  The default is FALSE for policy reasons. But it is recommended to set
  it to TRUE to improve the speed of recurrent queries. If NA (default
  parameter) the value is taken from former connection if it exists or
  it is set to FALSE.

- importPath:

  the path to the import folder for loading information in BED (used
  only when feeding the database ==\> default: NULL)

- .opts:

  a named list identifying the curl options for the handle (see
  [`neo2R::startGraph()`](https://rdrr.io/pkg/neo2R/man/startGraph.html)).

## Value

This function does not return any value. It prepares the BED environment
to allow transparent DB calls.

## Details

Be careful that you should reconnect to BED database each time the
environment is reloaded. It is done automatically if `remember` is set
to TRUE.

Information about how to get an instance of the BED 'Neo4j' database is
provided here:

- <https://github.com/patzaw/BED#bed-database-instance-available-as-a-docker-image>

- <https://github.com/patzaw/BED#build-a-bed-database-instance>

## See also

[checkBedConn](https://patzaw.github.io/BED/reference/checkBedConn.md),
[lsBedConnections](https://patzaw.github.io/BED/reference/lsBedConnections.md),
[forgetBedConnection](https://patzaw.github.io/BED/reference/forgetBedConnection.md)
