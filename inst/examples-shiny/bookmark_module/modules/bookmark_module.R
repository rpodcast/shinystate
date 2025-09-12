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
  session_df <- reactive({
    storage$get_sessions()
  })

  output$saved_sessions_placeholder <- renderUI({
    DT::dataTableOutput(session$ns("saved_sessions_table"))
  })

  output$saved_sessions_table <- DT::renderDataTable({
    req(session_df())
    DT::datatable(
      session_df(),
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
    "restore"
  ))

  observeEvent(input$show_load_modal, {
    showModal(modalDialog(
      size = "xl",
      easyClose = TRUE,
      title = "Restore session",
      footer = tagList(
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
              save_name = input$save_name,
              timestamp = Sys.time()
            )
          )
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
}
