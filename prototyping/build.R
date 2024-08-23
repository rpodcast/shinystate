library(rix)
rix(
  r_ver = "latest",
  r_pkgs = c("shiny", "fs", "languageserver", "pins", "archive", "s3fs", "DT", "DBI", "RSQLite", "lubridate", "pool", "dplyr", "dbplyr", "devtools", "testthat", "arrow", "Microsoft365R", "paws_storage", "sodium", "zip", "AzureStor",  "shinytest2", "chromote", "shinyvalidate"),
  system_pkgs = NULL,
  git_pkgs = NULL,
  ide = "radian",
  project_path = ".",
  overwrite = TRUE
)
