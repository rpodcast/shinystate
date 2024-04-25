parse_bookmark_id <- function(url) {
  stringr::str_extract(url, "(?<=\\=).*")
}

save_session <- function(df, board_sessions, board_name = "sessions") {
  pins::pin_write(board_sessions, df, board_name)
}

empty_sessions <- function(board_sessions, board_name = "sessions") {
  !board_name %in% pins::pin_list(board_sessions)
}

import_sessions <- function(board_sessions, board_name = "sessions") {
  if (empty_sessions(board_sessions, board_name)) return(NULL)
  pins::pin_read(board_sessions, board_name)
}

create_session_df <- function(url, session_metadata = NULL) {
  id <- parse_bookmark_id(url)
  url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url)
  custom_vars <- c(
    list(id = id, url = url),
    session_metadata
  )

  df <- tibble::tibble(!!!custom_vars)
  return(df)
}

save_interface <- function(id, callback) {
  message("entered save_interface")
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

load_interface <- function(id, callback) {
  message("entered load_interface")
  root_dir <- file.path(shiny::getShinyOption("local_storage_dir"))

  if (is.null(root_dir)) {
    root_dir <- fs::file_temp()
  }
  
  stateDir <- fs::path(root_dir, "shiny_bookmarks", id)
  callback(stateDir)
}

bookmark_fun <- function(state) {
  if (!is.null(shiny::getShinyOption("local_storage_dir"))) {
    state$values$local_storage_dir <- shiny::getShinyOption("local_storage_dir")
  }
}

bookmarked_fun <- function(url, board_sessions, board_name = "sessions", session_metadata = NULL) {
  id <- parse_bookmark_id(url)
  df <- create_session_df(url = url, session_metadata = session_metadata)

  if (!empty_sessions(board_sessions, board_name)) {
    df <- rbind(
      import_sessions(board_sessions, board_name),
      df
    )
  }

  save_session(df, board_sessions, board_name)
  #upload_archive(board_sessions, local_storage_dir, storage_id, id)
}

restore_fun <- function(state) {
  message("entered restore function")
  #cat("Restoring from state bookmarked at", state$values$time, "\n")
  if (!is.null(state$values$local_storage_dir)) {
    shiny::shinyOptions(local_storage_dir = state$values$local_storage_dir)
  }
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
      ns <- session$ns

      # restore session modal
      shiny::observeEvent(input$show_load_modal, {
        shiny::showModal(
          shiny::modalDialog(
            shiny::uiOutput(ns("sessions_list")),
            size = "xl",
            easyClose = TRUE,
            footer = tagList(
              shiny::modalButton("Cancel"),
              shiny::actionButton(
                ns("restore"),
                "Restore"
              )
            )
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
            shiny::checkboxInput(
              ns("save_boolean"),
              "Awesome?",
              value = FALSE
            ),
            shiny::numericInput(
              ns("save_number"),
              "Favorite Number",
              value = 0
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

      # reactive of the above inputs as a named list
      session_metadata <- reactive({
        list(
          name = input$save_name,
          boolean = input$save_boolean,
          number = input$save_number
        )
      })

      # saved sessions table placeholder
      output$saved_sessions_placeholder <- renderUI({
        fluidRow(
          DT::dataTableOutput(ns("saved_sessions_table"))
        )
      })

      # sessions table
      output$saved_sessions_table <- DT::renderDataTable({
        req(session_df())
        DT::datatable(
          session_df(),
          escape = FALSE
        )
      })

      # sessions list
      output$sessions_list <- shiny::renderUI({
        df <- storage$get_sessions()
        shiny::radioButtons(
          ns("restore_id"),
          "Choose session to restore",
          choiceNames = df$id,
          choiceValues = df$url
        )
      })

      # save session
      observeEvent(input$save, ignoreInit = TRUE, {
        storage$add_session_metadata(session_metadata())
        tryCatch(
          {
            if (!isTruthy(input$save_name)) {
              stop("Please specify a bookmark name")
            } else {
              shiny::removeModal()
              storage$snapshot()
              shiny::showNotification(
                "Session successfully saved"
              )
            }
          },
          error = function(e) {
            shiny::showNotification(
              conditionMessage(e),
              type = "error"
            )
          }
        )
        # storage$snapshot(name = input$save_name)
        # shiny::removeModal()
      })

      observeEvent(input$restore, {
        req(input$restore_id)
        storage$restore(input$restore_id)
      })

      shiny::setBookmarkExclude(
        c(
          "show_save_modal",
          "show_load_modal",
          "save_name",
          "save",
          "restore",
          "restore_id",
          "save_number",
          "save_boolean"
        )
      )
    }
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
    sprintf("%d %s %s",
      x,
      ifelse(x == 1, singular, plural),
      dir
    )
  }
  
  ifelse(abs_age == seconds(0), "Now",
    ifelse(abs_age < minutes(1), format_rel("second"),
      ifelse(abs_age < hours(1), format_rel("minute"),
        ifelse(abs_age < hours(6), format_rel("hour"),
          # Less than 24 hours, and during the same calendar day
          ifelse(abs_age < days(1) & abs_day_diff == 0, strftime(t, "%I:%M:%S %p"),
            ifelse(abs_age < days(3), strftime(t, "%a %I:%M:%S %p"),
              strftime(t, "%Y/%m/%d %I:%M:%S %p")
            ))))))
}

