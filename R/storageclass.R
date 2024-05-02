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
    bmi_storage = NULL,
    board_sessions = NULL,
    initialize = function(local_storage_dir = NULL) {
      if (is.null(local_storage_dir)) {
        local_storage_dir <- fs::path_temp("shinysessions")
        #local_storage_dir <- fs::file_temp(pattern = "shinysessions")
      }
      self$local_storage_dir <- local_storage_dir
      shiny::shinyOptions(local_storage_dir = local_storage_dir)
      shiny::shinyOptions(save.interface = saveInterfaceLocal)
      shiny::shinyOptions(load.interface = loadInterfaceLocal)

      # initialize local pins board for session metadata
      self$board_sessions <- pins::board_folder(local_storage_dir)

      # initialize app checking function for updated session data
      self$bmi_storage <- list(
        pool = self$board_sessions,
        reader = shiny::reactivePoll(
          intervalMillis = 1000,
          session = NULL,
          checkFunc = function() {
            if (empty_sessions(self$board_sessions)) {
              return(NULL)
            } else {
              pins::pin_meta(self$board_sessions, "sessions")$pin_hash
            }
          },
          valueFunc = function() {
            import_sessions(self$board_sessions)
          }
        )
      )
    },
  #' @details
  #' Restore a previous bookmarkable state session
  #' 
  #' @param url character with the unique URL assigned to the bookmarkable
  #'   state session.
  #' @param session The Shiny session to associate with the restore operation
    restore = function(url, session = shiny::getDefaultReactiveDomain()) {
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
  #' @details
  #' Register bookmarkable state storage data collection
    register_metadata = function() {
      set_onbookmarked(
        pool = self$board_sessions
      )()
    }
  ))