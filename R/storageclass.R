#' StorageClass R6 class
#' 
#' This class provides a set of methods to create a Shiny bookmarkable state
#' storage location using R6.
#' 
#' @section Usage:
#' TODO finish
StorageClass <- R6::R6Class( # nolint
  "StorageClass",
  public = list(
    local_storage_dir = NULL,
    bmi_storage = NULL,
    board_sessions = NULL,
    initialize = function(local_storage_dir = NULL) {
      if (is.null(local_storage_dir)) {
        local_storage_dir <- fs::path_temp("shinysessions")
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
    restore = function(url, session = shiny::getDefaultReactiveDomain()) {
      session$sendCustomMessage("redirect", list(url = url))
    },
    snapshot = function(session_metadata = NULL, session = shiny::getDefaultReactiveDomain()) {
      shiny::shinyOptions(session_metadata = session_metadata)
      session$doBookmark()
    },
    register_metadata = function() {
      set_onbookmarked(
        pool = self$board_sessions
      )()
    }
  ))