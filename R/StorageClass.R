StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    storage_id = NULL,
    board_sessions = NULL,
    storage_dir = NULL,
    session_dirname = NULL,
    initialize = function(storage_id, session_dirname = "shinysessions") {
      # create storage directory and pins board
      storage_dir <- fs::path_temp(session_dirname)
      fs::dir_create(storage_dir, storage_id, "shiny_bookmarks")
      board_sessions <- pins::board_folder(storage_dir)
      self$board_sessions <- board_sessions
      self$storage_id <- storage_id
      self$storage_dir <- storage_dir

      # override shiny options for bookmark state
      shiny::shinyOptions(storage_dir = storage_dir)
      shiny::shinyOptions(storage_id = storage_id)

      shiny::shinyOptions(save.interface = function(id, callback) {
        state_dir <- fs::path(
          shiny::getShinyOption("storage_dir"),
          shiny::getShinyOption("storage_id"),
          "shiny_bookmarks",
          id
        )
        if (!fs::dir_exists(state_dir)) fs::dir_create(state_dir)
        callback(state_dir)
      })

      shiny::shinyOptions(load.interface = function(id, callback) {
        state_dir <- fs::path(
          shiny::getShinyOption("storage_dir"),
          shiny::getShinyOption("storage_id"),
          "shiny_bookmarks",
          id
        )
        callback(state_dir)
      })
    },
    greet = function() {
      message(glue::glue("Hello, your storage directory is {self$storage_dir}"))
    },
    bookmark_init = function() {
      shiny::onBookmark(bookmark_fun)
      shiny::onRestore(restore_fun)
      shiny::onBookmarked(
        function(url) {
          bookmarked_fun(
            url = url,
            board = self$board_sessions
          )
        }
      )
      shiny::enableBookmarking("server")
    },
    sessions_rv = function() {
      pins::pin_reactive_read(self$board_sessions, "sessions", interval = 1000)
    }
  )
)