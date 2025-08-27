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
  sub(".*\\?_state_id_=([a-zA-Z0-9]+).*", "\\1", url)
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

import_sessions <- function(board_sessions, name = "sessions") {
  if (empty_sessions(board_sessions)) {
    return(NULL)
  }
  pins::pin_read(board_sessions, name = name)
}

delete_session <- function(url, board) {
  session_url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny_bookmark_id <- session_id_from_url(url)
  current_sessions_df <- import_sessions(board)
  if (!session_url %in% current_sessions_df$url) {
    message("selected session not in sessions data frame. Nothing to do")
  } else {
    new_sessions_df <- current_sessions_df[
      which(current_sessions_df$url != !!session_url),
      ,
      drop = FALSE
    ]
    # remove bookmark bundle from pins if available
    if (shiny_bookmark_id %in% pins::pin_list(board)) {
      pins::pin_delete(
        board = board,
        names = shiny_bookmark_id
      )
    }

    # either remove all of sessions metadata or re-upload new version
    if (nrow(new_sessions_df) < 1) {
      pins::pin_delete(
        board = board,
        names = "sessions"
      )
    } else {
      upload_sessions(
        new_sessions_df,
        board = board
      )
    }
  }
}

upload_sessions <- function(
  sessions_df,
  board,
  name = "sessions",
  quiet = TRUE
) {
  if (quiet) {
    suppressMessages(
      save_session(sessions_df, board, name)
    )
  } else {
    save_session(sessions_df, board, name)
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
  # TODO: Verify that updateQueryString is still necessary
  #url <- sub("^[^?]+", "", url, perl = TRUE)
  #shiny::updateQueryString(url)

  session_metadata <- c(
    url = sub("^[^?]+", "", url, perl = TRUE),
    session_metadata
  )

  df <- tibble::tibble(!!!session_metadata)
  if (!is.null(session_metadata)) {
    shiny::shinyOptions(session_metadata = NULL)
  }
  return(df)
}

on_bookmarked <- function(url, session_metadata, board) {
  #url_for_sessions <- sub("^[^?]+", "", url, perl = TRUE)
  #shiny::updateQueryString(url_for_sessions)

  #df <- create_session_data(url_for_sessions, session_metadata)
  df <- create_session_data(url, session_metadata)
  sessions_df <- bind_rows_base(import_sessions(board), df)
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
    shiny::onBookmarked(function(url) {
      on_bookmarked(
        url = url,
        session_metadata = shiny::getShinyOption("session_metadata"),
        board = board
      )
    })
  }
}

save_session <- function(sessions_df, board_sessions, name = "sessions") {
  pins::pin_write(board_sessions, sessions_df, name = name)
}

create_bookmark_bundle <- function(local_storage_dir, url) {
  shiny_bookmark_id <- session_id_from_url(url)
  bundle_tmp_path <- fs::path_temp(fs::path_ext_set(
    shiny_bookmark_id,
    "tar.gz"
  ))
  archive::archive_write_dir(
    bundle_tmp_path,
    fs::path(local_storage_dir, "shiny_bookmarks", shiny_bookmark_id)
  )
  return(bundle_tmp_path)
}

upload_bookmark_bundle <- function(
  local_storage_dir,
  url,
  board,
  quiet = TRUE
) {
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

download_bookmark_bundle <- function(
  local_storage_dir,
  shiny_bookmark_id,
  board
) {
  bundle_tmp_path <- pins::pin_download(
    board = board,
    name = shiny_bookmark_id
  )
  bookmark_local_path <- fs::path(
    local_storage_dir,
    "shiny_bookmarks",
    shiny_bookmark_id
  )
  if (!fs::dir_exists(bookmark_local_path)) {
    fs::dir_create(bookmark_local_path)
  }
  archive::archive_extract(
    archive = bundle_tmp_path,
    dir = fs::path(local_storage_dir, "shiny_bookmarks", shiny_bookmark_id)
  )
}

bind_rows_base <- function(..., .id = NULL) {
  dfs <- list(...)

  # Remove NULL data frames
  dfs <- dfs[!sapply(dfs, is.null)]

  if (length(dfs) == 0) {
    return(data.frame())
  }

  if (length(dfs) == 1) {
    return(dfs[[1]])
  }

  # Get all unique column names
  all_cols <- unique(unlist(lapply(dfs, names)))

  # Add missing columns to each data frame
  dfs <- lapply(dfs, function(df) {
    missing_cols <- setdiff(all_cols, names(df))
    if (length(missing_cols) > 0) {
      # Add missing columns as NA with appropriate type
      for (col in missing_cols) {
        df[[col]] <- NA
      }
    }
    # Reorder columns to match all_cols
    df[all_cols]
  })

  # Now rbind will work since all data frames have same columns
  result <- do.call(rbind, dfs)
  row.names(result) <- NULL

  return(result)
}
