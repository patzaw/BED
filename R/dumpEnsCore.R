#' Feeding BED: Dump table from the Ensembl core database
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param organism the organism to download (e.g. "Homo sapiens").
#' @param release Ensembl release (e.g. "83")
#' @param gv version of the genome (e.g. "38")
#' @param ddir path to the directory where the data should be saved
#' @param toDump the list of tables to download
#' @param env the R environment in which to load the tables when downloaded
#'
dumpEnsCore <- function(
    organism,
    release,
    gv,
    ddir,
    toDump=c(
        "attrib_type", "gene_attrib", "transcript",
        "external_db", "gene", "translation",
        "external_synonym", "object_xref", "xref",
        "stable_id_event"
    ),
    env=parent.frame(n=1)
){
    dumpDir <- file.path(ddir, paste(
        gsub(" ", "_", tolower(organism)),
        "core", release, gv,
        sep="_"
    ))
    dir.create(dumpDir, showWarnings = F)
    ftp <- paste0(
        "ftp://ftp.ensembl.org/pub/release-", release,
        "/mysql/", dumpDir, "/"
    )
    ## SQL file
    f <- paste0(dumpDir, ".sql.gz")
    message(f)
    sqlf <- lf <- file.path(dumpDir, f)
    if(!file.exists(lf)){
        message(Sys.time(), " --> Downloading...")
        utils::download.file(
            url=paste0(ftp, f),
            destfile=lf,
            method="wget",
            quiet=T
        )
    }
    coreSql <- readLines(sqlf)
    tableStarts <- grep("^CREATE TABLE", coreSql)
    tableEnds <- grep("^)", coreSql)
    tables <- mapply(
        function(s, e){
            tname <- sub("[`].*$", "", sub("^CREATE TABLE [`]", "", coreSql[s]))
            fields <- grep("^[[:blank:]]*[`]", coreSql[(s+1):(e-1)], value=T)
            fields <- sub("[`].*$", "", sub("^[[:blank:]]*[`]", "", fields))
            return(list(tname=tname, fields=fields))
        },
        tableStarts,
        tableEnds,
        SIMPLIFY=F
    )
    tables.names <- unlist(lapply(tables, function(x) x$tname))
    tables.fields <- lapply(tables, function(x) x$fields)
    names(tables.fields) <- tables.names
    ## Data files
    for(td in toDump){
        f <- paste0(td, ".txt.gz")
        message(f)
        lf <- file.path(dumpDir, f)
        if(!file.exists(lf)){
            message(Sys.time(), " --> Downloading...")
            utils::download.file(
                url=paste0(ftp, f),
                destfile=lf,
                method="wget",
                quiet=T
            )
        }
        df <- file.path(dumpDir, paste0(td, ".rda"))
        if(!file.exists(df)){
            # tmp <- readLines(lf, encoding="UTF-8")
            tmp <- readr::read_file(lf)
            tmp <- gsub("\r\n", " ", tmp)
            tmp <- gsub("\r\\\\n", "", tmp)
            tmp <- strsplit(tmp, split="\n")[[1]]
            toRm <- which(tmp=="\\")
            if(length(toRm)>0){
                toRm <- c(toRm, toRm+1)
                tmp <- tmp[-toRm]
            }
            tmp <- paste(tmp, collapse="\n")
            tmp <- gsub("[\\]\n", "", tmp)
            tmp <- unlist(strsplit(tmp, split="\n"))
            tmpf <- tempfile()
            write(tmp, tmpf, ncolumns=1)
            data <- utils::read.table(
                tmpf,
                sep="\t", quote="", comment.char="",
                header=F, stringsAsFactors=F
            )
            # colnames(data) <- doc$Column
            colnames(data) <- tables.fields[[td]]
            assign(td, data)
            save(list=td, file= df)
        }
        load(df, envir=env)
    }

}
