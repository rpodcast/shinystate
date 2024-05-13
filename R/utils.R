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

session_id_from_url <- function(url) {
  stringr::str_extract(url, "(?<=\\=).*")
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

upload_sessions <- function(sessions_df, board, name = "sessions", quiet = TRUE) {
  if (quiet) {
    suppressMessages(
      pins::pin_write(
        board = board,
        x = sessions_df,
        name = name
      )
    )
  } else {
    pins::pin_write(
      board = board,
      x = sessions_df,
      name = name
    )
  }
}

empty_sessions <- function(board_sessions) {
  existing_pins <- pins::pin_list(board_sessions)
  if (length(existing_pins) > 0) {
    return(!"sessions" %in% pins::pin_list(board_sessions))
  } else {
    return(TRUE)
  }
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

on_bookmarked <- function(url, session_metadata, board) {
  url_for_sessions <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url_for_sessions)

  df <- create_session_data(url_for_sessions, session_metadata)
  sessions_df <- dplyr::bind_rows(import_sessions(board), df)
  upload_sessions(
    sessions_df,
    board = board
  )
  upload_bookmark_bundle(
    local_storage_dir = shiny::getShinyOption("local_storage_dir"),
    url = url,
    board = board
  )
}

set_onbookmarked <- function(board) {
  function() {
    onBookmarked(function(url) {
      on_bookmarked(
        url = url,
        session_metadata = shiny::getShinyOption("session_metadata"),
        board = board
      )
    })
  }
}

save_session <- function(sessions_df, board_sessions) {
  pins::pin_write(board_sessions, sessions_df, name = "sessions")
}

create_bookmark_bundle <- function(local_storage_dir, url) {
  shiny_bookmark_id <- session_id_from_url(url)
  bundle_tmp_path <- fs::path_temp(fs::path_ext_set(shiny_bookmark_id, "tar.gz"))
  archive::archive_write_dir(
    bundle_tmp_path,
    fs::path(local_storage_dir, "shiny_bookmarks", shiny_bookmark_id)
  )
  return(bundle_tmp_path)
}

upload_bookmark_bundle <- function(local_storage_dir, url, board, quiet = TRUE) {
  pin_name <- session_id_from_url(url)
  pin_title <- pin_name

  bundle_archive <- create_bookmark_bundle(local_storage_dir, url)

  if (quiet) {
    suppressMessages(
      pins::pin_upload(
        board = board,
        paths = bundle_archive,
        name = pin_name,
        title = pin_title,
        metadata = list(
          shiny_bookmark_id = pin_name,
          timestamp = Sys.time()
        )
      )
    )
  } else {
    pins::pin_upload(
      board = board,
      paths = bundle_archive,
      name = pin_name,
      title = pin_title,
      metadata = list(
        shiny_bookmark_id = pin_name,
        timestamp = Sys.time()
      )
    )
  }
  unlink(bundle_archive)
}

download_bookmark_bundle <- function(local_storage_dir, shiny_bookmark_id, board) {
  bundle_tmp_path <- pins::pin_download(
    board = board,
    name = shiny_bookmark_id
  )
  bookmark_local_path <- fs::path(local_storage_dir, "shiny_bookmarks", shiny_bookmark_id)
  if (!fs::dir_exists(bookmark_local_path)) fs::dir_create(bookmark_local_path)
  archive::archive_extract(
    archive = bundle_tmp_path,
    dir = fs::path(local_storage_dir, "shiny_bookmarks", shiny_bookmark_id)
  )
}