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

on_bookmarked <- function(url, thumbnailFunc, save_name, pool, session = shiny::getDefaultReactiveDomain()) {
  url <- sub("^[^?]+", "", url, perl = TRUE)
  shiny::updateQueryString(url)
  
  thumbnail <- if (!is.null(thumbnailFunc)) {
    pngfile <- plotPNG(function() {
      try(thumbnailFunc(), silent = TRUE)
    }, height = 300)
    on.exit(unlink(pngfile), add = TRUE)
    base64enc::dataURI(mime = "image/png", file = pngfile)
  } else {
    NA_character_
  }
  
  df <- data.frame(
    timestamp = Sys.time(),
    url = url,
    label = save_name,
    author = if (!is.null(session$user))
      session$user
    else
      paste("Anonymous @", session$request$REMOTE_ADDR),
    thumbnail = thumbnail,
    stringsAsFactors = FALSE
  )
  
  dbWriteTable(pool, "bookmarks", df, append = TRUE)
}

set_onbookmarked <- function(url, thumbnailFunc, save_name, pool) {
  function() {
    onBookmarked(function(url) {
      on_bookmarked(
        url = url,
        thumbnailFunc = thumbnailFunc,
        save_name = save_name,
        pool = pool
      )
    })
  }
}

StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    local_storage_dir = NULL,
    bmi_storage = NULL,
    initialize = function(local_storage_dir = NULL) {
      if (is.null(local_storage_dir)) {
        local_storage_dir <- fs::path_temp("shinysessions")
      }
      self$local_storage_dir <- local_storage_dir
      shiny::shinyOptions(local_storage_dir = local_storage_dir)
      shiny::shinyOptions(save.interface = saveInterfaceLocal)
      shiny::shinyOptions(load.interface = loadInterfaceLocal)
    },
    bookmark_init = function() {
      filepath <- file.path(self$local_storage_dir, "bookmarks.sqlite")

      if (!dir.exists(dirname(filepath))) {
        dir.create(dirname(filepath))
      }
      
      bookmark_pool <- local({
        pool <- dbPool(SQLite(), dbname = filepath)
        onStop(function() {
          poolClose(pool)
        })
        pool
      })
      
      bookmarks <- reactivePoll(1000, NULL,
        function() {
          file.info(filepath)$mtime
        },
        function() {
          bookmark_pool %>% tbl("bookmarks") %>%
            arrange(desc(timestamp)) %>%
            collect() %>%
            mutate(
              timestamp = friendly_time(as.POSIXct(timestamp, origin = "1970-01-01")),
              link = sprintf("<a href=\"%s\">%s</a>",
                htmltools::htmlEscape(url, TRUE),
                htmltools::htmlEscape(label, TRUE))
            )
        }
      )
      
      self$bmi_storage <- list(
        pool = bookmark_pool,
        reader = bookmarks
      )
    },
    restore = function(url, session = shiny::getDefaultReactiveDomain()) {
      session$sendCustomMessage("redirect", list(url = url))
    },
    snapshot = function(session = shiny::getDefaultReactiveDomain()) {
      session$doBookmark()
    }
  ))