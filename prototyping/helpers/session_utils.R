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
    #timestamp = Sys.time(),
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
  pins::pin_write(
    board = pool, 
    x = dplyr::bind_rows(import_sessions(pool), df),
    name = "sessions"
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

StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    local_storage_dir = NULL,
    bmi_storage = NULL,
    board_sessions = NULL,
    initialize = function(local_storage_dir = NULL) {
      if (is.null(local_storage_dir)) {
        local_storage_dir <- fs::path_temp("shinysessions")
      }
      self$local_storage_dir <- local_storage_dir
      shiny::shinyOptions(local_storage_dir = local_storage_dir)
      shiny::shinyOptions(save.interface = saveInterfaceLocal)
      shiny::shinyOptions(load.interface = loadInterfaceLocal)

      # initialize local pins board for session metadata
      self$board_sessions <- pins::board_folder(local_storage_dir)

      # initialize app checking function for updated session data
      self$bmi_storage <- list(
        pool = self$board_sessions,
        reader = shiny::reactivePoll(
          intervalMillis = 1000,
          session = NULL,
          checkFunc = function() {
            if (empty_sessions(self$board_sessions)) {
              return(NULL)
            } else {
              pins::pin_meta(self$board_sessions, "sessions")$pin_hash
            }
          },
          valueFunc = function() {
            import_sessions(self$board_sessions)
          }
        )
      )
    },
    restore = function(url, session = shiny::getDefaultReactiveDomain()) {
      session$sendCustomMessage("redirect", list(url = url))
    },
    snapshot = function(session_metadata = NULL, session = shiny::getDefaultReactiveDomain()) {
      shiny::shinyOptions(session_metadata = session_metadata)
      session$doBookmark()
    },
    register_metadata = function() {
      set_onbookmarked(
        pool = self$board_sessions
      )()
    }
  ))