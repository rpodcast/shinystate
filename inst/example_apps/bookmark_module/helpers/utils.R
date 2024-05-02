library(rlang)

#' Evaluate an expression in a fresh environment
#'
#' Like eval_tidy, but with different defaults. By default, instead of running
#' in the caller's environment, it runs in a fresh environment.
#' @export
eval_clean <- function(expr, env = list(), enclos = clean_env()) {
  eval_tidy(expr, env, enclos)
}

#' Create a clean environment
#' 
#' Creates a new environment whose parent is the global environment.
#' @export
clean_env <- function() {
  new.env(parent = globalenv())
}

#' Join calls into a pipeline
expr_pipeline <- function(..., .list = list(...)) {
  exprs <- .list
  if (length(exprs) == 0) {
    return(NULL)
  }

  exprs <- rlang::flatten(exprs)

  exprs <- Filter(Negate(is.null), exprs)
  
  if (length(exprs) == 0) {
    return(NULL)
  }
  
  Reduce(function(memo, expr) {
    expr(!!memo %>% !!expr)
  }, tail(exprs, -1), exprs[[1]])
}
