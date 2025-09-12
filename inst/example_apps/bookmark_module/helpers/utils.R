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

  Reduce(
    function(memo, expr) {
      expr(!!memo %>% !!expr)
    },
    tail(exprs, -1),
    exprs[[1]]
  )
}

friendly_time <- function(t) {
  t <- round_date(t, "seconds")
  now <- round_date(Sys.time(), "seconds")

  abs_day_diff <- abs(day(now) - day(t))
  age <- now - t

  abs_age <- abs(age)
  future <- age != abs_age
  dir <- ifelse(future, "from now", "ago")

  format_rel <- function(singular, plural = paste0(singular, "s")) {
    x <- as.integer(round(time_length(abs_age, singular)))
    sprintf("%d %s %s", x, ifelse(x == 1, singular, plural), dir)
  }

  ifelse(
    abs_age == seconds(0),
    "Now",
    ifelse(
      abs_age < minutes(1),
      format_rel("second"),
      ifelse(
        abs_age < hours(1),
        format_rel("minute"),
        ifelse(
          abs_age < hours(6),
          format_rel("hour"),
          # Less than 24 hours, and during the same calendar day
          ifelse(
            abs_age < days(1) & abs_day_diff == 0,
            strftime(t, "%I:%M:%S %p"),
            ifelse(
              abs_age < days(3),
              strftime(t, "%a %I:%M:%S %p"),
              strftime(t, "%Y/%m/%d %I:%M:%S %p")
            )
          )
        )
      )
    )
  )
}
