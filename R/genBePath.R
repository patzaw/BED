#' Construct CQL sub-query to map 2 biological entity
#'
#' Internal use
#'
#' @param from one biological entity (BE)
#' @param to one biological entity (BE)
#' @param onlyR logical. If TRUE (default: FALSE) it returns only the names
#' of the relationships and not the cypher sub-query
#'
#' @return A character value corresponding to the sub-query.
#' Or, if onlyR, a character vector with the names of the relationships.
#'
#' @seealso [genProbePath], [listBe]
#'
genBePath <- function(from, to, onlyR=FALSE){
   if(from==to){
      stop('from and to should be different.')
   }
   cqRes <- bedCall(
      neo2R::cypher,
      query=neo2R::prepCql(c(
         sprintf(
            'MATCH (f:BEType {value:"%s"})',
            from
         ),
         sprintf(
            'MATCH (t:BEType {value:"%s"})',
            to
         ),
         'MATCH p=shortestPath((f)-[:produces*1..]-(t))',
         'UNWIND relationships(p) as r',
         'MATCH (s)-[r]->(e)',
         'RETURN id(r) as id, r.how as how,',
         'id(s) as s_id, s.value, id(e) as e_id, e.value'
      )),
      result="row"
   )
   if(is.null(cqRes) || nrow(cqRes)==0){
      stop("Cannot find any paths between from and to.")
   }
   rtable <- cqRes[,c("id", "s_id", "e_id", "how")]
   colnames(rtable) <- c("id", "start", "end", "how")

   stable <- cqRes[, c("s_id", "s.value")]
   etable <- cqRes[, c("e_id", "e.value")]
   colnames(stable) <- colnames(etable) <- c("id", "value")
   ntable <- unique(rbind(stable, etable))

   ##################################
   genCypher <- function(fid, usedR, onlyR){
      curR <- rtable[which(
         (rtable$start==fid | rtable$end==fid) & !rtable$id %in% usedR
      ),]
      if(nrow(curR)>1){
         stop("Several possible paths")
      }
      if(nrow(curR)==0){
         if(onlyR){
            return(c())
         }else{
            return("")
         }
      }
      if(fid==curR$"start"){
         toRet <- paste0('-[:', curR$how, ']->')
         nid <- curR$end
      }else{
         toRet <- paste0('<-[:', curR$how, ']-')
         nid <- curR$start
      }
      if(onlyR){
         toRet <- curR$how
      }
      toApp <- genCypher(nid, c(usedR, curR$id), onlyR=onlyR)
      if(onlyR){
         toRet <- c(toRet, toApp)
      }else{
         if(toApp!=""){
            toRet <- paste0(
               toRet,
               "(:",  ntable$value[which(ntable$id==nid)],")",
               toApp
            )
         }
      }
      return(toRet)
   }
   ##################################

   return(genCypher(
      fid=ntable$id[which(ntable$value==from)],
      usedR=c(),
      onlyR=onlyR
   ))

}
