#' StorageClass R6 class
#' 
#' @description
#' This class provides a set of methods to create and manage Shiny bookmarkable
#' state files.
#' 
#' @field local_storage_dir file path to use for storing bookmarkable state
#'   files. If not specified, a temporary directory on the host system
#'   will be used.
#' @field board_sessions Optional pre-created board object created with the
#'   pins package. If missing, a folder-based pin board will be created using
#'   the `local_storage_dir` path.
#' @export
StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    #' @description
    #' Initialize a `StorageClass` object
    #' 
    #' @param local_storage_dir file path to use for storing bookmarkable state
    #'   files. If not specified, a temporary directory on the host system
    #'   will be used.
    #' @param board_sessions Optional pre-created board object created with the
    #'   pins package. If missing, a folder-based pin board will be created using
    #'   the `local_storage_dir` path.
    #' @return An object with class `StorageClass` and the methods described
    #'   in this documentation
    #' 
    #' @examples
    #' \dontrun{
    #' # beginning of application
    #' library(shiny)
    #' library(shinystate)
    #' 
    #' # Create a StorageClass object with default settings
    #' storage <- StorageClass$new()
    #' 
    #' # Use a local directory called "sessions" to store files
    #' storage <- StorageClass$new(local_storage_dir = "sessions")
    #' 
    #' # use a custom pins board to store bookmarkable state data
    #' library(pins)
    #' board <- board_folder("/path/to/storage_dir")
    #' storage <- StorageClass$new(board_sessions = board)
    #' }
    local_storage_dir = NULL,
    board_sessions = NULL,
    initialize = function(local_storage_dir = NULL, board_sessions = NULL) {
      if (is.null(local_storage_dir)) {
        local_storage_dir <- fs::path_temp("shinysessions")
      }
      self$local_storage_dir <- local_storage_dir
      shiny::shinyOptions(local_storage_dir = local_storage_dir)
      shiny::shinyOptions(save.interface = saveInterfaceLocal)
      shiny::shinyOptions(load.interface = loadInterfaceLocal)

      # initialize local pins board for session metadata
      if (is.null(board_sessions)) {
        self$board_sessions <- pins::board_folder(local_storage_dir)
      } else {
        self$board_sessions <- board_sessions
      }
    },

    #' @description
    #' Obtain saved bookmarkable state session metadata
    #' 
    #' Calls `$get_sessions()` on the [`StorageClass`] object to extract
    #' the bookmarkable state session metadata. You can leverage this data
    #' frame in your Shiny application to let the user manage their existing
    #' bookmarkable state sessions, for example.
    #' 
    #' @examples
    #' \dontrun{
    #' # beginning of application
    #' library(shiny)
    #' library(shinystate)
    #' 
    #' storage <- StorageClass$new()
    #' 
    #' # application UI for displaying session data
    #' DT::datatableOutput("session_table")
    #' 
    #' # server logic for displaying session data
    #' output$session_table <- DT::renderDT({
    #'   storage$get_sessions()
    #' })
    #' }
    get_sessions = function() {
      import_sessions(self$board_sessions)
    },

    #' @description
    #' Restore a previous bookmarkable state session
    #' 
    #' @param url character with the unique URL assigned to the bookmarkable
    #'   state session.
    #' @param session The Shiny session to associate with the restore operation
    #' 
    #' @examples
    #' \dontrun{
    #' # beginning of application
    #' library(shiny)
    #' library(shinystate)
    #' 
    #' # restoration of last-saved bookmarkable state file
    #' #
    #' # beginning of application
    #' storage <- StorageClass$new()
    #' 
    #' # application UI to trigger restore
    #' shiny::actionButton("restore", "Restore State")
    #' 
    #' # server logic for restoring state
    #' observeEvent(input$restore, {
    #'   session_df <- storage$get_sessions()
    #'   storage$restore(tail(session_df$url, n = 1))
    #' })
    #' }
    restore = function(url, session = shiny::getDefaultReactiveDomain()) {
      # download shiny bookmark files from board if not available locally
      id <- session_id_from_url(url)
      if (!fs::dir_exists(fs::path(self$local_storage_dir, "shiny_bookmarks", id))) {
        download_bookmark_bundle(
          self$local_storage_dir,
          shiny_bookmark_id = id,
          board = self$board_sessions
        )
      }
      session$sendCustomMessage("redirect", list(url = url))
    },

    #' @description
    #' Create a snapshot of bookmarkable state
    #' 
    #' @param session_metadata Optional named list of additional variables to 
    #'   include with the default bookmarkable state attributes when creating
    #'   the snapshot. Each element of the list must be a single-length item
    #' @param session The Shiny session to associate with the snapshot operation
    #' 
    #' @examples
    #' \dontrun{
    #' # beginning of application
    #' library(shiny)
    #' library(shinystate)
    #' 
    #' storage <- StorageClass$new()
    #' 
    #' # application UI to trigger save
    #' actionButton("save", "Save State")
    #' 
    #' # server logic for restoring state with timestamp as metadata
    #' observeEvent(input$save, {
    #'   storage$snapshot(session_metadata = list(time = Sys.time()))
    #' })
    #' }
    snapshot = function(session_metadata = NULL, session = shiny::getDefaultReactiveDomain()) {
      shiny::shinyOptions(session_metadata = session_metadata)
      session$doBookmark()
    },

    #' @description
    #' Delete a previous snapshot of bookmarkable state
    #' 
    #' @param url character with the unique URL assigned to the bookmarkable
    #'   state session.
    #' 
    #' @examples
    #' \dontrun{
    #' # beginning of application
    #' library(shiny)
    #' library(shinystate)
    #' 
    #' storage <- StorageClass$new()
    #' 
    #' # application UI to let user choose previous session
    #' uiOutput("previous_sessions_ui")
    #' 
    #' # application UI to trigger delete
    #' shiny::actionButton("delete", "Delete Session")
    #' 
    #' # server logic
    #' # populate dynamic UI
    #' output$previous_sessions_ui <- renderUI({
    #'   session_df <- storage$get_sessions
    #'   radioButtons(
    #'     "session_choice",
    #'     "Choose Session",
    #'     choices = session_df$url
    #'   )
    #' })
    #' 
    #' # perform session deletion
    #' observeEvent(input$delete, {
    #'   req(input$session_choice)
    #'   storage$delete(input$session_choice)
    #' })
    #' }
    delete = function(url) {
      delete_session(url, board = self$board_sessions)
    },

    #' @description
    #' Register bookmarkable state storage data collection
    #' 
    #' This method must be called in the application server function to
    #' perform the necessary customizations to bookmark methods
    #' 
    #' @examples
    #' \dontrun{
    #' # beginning of application
    #' library(shiny)
    #' library(shinystate)
    #' 
    #' storage <- StorageClass$new()
    #' 
    #' # applicaiton UI code ...
    #' 
    #' # application server code
    #' storage$register_metadata()
    #' }
    register_metadata = function() {
      set_onbookmarked(board = self$board_sessions)()
    }
  ))