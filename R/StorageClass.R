StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    board_sessions = NULL,
    board_name = "sessions",
    local_storage_dir = NULL,
    session_metadata = NULL,
    triggers = shiny::reactiveValues(session = 0),
    initialize = function(
      board_sessions = NULL,
      local_storage_dir = NULL) {
      # create storage directory and pins board
      if (is.null(local_storage_dir)) local_storage_dir <- fs::path_temp("shinysessions")
      if (is.null(board_sessions)) board_sessions <- pins::board_temp()
      self$board_sessions <- board_sessions
      #self$board_name <- board_name
      self$local_storage_dir <- local_storage_dir

      # override shiny options for bookmark state
      shiny::shinyOptions(local_storage_dir = local_storage_dir)
      shiny::shinyOptions(save.interface = save_interface)
      shiny::shinyOptions(load.interface = load_interface)
    },
    greet = function() {
      message(glue::glue("Hello, your storage directory is {self$storage_dir}"))
    },
    bookmark_init = function() {
      #fs::dir_create(self$local_storage_dir, storage_id, "shiny_bookmarks")
      
      # override shiny options for bookmark state
      #shiny::shinyOptions(local_storage_dir = self$local_storage_dir)
      # shiny::shinyOptions(storage_id = storage_id)
      shiny::shinyOptions(save.interface = save_interface)
      shiny::shinyOptions(load.interface = load_interface)
      
      shiny::onBookmark(bookmark_fun)
      shiny::onRestore(restore_fun)
      shiny::onBookmarked(
        function(url) {
          bookmarked_fun(
            url = url,
            board = self$board_sessions,
            session_metadata = self$session_metadata
          )
        }
      )
      shiny::enableBookmarking("server")
    },
    trigger_session = function() {
      self$triggers$session <- self$triggers$session + 1
    },
    get_sessions = function() {
      self$triggers$session
      import_sessions(self$board_sessions)
    },
    add_session_metadata = function(session_metadata) {
      self$session_metadata <- session_metadata
    },
    snapshot = function(session = shiny::getDefaultReactiveDomain()) {
      session$doBookmark()
      self$trigger_session()
    },
    restore = function(url, session = shiny::getDefaultReactiveDomain()) {
      session$sendCustomMessage("redirect", list(url = url))
    }
  )
)