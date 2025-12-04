#' Add shinystate dependency
#'
#' Include shinystate dependencies in your Shiny application UI
#'
#' @importFrom htmltools htmlDependency
#' @export
#' @examples
#' ## Only run examples in interactive R sessions
#' if (interactive()) {
#'
#' library(shiny)
#' library(shinystate)
#'
#' storage <- StorageClass$new()
#'
#' ui <- function(request) {
#'   fluidPage(
#'     use_shinystate(),
#'     actionButton("bookmark", "Bookmark"),
#'     actionButton("restore", "Restore Last Bookmark")
#'   )
#' }
#' }
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

import_sessions <- function(board_sessions) {
  existing_pins <- pins::pin_list(board_sessions)

  if (length(existing_pins) == 0) {
    return(NULL)
  }

  # BACKWARD COMPATIBILITY: Migrate legacy "sessions" pin from v0.1.0
  if ("sessions" %in% existing_pins) {
    migrate_legacy_sessions(board_sessions)
    # Refresh pin list after migration
    existing_pins <- pins::pin_list(board_sessions)
  }

  # Read session metadata from each bookmark pin's metadata field
  rows <- lapply(existing_pins, function(pin_name) {
    tryCatch(
      {
        meta <- pins::pin_meta(board_sessions, pin_name)
        user_meta <- meta$user

        # Check if this is a bookmark pin (has shiny_bookmark_id in metadata)
        if (is.null(user_meta$shiny_bookmark_id)) {
          return(NULL)
        }

        # Build row from user metadata (only scalar values)
        row_data <- lapply(user_meta, function(val) {
          if (length(val) == 1L) val else NA
        })

        as.data.frame(row_data, stringsAsFactors = FALSE)
      },
      error = function(e) NULL
    )
  })

  # Remove NULLs
  rows <- Filter(Negate(is.null), rows)

  if (length(rows) == 0) {
    return(NULL)
  }

  result <- bind_rows_base(rows)
  
  # Sort by timestamp in descending order (newest last)
  if (!is.null(result) && "timestamp" %in% names(result)) {
    result <- result[order(result$timestamp, decreasing = FALSE), ]
    rownames(result) <- NULL
  }
  
  result
}

delete_session <- function(url, board) {
  shiny_bookmark_id <- session_id_from_url(url)

  # Delete the bookmark pin (metadata is stored in pin, no separate sessions pin)
  if (shiny_bookmark_id %in% pins::pin_list(board)) {
    pins::pin_delete(
      board = board,
      names = shiny_bookmark_id
    )
  } else {
    message("selected session not found. Nothing to do")
  }
}

validate_session_metadata <- function(session_metadata) {
  if (is.null(session_metadata)) {
    return(TRUE)
  }

  if (!is.list(session_metadata) || is.null(names(session_metadata))) {
    stop("session_metadata must be a named list", call. = FALSE)
  }

  for (nm in names(session_metadata)) {
    val <- session_metadata[[nm]]
    if (length(val) != 1L) {
      stop(
        sprintf(
          "session_metadata element '%s' must be single-length (got length %d)",
          nm,
          length(val)
        ),
        call. = FALSE
      )
    }
  }

  TRUE
}

migrate_legacy_sessions <- function(board_sessions) {
  # Migration function for v0.1.0 and below to new metadata format.
  # Old version stored all session metadata in a single "sessions" pin
  # New version stores metadata in each bookmark pin's metadata field

  message("Migrating legacy session metadata to new format...")

  legacy_sessions <- tryCatch(
    pins::pin_read(board_sessions, "sessions"),
    error = function(e) {
      warning("Failed to read legacy sessions pin: ", e$message)
      return(NULL)
    }
  )

  if (is.null(legacy_sessions) || nrow(legacy_sessions) == 0) {
    # Empty legacy pin, just delete it
    tryCatch(
      pins::pin_delete(board_sessions, "sessions"),
      error = function(e) warning("Failed to delete empty legacy sessions pin: ", e$message)
    )
    return(invisible(NULL))
  }

  # Get list of existing bookmark pins
  existing_pins <- pins::pin_list(board_sessions)
  migrated_count <- 0
  failed_count <- 0

  for (i in seq_len(nrow(legacy_sessions))) {
    session_row <- legacy_sessions[i, , drop = FALSE]

    # Extract bookmark ID from URL
    bookmark_id <- session_id_from_url(session_row$url)

    # Check if bookmark bundle still exists
    if (!bookmark_id %in% existing_pins) {
      message("  Skipping session ", bookmark_id, " (bookmark bundle not found)")
      failed_count <- failed_count + 1
      next
    }

    # Read existing bookmark metadata
    existing_meta <- tryCatch(
      pins::pin_meta(board_sessions, bookmark_id),
      error = function(e) {
        warning("Failed to read metadata for bookmark ", bookmark_id, ": ", e$message)
        return(NULL)
      }
    )

    if (is.null(existing_meta)) {
      failed_count <- failed_count + 1
      next
    }

    # Check if already migrated (has url in metadata)
    if (!is.null(existing_meta$user$url)) {
      message("  Skipping session ", bookmark_id, " (already migrated)")
      next
    }

    # Build new metadata combining old user metadata with session data
    # Preserve the original timestamp from the pin metadata
    original_timestamp <- existing_meta$user$timestamp
    if (is.null(original_timestamp)) {
      # If no timestamp exists, use current time
      original_timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    } else if (inherits(original_timestamp, "POSIXct")) {
      # Convert POSIXct to ISO 8601 string if needed
      original_timestamp <- format(original_timestamp, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    }
    
    new_user_meta <- list(
      shiny_bookmark_id = bookmark_id,
      timestamp = original_timestamp,
      url = sub("^[^?]+", "", session_row$url, perl = TRUE)
    )

    # Add any additional columns from legacy session data
    extra_cols <- setdiff(names(session_row), "url")
    for (col in extra_cols) {
      val <- session_row[[col]]
      if (length(val) == 1L) {
        new_user_meta[[col]] <- val
      }
    }

    # Update the bookmark pin with new metadata
    # We need to re-upload with updated metadata
    tryCatch(
      {
        # Download the existing bundle to a temp location
        bundle_path <- pins::pin_download(board_sessions, bookmark_id)

        # Copy to temp file since deleting pin will invalidate the path
        temp_bundle <- fs::path_temp(paste0(bookmark_id, ".tar.gz"))
        fs::file_copy(bundle_path, temp_bundle, overwrite = TRUE)

        # Delete the old pin to avoid version conflict
        suppressMessages(
          pins::pin_delete(board_sessions, bookmark_id)
        )

        # Re-upload with new metadata
        suppressMessages(
          pins::pin_upload(
            board = board_sessions,
            paths = temp_bundle,
            name = bookmark_id,
            title = bookmark_id,
            metadata = new_user_meta
          )
        )

        # Clean up temp file
        unlink(temp_bundle)

        migrated_count <- migrated_count + 1
      },
      error = function(e) {
        warning("Failed to migrate session ", bookmark_id, ": ", e$message)
        failed_count <- failed_count + 1
      }
    )
  }

  # Delete legacy sessions pin after migration
  tryCatch(
    {
      pins::pin_delete(board_sessions, "sessions")
      message("Migration complete: ", migrated_count, " sessions migrated",
              if (failed_count > 0) paste0(", ", failed_count, " failed") else "")
    },
    error = function(e) {
      warning("Failed to delete legacy sessions pin: ", e$message)
    }
  )

  invisible(NULL)
}

on_bookmarked <- function(url, session_metadata, board) {
  validate_session_metadata(session_metadata)

  # Upload bundle with session metadata stored in pin metadata
  upload_bookmark_bundle(
    local_storage_dir = shiny::getShinyOption("local_storage_dir"),
    url = url,
    board = board,
    session_metadata = session_metadata
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
  session_metadata = NULL,
  quiet = TRUE
) {
  pin_name <- session_id_from_url(url)
  pin_title <- pin_name

  bundle_archive <- create_bookmark_bundle(local_storage_dir, url)

  # Build metadata: standard fields + user-supplied session metadata
  meta <- list(
    shiny_bookmark_id = pin_name,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    url = sub("^[^?]+", "", url, perl = TRUE)
  )

  if (!is.null(session_metadata)) {
    meta <- c(meta, session_metadata)
  }

  if (quiet) {
    suppressMessages(
      pins::pin_upload(
        board = board,
        paths = bundle_archive,
        name = pin_name,
        title = pin_title,
        metadata = meta
      )
    )
  } else {
    pins::pin_upload(
      board = board,
      paths = bundle_archive,
      name = pin_name,
      title = pin_title,
      metadata = meta
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

  # Handle case where a single list of data frames is passed
  if (length(dfs) == 1 && is.list(dfs[[1]]) && !is.data.frame(dfs[[1]])) {
    dfs <- dfs[[1]]
  }

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
