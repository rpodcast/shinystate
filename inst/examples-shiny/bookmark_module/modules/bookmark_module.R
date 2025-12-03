library(shiny)
library(dplyr)
library(lubridate)

bookmark_modal_save_ui <- function(id) {
  ns <- NS(id)

  tagList(
    actionLink(ns("show_save_modal"), "Save session")
  )
}

bookmark_modal_load_ui <- function(id) {
  ns <- NS(id)

  tagList(
    actionLink(ns("show_load_modal"), "Restore session")
  )
}

bookmark_load_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("saved_sessions"))
  )
}

bookmark_mod <- function(input, output, session, storage) {
  ns <- session$ns

  # Trigger for refreshing session list
  refresh_trigger <- reactiveVal(0)

  # Use reactive_sessions with trigger - refreshes on:
  # 1. Modal open (input$show_load_modal changes)
  # 2. After save (refresh_trigger increments)
  # 3. After delete (refresh_trigger increments)
  session_df <- storage$reactive_sessions(
    trigger = reactive(list(refresh_trigger(), input$show_load_modal))
  )

  output$saved_sessions_placeholder <- renderUI({
    DT::dataTableOutput(session$ns("saved_sessions_table"))
  })

  output$saved_sessions_table <- DT::renderDataTable({
    sessions <- session_df()

    # Show message if no sessions exist
    if (is.null(sessions) || nrow(sessions) == 0) {
      # Return empty data frame with message
      return(DT::datatable(
        data.frame(Message = "No saved sessions found. Save a session first!"),
        options = list(dom = 't'),
        rownames = FALSE,
        selection = 'none'
      ))
    }

    DT::datatable(
      sessions,
      escape = FALSE,
      selection = "single"
    )
  })

  session_choice <- reactive({
    req(session_df())
    req(input$saved_sessions_table_rows_selected)
    i <- input$saved_sessions_table_rows_selected
    url <- session_df()[i, "url"]
    return(url)
  })

  observeEvent(input$restore, {
    req(session_choice())
    storage$restore(session_choice())
  })

  shiny::setBookmarkExclude(c(
    "show_save_modal",
    "show_load_modal",
    "save_name",
    "save",
    "session_choice",
    "restore",
    "delete"
  ))

  observeEvent(input$show_load_modal, {
    showModal(modalDialog(
      size = "xl",
      easyClose = TRUE,
      title = "Restore session",
      footer = tagList(
        actionButton(session$ns("delete"), "Delete", class = "btn-danger"),
        modalButton("Cancel"),
        actionButton(session$ns("restore"), "Restore", class = "btn-primary")
      ),
      tagList(
        uiOutput(session$ns("saved_sessions_placeholder"))
      )
    ))
  })

  observeEvent(input$show_save_modal, {
    showModal(modalDialog(
      easyClose = TRUE,
      textInput(session$ns("save_name"), "Give this session a name"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton(session$ns("save"), "Save", class = "btn-primary")
      )
    ))
  })

  observeEvent(input$save, ignoreInit = TRUE, {
    tryCatch(
      {
        if (!isTruthy(input$save_name)) {
          stop("Please specify a bookmark name")
        } else {
          removeModal()
          storage$snapshot(
            session_metadata = list(
              save_name = input$save_name
            )
          )
          # Trigger refresh so user sees their new bookmark
          refresh_trigger(refresh_trigger() + 1)
          showNotification(
            "Session successfully saved"
          )
        }
      },
      error = function(e) {
        showNotification(
          conditionMessage(e),
          type = "error"
        )
      }
    )
  })

  # Delete handler
  observeEvent(input$delete, ignoreInit = TRUE, {
    tryCatch(
      {
        req(session_choice())
        storage$delete(session_choice())
        # Trigger refresh so deleted bookmark disappears from list
        refresh_trigger(refresh_trigger() + 1)
        showNotification(
          "Session deleted"
        )
      },
      error = function(e) {
        showNotification(
          conditionMessage(e),
          type = "error"
        )
      }
    )
  })
}