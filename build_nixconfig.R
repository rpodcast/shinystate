#https://gist.github.com/b-rodrigues/d427703e76a112847616c864551d96a1
library(rix)

rix(
  date = "2025-04-16",
  #r_ver = "4.4.2",
  project_path = getwd(),
  r_pkgs = c(
    "archive",
    "cli",
    "DBI",
    "devtools",
    "dplyr",
    "DT",
    "fs",
    "htmltools",
    "lubridate",
    "pins",
    "R6",
    "RSQLite",
    "pool",
    "shiny",
    "tibble",
    "rlang",
    #"shinytest2",
    "testthat",
    "withr",
    "s3fs",
    "sodium",
    "shinyvalidate",
    "chromote",
    "zip",
    "ggplot2",
    "roxy.shinylive",
    "rhub",
    "golem",
    "rhino",
    "attachment"
  ),
  ide = "none",
  system_pkgs = c("air-formatter", "qpdf", "git"),
  overwrite = TRUE
)
