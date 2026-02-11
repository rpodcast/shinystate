# Bookmark Modules Example

## Introduction

The `shinystate` package was greatly inspired by an [example
application](https://github.com/jcheng5/rpharma-demo) created by Joe
Cheng (creator of Shiny) to accompany his keynote presentation at the
2018 [R/Pharma conference](https://rinpharma.com/). Among other notable
features as documented in the GitHub repository
[README](https://github.com/jcheng5/rpharma-demo/blob/master/README.md),
the application provided an alternative user interface powered by Shiny
modules to save and restore bookmarkable state. The following example is
an adaptation of the original version to utilize `shinystate` to manage
the bookmarkable state features.

## How to Run Application

The application source code is included in the ‘shinystate’ package and
it can be launched with the following code:

``` r
library(shiny)
library(shinystate)
runExample("bookmark_module", package = "shinystate")
```

If you are viewing this package vignette in a web browser, the
application can also be viewed using the Shinylive service:

[Open in
Shinylive](https://shinylive.io/r/app/#code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgDk7ABZsAnpyjkBuAAQM4qIu1kBeWQUHDSpVO0QB6AwyUATAlE4YGAWgCuEFgDc4DdnAym4TmbIHbdfSMFJWsbaksYDCIGAHMBAEoEsABfAF0gA)

## Application Code

The remainder of this vignette contains the source code of the
application. Note that the version included in the package is
constructed with separate R scripts containing the module and utility
function code.

The same principles for using `shinystate` in an application apply in
this example as well, but here are specific notes for the implementation
used in this example application:

- The module `bookmark_mod` contains a parameter for the `StorageClass`
  instance used for the application.
- Bookmarkable state sessions are displayed using an interactive table
  produced by
  [`DT::datatable()`](https://rdrr.io/pkg/DT/man/datatable.html) with
  the ability to select the row used to restore a saved session. This is
  just one approach to display sessions in a Shiny application.
- The `reactive_sessions()` method is used with a trigger to
  automatically refresh the session list when the modal opens, after
  saving, or after deleting a session.
- A reactive object `session_choice` corresponding to the `url` value of
  the selected row in the sessions table is supplied to the `restore()`
  method of the `StorageClass` instance.
- A custom bookmark name entered in a text input plus the bookmark id
  and a timestamp are saved as part of the bookmarkable state snapshot
  metadata. These are assembled as a
  [`list()`](https://rdrr.io/r/base/list.html) object with named
  elements for each variable. Other custom scalar metadata about the
  bookmark could also be captured.

### `app.R`

``` r
library(shiny)
library(shinystate)
library(dplyr)
library(DT)

#  recommended to define a directory for storage or a pins board
storage <- StorageClass$new()

ui <- function(req) {
  tagList(
    # Bootstrap header
    tags$header(
      class = "navbar navbar-default navbar-static-top",
      tags$div(
        class = "container-fluid",
        tags$div(
          class = "navbar-header",
          tags$div(class = "navbar-brand", "Bookmark Module Demo")
        ),
        # Links for restoring/loading sessions
        tags$ul(
          class = "nav navbar-nav navbar-right",
          tags$li(
            bookmark_modal_load_ui("bookmark")
          ),
          tags$li(
            bookmark_modal_save_ui("bookmark")
          )
        )
      )
    ),
    fluidPage(
      use_shinystate(),
      sidebarLayout(
        position = "right",
        column(
          width = 4,
          wellPanel(
            select_vars_ui("select")
          ),
          wellPanel(
            filter_ui("filter")
          )
        ),
        mainPanel(
          tabsetPanel(
            id = "tabs",
            tabPanel("Plot", tags$br(), plotOutput("plot", height = 600)),
            tabPanel("Summary", tags$br(), verbatimTextOutput("summary")),
            tabPanel("Table", tags$br(), tableOutput("table"))
          )
        )
      )
    )
  )
}

server <- function(input, output, session) {
  callModule(bookmark_mod, "bookmark", storage)
  storage$register_metadata()
  datasetExpr <- reactive(expr(mtcars %>% mutate(cyl = factor(cyl))))
  filterExpr <- callModule(filter_mod, "filter", datasetExpr)
  selectExpr <- callModule(
    select_vars,
    "select",
    reactive(names(eval_clean(datasetExpr()))),
    filterExpr
  )

  data <- reactive({
    resultExpr <- selectExpr()
    df <- eval_clean(resultExpr)
    validate(need(nrow(df) > 0, "No data matches the filter"))
    df
  })

  output$table <- renderTable(
    {
      data()
    },
    rownames = TRUE
  )

  do_plot <- function() {
    plot(data())
  }

  output$plot <- renderPlot({
    do_plot()
  })

  output$summary <- renderPrint({
    summary(data())
  })

  output$code <- renderText({
    format_tidy_code(selectExpr())
  })
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
```

### `bookmark_modules.R`

``` r
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
```

### `filter_module.R`

``` r
library(shiny)
library(dplyr)
library(rlang)

filter_ui <- function(id) {
  ns <- NS(id)

  tagList(
    div(id = ns("filter_container")),
    actionButton(ns("show_filter_dialog_btn"), "Add filter")
  )
}

filter_mod <- function(input, output, session, data_expr) {
  ns <- session$ns

  setBookmarkExclude(c("show_filter_dialog_btn", "add_filter_btn"))

  filter_fields <- list()
  makeReactiveBinding("filter_fields")

  onBookmark(function(state) {
    state$values$filter_field_names <- names(filter_fields)
  })

  onRestore(function(state) {
    filter_field_names <- state$values$filter_field_names
    for (fieldname in filter_field_names) {
      addFilter(fieldname)
    }
  })

  observeEvent(input$show_filter_dialog_btn, {
    available_fields <- names(eval_clean(data_expr())) %>% base::setdiff(names(filter_fields))

    showModal(modalDialog(
      title = "Add filter",

      radioButtons(ns("filter_field"), "Field to filter",
        available_fields),

      footer = tagList(
        modalButton("Cancel"),
        actionButton(ns("add_filter_btn"), "Add filter")
      )
    ))
  })

  observeEvent(input$add_filter_btn, {
    addFilter(input$filter_field)
    removeModal()
  })

  addFilter <- function(fieldname) {
    id <- paste0("filter__", fieldname)

    filter <- createFilter(
      data = eval_clean(data_expr())[[fieldname]],
      id = ns(id),
      fieldname = fieldname)

    freezeReactiveValue(input, id)

    insertUI(
      paste0("#", ns("filter_container")),
      "beforeEnd",
      # TODO: escape special characters in fieldname
      filter$ui
    )

    filter$inputId <- id
    filter_fields[[fieldname]] <<- filter
  }

  reactive({
    result_expr <- data_expr()

    if (length(filter_fields) == 0) {
      return(result_expr)
    }

    # Gather up all filter expressions
    exprs <- lapply(names(filter_fields), function(name) {
      filter <- filter_fields[[name]]
      x <- as.symbol(name) #df[[name]]
      param <- input[[ filter[["inputId"]] ]]
      cond_expr <- filter[["filterExpr"]](x = x, param = param)
      if (!is.null(cond_expr)) {
        result_expr <<- expr(!!result_expr %>% filter(!!cond_expr))
      }
      invisible()
    })

    result_expr
  })
}

createFilter <- function(data, id, fieldname) {
  UseMethod("createFilter")
}

createFilter.character <- function(data, id, fieldname) {
  list(
    ui = textInput(id, fieldname, ""),
    filterExpr = function(x, param) {
      if (!nzchar(param)) {
        NULL
      } else {
        expr(grepl(!!param, !!x, ignore.case = TRUE, fixed = TRUE))
      }
    }
  )
}

createFilter.numeric <- function(data, id, fieldname) {
  list(
    ui = sliderInput(id, fieldname, min = min(data), max = max(data),
      value = range(data)),
    filterExpr = function(x, param) {
      if (is.null(param) || length(param) == 0) {
        NULL
      } else {
        expr(!!x >= !!param[1] & !!x <= !!param[2])
      }
    }
  )
}

createFilter.integer <- createFilter.numeric

createFilter.factor <- function(data, id, fieldname) {
  inputControl <- if (length(levels(data)) > 6) {
    selectInput(id, fieldname, levels(data), character(0), multiple = TRUE)
  } else {
    checkboxGroupInput(id, fieldname, levels(data))
  }

  list(
    ui = inputControl,
    filterExpr = function(x, param) {
      if (length(param) == 0)
        NULL
      else
        expr(!!x %in% !!param)
    }
  )
}

createFilter.POSIXt <- createFilter.numeric
```

### `select_module.R`

``` r
library(shiny)
library(dplyr)
library(rlang)

select_vars_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("vars_ui"))
  )
}

select_vars <- function(input, output, session, vars, data_expr) {
  ns <- session$ns

  output$vars_ui <- renderUI({
    freezeReactiveValue(input, "vars")
    selectInput(ns("vars"), "Variables to display", vars(), multiple = TRUE)
    #checkboxGroupInput(ns("vars"), "Variables", names(data), selected = names(data))
  })
  
  reactive({
    if (length(input$vars) == 0) {
      data_expr()
    } else {
      expr(!!data_expr() %>% select(!!!syms(input$vars)))
    }
  })
}
```

### `summarize_module.R`

``` r
library(shiny)
library(dplyr)
library(rlang)

summarize_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("summarize_ui"))
  )
}

summarize_mod <- function(input, output, session, vars, data_expr) {
  output$summarize_ui <- renderUI({
    ns <- session$ns
    
    tagList(
      selectInput(ns("group_by"), "Group by", choices = vars(), multiple = TRUE),
      selectInput(ns("operation"), "Summary operation", c("mean", "sum", "count")),
      selectInput(ns("aggregate"), "Summary value", choices = vars(), multiple = TRUE)
    )
  })
  
  reactive({
    result_expr <- data_expr()
    if (length(input$group_by) > 0) {
      result_expr <- expr(!!result_expr %>% group_by(!!!syms(input$group_by)))
    }
    if (length(input$aggregate) > 0) {
      op <- switch(input$operation,
        mean = quote(mean),
        sum = quote(sum),
        count = quote(length)
      )
      agg_exprs <- lapply(input$aggregate, function(var) {
        col_name <- deparse(expr((!!sym(input$operation))(!!sym(var))))
        expr(!!col_name := (!!op)(!!sym(var)))
      })
      result_expr <- expr(!!result_expr %>% summarise(!!!agg_exprs))
    }
    result_expr
  })
}
```

### `utils.R`

``` r
library(rlang)

#' Evaluate an expression in a fresh environment
#'
#' Like eval_tidy, but with different defaults. By default, instead of running
#' in the caller's environment, it runs in a fresh environment.
#' @export
eval_clean <- function(expr, env = list(), enclos = clean_env()) {
  eval_tidy(expr, env, enclos)
}

#' Create a clean environment
#'
#' Creates a new environment whose parent is the global environment.
#' @export
clean_env <- function() {
  new.env(parent = globalenv())
}

#' Join calls into a pipeline
expr_pipeline <- function(..., .list = list(...)) {
  exprs <- .list
  if (length(exprs) == 0) {
    return(NULL)
  }

  exprs <- rlang::flatten(exprs)

  exprs <- Filter(Negate(is.null), exprs)

  if (length(exprs) == 0) {
    return(NULL)
  }

  Reduce(
    function(memo, expr) {
      expr(!!memo %>% !!expr)
    },
    tail(exprs, -1),
    exprs[[1]]
  )
}

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
    sprintf("%d %s %s", x, ifelse(x == 1, singular, plural), dir)
  }

  ifelse(
    abs_age == seconds(0),
    "Now",
    ifelse(
      abs_age < minutes(1),
      format_rel("second"),
      ifelse(
        abs_age < hours(1),
        format_rel("minute"),
        ifelse(
          abs_age < hours(6),
          format_rel("hour"),
          # Less than 24 hours, and during the same calendar day
          ifelse(
            abs_age < days(1) & abs_day_diff == 0,
            strftime(t, "%I:%M:%S %p"),
            ifelse(
              abs_age < days(3),
              strftime(t, "%a %I:%M:%S %p"),
              strftime(t, "%Y/%m/%d %I:%M:%S %p")
            )
          )
        )
      )
    )
  )
}
```
