#' Compare 2 BED database instances
#'
#' @param connections a numeric vector of length 1 or 2 providing connections
#' from [lsBedConnections] to be compared.
#'
#' @return If only one connection is provided, the function returns a list
#' with information about BEID and platforms available for the connection
#' along with DB version information.
#' If two connections are provided the same information as above is provided
#' for the 2 connection named V1 and V2 in that order. In addition,
#' differences observed between the 2 instances are reported for BEID and
#' platforms.
#'
#' @details The current connection is restored when exiting this function.
#'
#' @export
compareBedInstances <- function(connections){
   toRestore <- lsBedConnections()[[1]]
   on.exit(connectToBed(
      url=toRestore[["url"]],
      username=toRestore[["username"]],
      password=toRestore[["password"]]
   ))
   if(length(connections)>2){
      stop("Maximum 2 connections can be provided")
   }
   if(length(connections)==0){
      stop("At least 1 connection must be provided")
   }

   ## V1
   connectToBed(connection=connections[1])
   be.V1 <- c()
   for(be in listBe()){
      for(org in listOrganisms()){
         toAdd <- listBeIdSources(
            be=be,
            organism=org,
            exclude=c("BEDTech_gene", "BEDTech_transcript"),
            verbose=FALSE
         )
         if(!is.null(toAdd)){
            colnames(toAdd) <- c("Database", "nbBE", "BEID", "BE")
            toAdd$Organism <- org
            be.V1 <- rbind(
               be.V1,
               toAdd[,c("BE", "Organism", "Database", "BEID")]
            )
         }
      }
   }
   pl.V1 <- listPlatforms()
   db.V1 <- attr(checkBedConn(), "dbVersion")
   if(length(connections)==1){
      return(list(
         BEID=be.V1,
         platforms=pl.V1,
         dbVersion=db.V1
      ))
   }

   ## V2
   connectToBed(connection=connections[2])
   be.V2 <- c()
   for(be in listBe()){
      for(org in listOrganisms()){
         toAdd <- listBeIdSources(
            be=be,
            organism=org,
            exclude=c("BEDTech_gene", "BEDTech_transcript"),
            verbose=FALSE
         )
         if(!is.null(toAdd)){
            colnames(toAdd) <- c("Database", "nbBE", "BEID", "BE")
            toAdd$Organism <- org
            be.V2 <- rbind(
               be.V2,
               toAdd[,c("BE", "Organism", "Database", "BEID")]
            )
         }
      }
   }
   pl.V2 <- listPlatforms()
   db.V2 <- attr(checkBedConn(), "dbVersion")

   ## BEID Comparison
   rownames(be.V1) <- apply(be.V1[,1:3], 1, paste, collapse="..")
   rownames(be.V2) <- apply(be.V2[,1:3], 1, paste, collapse="..")
   beidOnlyInV1 <- be.V1[setdiff(rownames(be.V1), rownames(be.V2)),]
   beidOnlyInV2 <- be.V2[setdiff(rownames(be.V2), rownames(be.V1)),]
   commBeid <- intersect(rownames(be.V1), rownames(be.V2))
   commBeid <- cbind(
      be.V1[commBeid,],
      V2=be.V2[commBeid, "BEID"],
      "Delta"=be.V2[commBeid, "BEID"] - be.V1[commBeid, "BEID"]
   )
   colnames(commBeid) <- c(
      colnames(be.V1)[1:3],
      paste(db.V1[1,], collapse="|"),
      paste(db.V2[1,], collapse="|"),
      "Delta"
   )

   ## Platforms comparison
   plOnlyInV1 <- pl.V1[setdiff(rownames(pl.V1), rownames(pl.V2)),]
   plOnlyInV2 <- pl.V2[setdiff(rownames(pl.V2), rownames(pl.V1)),]
   commPl <- intersect(rownames(pl.V1), rownames(pl.V2))
   commPl <- cbind(
      pl.V1[commPl,],
      pl.V2[commPl,],
      identical=all(
         apply(pl.V1[commPl,], 1, paste, collapse="||")==
            apply(pl.V2[commPl,], 1, paste, collapse="||")
      )
   )
   colnames(commPl) <- c(
      paste0(colnames(pl.V1), " (", paste(db.V1[1,], collapse="|"), ")"),
      paste0(colnames(pl.V2), " (", paste(db.V2[1,], collapse="|"), ")"),
      "Identical def."
   )

   ##
   toRet <- list(
      BEID=list(
         "Only in V1"=beidOnlyInV1,
         "Only in V2"=beidOnlyInV2,
         "Common"=commBeid
      ),
      platforms=list(
        "Only in V1"=plOnlyInV1,
        "Only in V2"=plOnlyInV2,
        "Common"=commPl
      ),
      V1=list(
         BEID=be.V1,
         platforms=pl.V1,
         dbVersion=db.V1
      ),
      V2=list(
         BEID=be.V2,
         platforms=pl.V2,
         dbVersion=db.V2
      )
   )
   return(toRet)
}
