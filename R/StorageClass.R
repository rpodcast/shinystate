StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    storage_id = NULL,
    board_sessions = NULL,
    storage_dir = NULL,
    session_dirname = NULL,
    triggers = shiny::reactiveValues(session = 0),
    initialize = function(session_dirname = "shinysessions", storage_dir = NULL) {
      # create storage directory and pins board
      if (is.null(storage_dir)) storage_dir <- fs::path_temp(session_dirname)
      board_sessions <- pins::board_folder(storage_dir)
      self$board_sessions <- board_sessions
      self$storage_dir <- storage_dir
    },
    greet = function() {
      message(glue::glue("Hello, your storage directory is {self$storage_dir}"))
    },
    bookmark_init = function(storage_id) {
      self$storage_id <- storage_id
      fs::dir_create(self$storage_dir, storage_id, "shiny_bookmarks")
      
      # override shiny options for bookmark state
      shiny::shinyOptions(storage_dir = self$storage_dir)
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

      shiny::onBookmark(bookmark_fun)
      shiny::onRestore(restore_fun)
      shiny::onBookmarked(
        function(url) {
          bookmarked_fun(
            url = url,
            board = self$board_sessions,
            storage_id = storage_id,
            storage_dir = self$storage_dir
          )
        }
      )
      shiny::enableBookmarking("server")
    },
    trigger_session = function() {
      self$triggers$session <- self$triggers$session + 1
    },
    get_sessions = function() {
      if (fs::file_exists(fs::path(self$storage_dir, "sessions.csv"))) {
        read.csv(fs::path(self$storage_dir, "sessions.csv"))
      }
      # if ("sessions" %in% pins::pin_list(self$board_sessions)) {
      #   pins::pin_read(self$board_sessions, "sessions")
      # }
    }
    # sessions_rv = function() {
    #   if ("sessions" %in% pins::pin_list(self$board_sessions)) {
    #     pins::pin_reactive_read(self$board_sessions, "sessions", interval = 1000)
    #   }
    # }
  )
)