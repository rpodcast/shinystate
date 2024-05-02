#' Dependencies
#' 
#' Include shinystate dependencies in your Shiny UI
#' 
#' @importFrom htmltools htmlDependency
#' @export
use_shinystate <- function() {
  htmlDependency(
    "shinystate",
    version = utils::packageVersion("shinystate"),
    package = "shinystate",
    src = "js",
    script = "redirect.js"
  )
}

saveInterfaceLocal <- function(id, callback) {
  root_dir <- file.path(shiny::getShinyOption("local_storage_dir"))

  if (is.null(root_dir)) {
    root_dir <- fs::file_temp()
  }
  
  stateDir <- fs::path(root_dir, "shiny_bookmarks", id)
  
  if (!fs::dir_exists(stateDir)) {
    fs::dir_create(stateDir)
  }
  
  callback(stateDir)
}

loadInterfaceLocal <- function(id, callback) {
  root_dir <- file.path(shiny::getShinyOption("local_storage_dir"))

  if (is.null(root_dir)) {
    root_dir <- fs::file_temp()
  }
  
  stateDir <- fs::path(root_dir, "shiny_bookmarks", id)
  callback(stateDir)
}

set_bookmark_options <- function(local_storage_dir = NULL) {
  if (is.null(local_storage_dir)) {
    local_storage_dir <- fs::path_temp("shinysessions")
  }
  shiny::shinyOptions(local_storage_dir = local_storage_dir)
  shiny::shinyOptions(save.interface = saveInterfaceLocal)
  shiny::shinyOptions(load.interface = loadInterfaceLocal)
}

import_sessions <- function(board_sessions) {
  if (empty_sessions(board_sessions)) return(NULL)
  pins::pin_read(board_sessions, name = "sessions")
}

empty_sessions <- function(board_sessions) {
  !"sessions" %in% pins::pin_list(board_sessions)
}

create_session_data <- function(url, session_metadata = NULL) {
  url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url)

  session_metadata <- c(
    url = url,
    session_metadata
  )

  df <- tibble::tibble(!!!session_metadata)
  if (!is.null(session_metadata)) shiny::shinyOptions(session_metadata = NULL)
  return(df)
}

on_bookmarked <- function(url, session_metadata, pool) {
  url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url)

  df <- create_session_data(url, session_metadata)
  suppressMessages(
    pins::pin_write(
      board = pool, 
      x = dplyr::bind_rows(import_sessions(pool), df),
      name = "sessions"
    )
  )
}

set_onbookmarked <- function(pool) {
  function() {
    onBookmarked(function(url) {
      on_bookmarked(
        url = url,
        session_metadata = shiny::getShinyOption("session_metadata"),
        pool = pool
      )
    })
  }
}

save_session <- function(sessions_df, board_sessions) {
  pins::pin_write(board_sessions, sessions_df, name = "sessions")
}
