library(shiny)
library(DBI)
library(RSQLite)
library(pool)
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

bookmark_init <- function(filepath = file.path("shinysessions", "bookmarks.sqlite")) {
  if (!dir.exists(dirname(filepath))) {
    dir.create(dirname(filepath))
  }
  
  bookmark_pool <- local({
    pool <- dbPool(SQLite(), dbname = filepath)
    onStop(function() {
      poolClose(pool)
    })
    pool
  })
  
  bookmarks <- reactivePoll(1000, NULL,
    function() {
      file.info(filepath)$mtime
    },
    function() {
      bookmark_pool %>% tbl("bookmarks") %>%
        arrange(desc(timestamp)) %>%
        collect() %>%
        mutate(
          timestamp = friendly_time(as.POSIXct(timestamp, origin = "1970-01-01")),
          link = sprintf("<a href=\"%s\">%s</a>",
            htmltools::htmlEscape(url, TRUE),
            htmltools::htmlEscape(label, TRUE))
        )
    }
  )
  
  list(
    pool = bookmark_pool,
    reader = bookmarks
  )
}

bookmark_mod <- function(input, output, session, instance, thumbnailFunc) {
  ns <- session$ns
  session_df <- reactive({
    message("entered session_df")
    req(instance$reader())
    instance$reader() %>%
      select(url, label, author, timestamp) %>%
      mutate(url2 = glue::glue("<a href={url}>{label}</a>"))
  })
  
  output$saved_sessions_placeholder <- renderUI({
    fluidRow(
      #DT::dataTableOutput(session$ns("saved_sessions_table"))
      uiOutput(ns("saved_sessions"))
    )
  })
  
  output$saved_sessions_table <- DT::renderDataTable({
    req(session_df())
    DT::datatable(
      session_df(),
      escape = FALSE
    )
  })
  
  output$saved_sessions <- renderUI({
    fluidRow(
      instance$reader() %>%
        select(url, label, author, timestamp, thumbnail) %>%
        rowwise() %>%
        do(ui = with(., {
          tags$div(class = "col-md-4",
            tags$div(class = "thumbnail",
              if (!is.null(thumbnail) && isTRUE(!is.na(thumbnail))) {
                tags$a(href = url, tags$img(src = thumbnail))
              },
              tags$div(class = "caption",
                tags$h4(tags$a(href = url, label)),
                tags$p(
                  author,
                  tags$br(),
                  tags$small(timestamp)
                )
              )
            )
          )
        })) %>%
        pull(ui)
    )
  })

  output$saved_sessions <- renderUI({
    df <- instance$reader() %>%
      select(url, label, author, timestamp, thumbnail) %>%
      collect()

    radioButtons(
      ns("session_choice"),
      "Choose Session",
      choiceNames = df$label,
      choiceValues = df$url
    )
  })

  observeEvent(input$restore, {
    req(input$session_choice)
    session$sendCustomMessage("redirect", list(url = input$session_choice))
  })
  
  shiny::setBookmarkExclude(c("show_save_modal", "show_load_modal", "save_name", "save", "session_choice", "restore"))
  
  observeEvent(input$show_load_modal, {
    showModal(modalDialog(size = "xl", easyClose = TRUE, title = "Restore session",
      footer = tagList(
        modalButton("Cancel"),
        actionButton(session$ns("restore"), "Restore", class = "btn-primary")
      ),
      #tags$style(".modal-body { max-height: 900px; overflow-y: scroll; }"),
      #uiOutput(session$ns("saved_sessions")),
      uiOutput(session$ns("saved_sessions_placeholder"))
    ))
  })
  
  observeEvent(input$show_save_modal, {
    showModal(modalDialog(easyClose = TRUE,
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
          session$doBookmark()
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
  
  set_onbookmarked(url, thumbnailFunc, input$save_name, instance$pool)
}



### Utility functions ==============

friendly_time <- function(t) {
  t <- round_date(t, "seconds")
  now <- round_date(Sys.time(), "seconds")

  abs_day_diff <- abs(day(now) - day(t))
  age <- now - t
  
  abs_age <- abs(age)
  future <- age != abs_age
  dir <- ifelse(future, "from now", "ago")
  
  
  format_rel <- function(singular, plural = paste0(singular, "s")) {
    x <- as.integer(round(time_length(abs_age, singular)))
    sprintf("%d %s %s",
      x,
      ifelse(x == 1, singular, plural),
      dir
    )
  }
  
  ifelse(abs_age == seconds(0), "Now",
    ifelse(abs_age < minutes(1), format_rel("second"),
      ifelse(abs_age < hours(1), format_rel("minute"),
        ifelse(abs_age < hours(6), format_rel("hour"),
          # Less than 24 hours, and during the same calendar day
          ifelse(abs_age < days(1) & abs_day_diff == 0, strftime(t, "%I:%M:%S %p"),
            ifelse(abs_age < days(3), strftime(t, "%a %I:%M:%S %p"),
              strftime(t, "%Y/%m/%d %I:%M:%S %p")
            ))))))
}
