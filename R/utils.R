parse_bookmark_id <- function(url) {
  stringr::str_extract(url, "(?<=\\=).*")
}

gen_session_link <- function(id, url) {
  tags$a(href = url, id)
}

save_session <- function(df, board_sessions, name = "sessions") {
  pins::pin_write(board_sessions, df, name)
}

empty_sessions <- function(board_sessions, name = "sessions") {
  !"sessions" %in% pins::pin_list(board_sessions)
}

import_sessions <- function(board_sessions, name = "sessions") {
  # if (fs::file_exists(fs::path(local_storage_dir, "sessions.csv"))) {
  #   read.csv(fs::path(local_storage_dir, "sessions.csv"))
  # }
  if (empty_sessions(board_sessions, name)) return(NULL)
  pins::pin_read(board_sessions, name)
}

create_session_df <- function(url, storage_id, name = NULL) {
  id <- parse_bookmark_id(url)
  url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url)
  df <- tibble::tibble(
    id = id,
    storage_id = storage_id,
    url = url,
    name = name,
    timestamp = Sys.time()
  )
  return(df)
}

save_interface <- function(
  id,
  callback,
  local_storage_dir = shiny::getShinyOption("local_storage_dir"),
  storage_id = shiny::getShinyOption("storage_id")
) {
    state_dir <- fs::path(local_storage_dir, storage_id, "shiny_bookmarks", id)
    message(state_dir)
    if (!fs::dir_exists(state_dir)) fs::dir_create(state_dir)
    callback(state_dir)
  }

load_interface <- function(
  id,
  callback,
  local_storage_dir = shiny::getShinyOption("local_storage_dir"),
  storage_id = shiny::getShinyOption("storage_id")
) {
  message("entered load_interface")
  state_dir <- fs::path(local_storage_dir, storage_id, "shiny_bookmarks", id)
  callback(state_dir)
}

bookmark_fun <- function(state) {
  message_file <- fs::path(state$dir, "message.txt")
  cat(as.character(Sys.time()), file = message_file)
}

bookmarked_fun <- function(url, storage_id, board_sessions, name = "sessions", local_storage_dir = NULL) {
  message(url)
  id <- parse_bookmark_id(url)
  df <- create_session_df(url, storage_id, name = shiny::getShinyOption("session_name"))
  # url <- sub("^[^?]+", "", url, perl = TRUE)
  # shiny::updateQueryString(url)
  # df <- tibble::tibble(
  #   storage_id = storage_id,
  #   url = url,
  #   id = id,
  #   timestamp = Sys.time()
  # )

  if (!empty_sessions(board_sessions, name)) {
    df <- rbind(
      import_sessions(board_sessions, name),
      df
    )
  }

  save_session(df, board_sessions, name)
  upload_archive(board_sessions, local_storage_dir, storage_id, id)

  # if (fs::file_exists(fs::path(local_storage_dir, "sessions.csv"))) {
  #   existing_df <- read.csv(fs::path(local_storage_dir, "sessions.csv"))
  #   df <- rbind(existing_df, df)
  # }
  # write.csv(df, fs::path(local_storage_dir, "sessions.csv"), row.names = FALSE)

  # check for existing session entries
  # if ("sessions" %in% pins::pin_list(board)) {
  #   existing_df <- pins::pin_read(board, "sessions")
  #   df <- rbind(
  #     existing_df,
  #     df
  #   )
  # }
  # print(df)
  # pins::pin_write(board, df, "sessions")
}

restore_fun <- function(state) {
  cat("Restoring from state bookmarked at", state$values$time, "\n")
}

create_bookmark_bundle <- function(
  local_storage_dir,
  storage_id,
  shiny_session_id
) {
  bundle_tmp_path <- fs::path_temp(fs::path_ext_set(shiny_session_id, "tar.gz"))
  withr::defer(fs::file_delete(bundle_tmp_path))

  archive::archive_write_dir(
    bundle_tmp_path, 
    fs::path(local_storage_dir, "shiny_bookmarks", shiny_session_id)
  )
  return(bundle_tmp_path)
}

upload_archive <- function(
  board_sessions,
  local_storage_dir,
  storage_id, 
  shiny_session_id
) {
  pin_name <- glue::glue("{storage_id}__{shiny_session_id}")
  pin_title <- glue::glue("{storage_id} {shiny_session_id}")

  # bundle_tmp_path <- create_bookmark_bundle(
  #   local_storage_dir,
  #   storage_id,
  #   shiny_session_id
  # )
  bundle_tmp_path <- fs::path_temp(fs::path_ext_set(pin_name, "tar.gz"))
  withr::defer(fs::file_delete(bundle_tmp_path))

  archive::archive_write_dir(
    bundle_tmp_path, 
    fs::path(local_storage_dir, storage_id, "shiny_bookmarks", shiny_session_id)
  )

  pins::pin_upload(
    board = board_sessions,
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

download_archive <- function(
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

bookmark_modal_save_ui <- function(id) {
  ns <- shiny::NS(id)

  tagList(
    shiny::actionButton(ns("show_save_modal"), "Save session")
  )
}

bookmark_modal_load_ui <- function(id) {
  ns <- shiny::NS(id)

  tagList(
    shiny::actionButton(ns("show_load_modal"), "Restore session")
  )
}

bookmark_mod <- function(id, storage) {
  shiny::moduleServer(
    id,
    function(input, output, session) {
      # TODO: Add more code for restore
      ns <- session$ns
      shiny::setBookmarkExclude(c("save_name", "save", "show_save_modal", "show_load_modal"))
      # restore session modal
      shiny::observeEvent(input$show_load_modal, {
        shiny::showModal(
          shiny::modalDialog(
            shiny::uiOutput(ns("sessions_list")),
            #shiny::tableOutput(ns("sessions_table")),
            size = "xl"
          )
        )
      })

      # save session modal
      shiny::observeEvent(input$show_save_modal, {
        shiny::showModal(
          shiny::modalDialog(
            shiny::textInput(
              ns("save_name"),
              "Give this session a name"
            ),
            easyClose = TRUE,
            size = "m",
            footer = tagList(
              shiny::modalButton("Cancel"),
              shiny::actionButton(
                ns("save"),
                "Save"
              )
            )
          )
        )
      })

      # sessions table
      output$sessions_table <- shiny::renderTable({
        storage$get_sessions()
      })

      # sessions list
      output$sessions_list <- shiny::renderUI({
        df <- storage$get_sessions()
        tagList(
          purrr::map2(df$id, df$url, ~{
            gen_session_link(id = .x, url = .y)
          })
        )
      })

      # save session
      observeEvent(input$save, {
        storage$snapshot(name = input$save_name)
        shiny::removeModal()
      })
    }
  )
}
