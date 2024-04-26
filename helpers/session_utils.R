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

set_onbookmarked <- function() {
  function() {
    onBookmarked(function(url) {
      on_bookmarked(
        url = url,
        thumbnailFunc = thumbnailFunc,
        save_name = input$save_name,
        pool = instance$pool
      )
    })
  }
}