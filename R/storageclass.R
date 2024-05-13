#' StorageClass R6 class
#' 
#' This class provides a set of methods to create a Shiny bookmarkable state
#' storage location using R6.
#' 
#' @export
StorageClass <- R6::R6Class( # nolint
  "StorageClass",
#' @details
#' Create a new 'StorageClass' object.
#' 
#' @param local_storage_dir file path to use for storing bookmarkable state
#'   files. If not specified, a temporary directory on the host system
#'   will be used.
#' @param bmi_storage TODO may move to private
#' @param board_sessions TODO may move to private
  public = list(
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
    get_sessions = function() {
      import_sessions(self$board_sessions)
    },
  #' @details
  #' Restore a previous bookmarkable state session
  #' 
  #' @param url character with the unique URL assigned to the bookmarkable
  #'   state session.
  #' @param session The Shiny session to associate with the restore operation
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
  #' @details
  #' Create a snapshot of bookmarkable state
  #' 
  #' @param session_metadata Optional named list of additional variables to 
  #'   include with the default bookmarkable state attributes when creating
  #'   the snapshot. Each element of the list must be a single-length item
  #' @param session The Shiny session to associate with the snapshot operation
    snapshot = function(session_metadata = NULL, session = shiny::getDefaultReactiveDomain()) {
      shiny::shinyOptions(session_metadata = session_metadata)
      session$doBookmark()
    },
    delete = function(url) {
      delete_session(url, board = self$board_sessions)
    },
  #' @details
  #' Register bookmarkable state storage data collection
    register_metadata = function() {
      set_onbookmarked(board = self$board_sessions)()
    }
  ))