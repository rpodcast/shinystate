StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    storage_id = NULL,
    board_sessions = NULL,
    local_storage_dir = NULL,
    storage_dir = NULL,
    triggers = shiny::reactiveValues(session = 0),
    initialize = function(
      board_sessions = NULL,
      local_storage_dir = NULL) {
      # create storage directory and pins board
      if (is.null(local_storage_dir)) local_storage_dir <- fs::path_temp("shinysessions")
      if (is.null(board_sessions)) board_sessions <- pins::board_temp()
      self$board_sessions <- board_sessions
      self$local_storage_dir <- local_storage_dir
    },
    greet = function() {
      message(glue::glue("Hello, your storage directory is {self$storage_dir}"))
    },
    bookmark_init = function(storage_id) {
      self$storage_id <- storage_id
      fs::dir_create(self$local_storage_dir, storage_id, "shiny_bookmarks")
      
      # override shiny options for bookmark state
      shiny::shinyOptions(local_storage_dir = self$local_storage_dir)
      shiny::shinyOptions(storage_id = storage_id)
      shiny::shinyOptions(save.interface = save_interface)
      shiny::shinyOptions(load.interface = load_interface)
      shiny::onBookmark(bookmark_fun)
      shiny::onRestore(restore_fun)
      shiny::onBookmarked(
        function(url) {
          bookmarked_fun(
            url = url,
            storage_id = storage_id,
            board = self$board_sessions,
            local_storage_dir = self$local_storage_dir
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
    snapshot = function(name, session = shiny::getDefaultReactiveDomain()) {
      shiny::shinyOptions(session_name = name)
      session$doBookmark()
      self$trigger_session()
    }
  )
)