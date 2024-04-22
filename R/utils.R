bookmark_fun <- function(state) {
  message_file <- fs::path(state$dir, "message.txt")
  cat(as.character(Sys.time()), file = message_file)
}

bookmarked_fun <- function(url, board, storage_id) {
  url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url)

  df <- tibble::tibble(
    storage_id = storage_id,
    url = url,
    timestamp = Sys.time()
  )

  session_df <- pins::pin_read(board, "sessions")
  pins::pin_write(
    rbind(session_df, df),
    "sessions"
  )
}

restore_fun <- function(state) {
  cat("Restoring from state bookmarked at", state$values$time, "\n")
}

pin_upload_archive <- function(
  board,
  storage_dir,
  storage_id, 
  shiny_session_id
) {
  pin_name <- glue::glue("{storage_id}__{shiny_session_id}")
  pin_title <- glue::glue("{storage_id} {shiny_session_id}")

  bundle_tmp_path <- fs::path_temp(fs::path_ext_set(pin_name, "tar.gz"))
  withr::defer(fs::file_delete(bundle_tmp_path))
  archive::archive_write_dir(bundle_tmp_path, storage_dir)

  pins::pin_upload(
    board = board,
    paths = bundle_tmp_path,
    name = pin_name,
    title = pin_title,
    metadata = list(
      storage_id = storage_id,
      shiny_session_id = shiny_session_id,
      timestamp = Sys.time()
    )
  )
}

pin_download_archive <- function(
  board,
  pin_name,
  download_dir,
  extract = TRUE
) {

  local_path <- pins::pins_download(board = board, name = pin_name)

  if (fs::dir_exists(download_dir)) fs::dir_create(download_dir)

  if (extract) {
    archive::archive_extract(archive = local_path, dir = download_dir)
  } else {
    fs::file_copy(local_path, new_path = fs::path(download_dir, fs::path_ext_set(pin_name, "tar.gz")))
  }
}