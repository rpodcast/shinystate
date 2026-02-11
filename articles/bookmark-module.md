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
Shinylive](https://shinylive.io/r/app/#code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgDk7ABZsAnpyjkBuAAQM4qIu1kBeWQUHDSpVO0QB6AwyUATAlE4YGAWgCuEFgDc4DdnAym4TmbIHbdfSMFJWsbaksYDCIGAHMBAEoEgB0IAGIBWQBRJx47KThZKAhZOAAPVAV2dhYSWTYi2QAzKuFSiCcWBhJ4MlSM-syAGRYAa0LvHgB9UhZTMTk6O1JZahZSNtMWJqbXChWvJqg7blJ2DFkAITFZQ+PTuTZOOChTWSIm+QdHCFjB+pKG0KFl4riE7U63QgvVIjxWDAcKgaUGarQhXR6+ww-wAAuUlAxSKlJtwpgRuC8SgAeGzNBwEWYkPj4hhyChONSybgsTh8BJsiDk5Sc8mUqbsvkJWQgVKyUq5UmzebMiqsiECoXsFIQAC+qX+AGEFAVGqLiuioTDBobjeQVCiIHBqBbMWRVsJlIVUFAFG6ebIgbJYtwiHQeC7oVjcfiYkTBRTiuKOrIaXTBYyIHzpbLZI7qBgJd7fSt1MHQzwJUlUnqIP8AFJEBog7hIshERqoFioODcx3E1VTTvd3uFVNNekZvgYadyDDczic+ekKfTpLZkqlVUqVNznlxuXbWR8Cm-DYqypatTqAAMUplG7lClIdgYmYAcgBVIZDbVyms5llt1pBhuGKWJmCaUCdAoc83G1ACtxTWkADEWFOVw+DfOBYgKPgeQwCATm4flNwveCN0PY8KFiM9AKlVQbzvHNHzgZ9X0wr8fxzf8NywOBTDsAg4D4Zi0wZWpM3gGAiDZVUmIfOVSIYPgAEIVKk9sAFIAD5NNkNSWV-RSdVwUSuDQ2D2DkGwAEZ+VEwDgGAGyAF0XJzbUeJaFgKFMbgxBmFh4CQsTJ1IeS5RWVNugcUwplMXDYVkZIwHcYgIFMdgUqMiAiGdaKiFi+LcIAZQkDBZngPk5BStKSEy7L9Q3KA6HYYqAq2HYQpa9g+ASsQ+Fy6gpVpfq+HCoyoFiUdaSG2RaTjHMeqmKaZqKVq+FWozxzYtbVv09RltWnMtgYELth7dw+B2l84BqsAWiIGBczylL7qmohGtrDcmhiGApCmBRuBC8d0wkvgal+E4fTkVBuBfcN1G9Z5rwhthYmhtVauyiLFLKbrzjYchpuUmKMvGoK4CmE8aOETbWpW6a5EhjHQIYJIjLldhKiJpoRLATS3k0lRhbe2QykeXYW2E-GGNkGzmfRzHYfhhgeBI06jJ4g8pau0Sjumq9ZDqjLetvUyFJSt9XrwUSLulkSFLlA3R1kGA2GWOBersi3FMU36GH+0hAZ7fmTdMbLfb9+pdeE0S-ZdlNZA9F9vfsp3-b+gGgf593CPISP48U+29YzhOGf2qlk8Ktw+AANnT6Po4DoOQ-4FKU4YQuy8UtJZCGL2VA2c0ACYABZq9TuRijeASGHRgNhEKdhYGBCsMp9W4oDEIu-ZLuOe-LtrK63iQ+Ds2QADJ1ra-r4u2T45evKOm79zgGCaSrhKSlLNIASUQJpAAsoAkqshNKoG7q-aO+9HbQKbonKu-VeoAGZG7wLfqQD+X9xr3U0iif+gCQGaTARAqBGDFLv0-pTXByUBYAE0DCaRgEwoWADgGgPAZAsAnN4G8KbvwxSgjeFGU8qkOgRAiCjH+gwUYUxpIJVJCvFwUw7AsBBhOcGcxcYcBCm+EqeFTDkUilNEYvJ9biRICMCAoxBq9Vqh6agUxlFUwUTwSOdCSpQBcMbQeEkvpyjEd9CRUiZFyLcaSEMrxVHqLHJopk2j1xyl0amfRhjjEBlMXuOBikoCWIgNY2xHAw6OOpkQaJESPEpT4pwGIy8-EkACbIIJ4jJHSJ9HIqJcU1EaLBgkoxSTcxAVkGk7ROYuCxDMcuUSaiADyyxUDLDsWHbx-FnENI4DjDy1YmohPabI+RRA3hxL6ZmNgiykqFV0MsZmGzmakBiFtQZKTaTuGqBJAAJJsjcbyagkHip8aKLxxIuD4PeTBjzpofOmsHX5ElepawyVci5HyXFxThSQNqcM8lwA9NwLwZ0gUZVcB+P+YLRIABEAAqzAEpcCpS1Ck8zrnLgxRAL59jUqrPRRstqXA6AUi2RuHUSKFnLFRdy9Z7zMUzEZWtalzBfQEopVIKADKBXCXBYpBQABHCGGyAWSkpTSxAdLVUapyW-A1pg+boL9l7Cw3ZOTIQAIJDBKlkF+lCexwHyZyWq6NBVgFEoipqXMDUEA9CwISIVjQgs1aJXV+rpUQENVWBSSbznirRVKv5HBZUasBnlNq7gKQMn4rw2JtIs2kAlS4HlKa+VyqLdQEtPry0RwUi+YGqY2VpuACwe63aUruQzaxF8mZu2hu+nKUM7gGAuByPsPCEAUVVAeQoOQWqWJ6r7ZGxsQkjUKVqWrKF666nJrzWSKNh701-gySIcQzB3CkEuG0sJWQyjkjsF4PgmhRIOLys41ZhzFFvQA6lUpXTQPuNtpbLlKjoDwHA-BlxKG-a1QjTeuA6HFIpXPQoFKHkkWtVcIulwZAV0opEEB6DESt2iRo9QIBRyeB8AiRSlgPAiCxEtZQlgAAvQo6gUplG4Lh+1lgxAGhDO4TkVKsAfk9UXWYpAKT+rADUjd9SU0SczkQcgZ11ATKmXxv2ETLjLAeZmFKBpihCXEzwr1Cd8mWZ0EyNlHL+YEZw05uhWm6li3JJYFQImwB0FIBAGwPMZE7x4UXO1ikTPZN3rIOZYrWUbK87VSVbKsWgSEniglQqBEhunTmOdZG4BLsozW1FpSXEwe4Ax49jiWOKPY6x7gnHuO8aLi8dg0nZPCdkAppTzmAzlFIH-VdSzPPFJy4h1eVSwAAHFnCFA2P6NljQkO+cS3KX6BnXCcmS+YnuFmrNMls-Zns5CEGuau5mebnK0N+ZSl4lwQXQLVA0xFqLMWfRxeEWV7iJH53keXXVlxjxYi5QUDN9Y8nFOesGZFBg0mpCRrM2jmBnxVI8ipQiDYA1ocgb22ubdr9amoH5gABQTHJ7mvrtg3BRHssJuZlvxZ7jqUo0tcdNwUNJFw7W2OCIhaeuAqLoB6A9NMw+3qU3yNYq8VVi4UuK7fuT1enIydLfgBN6BX9JAwFQJyMq5wcES+jjbwJqWuaOOtrMJo0apDgwd3hsAJUNnG0EkJao45eA3DRURxXNuaxNxMv1hg3QjOhXBnAXGTcmPO+2G7ycnv0pbAzEAweq1mQHejqQMQTqwuuDj2H6BgjI9CLBzsiArv0IMBib0-J6TnnDNGUYsNmTJma79lsJwhjOQLYemhQzZISDmUdF3HhiW8kZjc9Z5ZgGnFN8n1sXrUx-srZdaYN4G-XBNJaY3ifrhQNt8nDWuQyKbm+JTXIM14o5Kd5Ci93vL632hI6Z+79v7-1IMgMj8W8t8QxYgd9IsxYUpXg4oQDIDax59e94DXcexMoQolw+Qcx-pxg+JF8NtLg2Athfh+YUCfJ8UsoecKsIBv99lbFQZ29JByBk9jYuByAPkFQ7AvYPkyC0Cpg9thkBDrpz8W9UCKDysNwSAAsFBrp4lns2Ck9cdeD8V+DV5hkmDpdODuDlC4oBDRIA4jwxDTA9sARmgRCpgjDVD4BLwqdnYD9UJm9hC0CKdRJa8RVe9KsF1qsKNlxodSl4CwCeMECWsE5cg0Jm0jDBC1DmQFQyQExMxn8WRJQpQdJNIi4wx3Bn1WJOo+YhCdCtQMlHc8oxd+AOMuNwCcdVN1Mwt99D8RCUMi41YtgiBl9MVV9x9m8LDyCI53swBUI0CAx2wQCxZvEoBwjC1Ij04i4jtDNTsslztoFLt3MbMwA7NBQ7snNUt8CSBWjMwx9YCujOjd9ejaizDm8mk-YREJDZ1SMvCatfDZta0Dj4D-sQjcl7CRCqNxUdDeFhciBRcussDhUMlYCHDZiTl28jCKdcc5gQpkZyBUYUp4CpgxYoTV5CizjwTaQCBbQ4AwSMIi4zVOQSQ4jKQ+pVUX9KhJQnI0T4A3IJtYT1BiltEJtaSRs2SQ1e9DsFA4AhM8D40AA1PIYSG-eoHvGdYuDgVwUgUlHHeEuAREsANIMWMfeA9KGfY-efCbFKOgOAAOarDKPTOUPuKlWZClWZRAUodgR1ZebsAgcojQYQH0RfVwVsMw5w5bDOEAj5NRTkiUw7EQj5GtP+Y5atTtP2fImk7ovbNyFMMceo4VXvONWYUFKnKoE4YOFkEKRI1UIEu2fHGmM8fI+iRiQXeQcddidM04Sk9mVwrk2QPuVbKQJeM6Owc3HgYGEApSXlByRCVMUCdAfyQaaI4suQBgycaE2wzEk7eMzoyIpyGM0dJufGVMSwDAQbGACRfgaEtIG1Bc1eNyIuIsWAc6R4qM5vJyFKYMnotyQ8jObPGskGEQy8jowzT9SoEdFyPgWWcWWGZ056JGf8wRSiFSfCQiXgP9eqGsynVLKszM1UOM2kJItSOCx81I6c5SNSB8wyGvIuNgToGoC1Xhdw-08s9gDMms+vXUJqHEl4cgfEwlWkcc8GM1R4UwMc6M9EwZD8dwPPDYI5fmWigoBir6HiIS+ikQjASNZ08tRihPJkVisUjij0+AXGTAmZdRYzKbGbC5QxZS-FPbe6e7DC98+PZipkCWWQY8mAFgnWI8FSCAATaS5SaymCnuT8b8IuPnS6QoKcuUJI2IEIfgNSayuQNSSylgOHOpKSywEbMbVHV3MofiZHJTO9aOWvP8bZai76cSvEySwieAeeAgK-Fi1VNi-S4wrirVdSrtTS42bkAlHSpZPC9i6Yziw3IuPOTkPOckrgIvf6H8ga3qqAIvLQzkNWX4YSM1ERL1EA0yzkcyzMSy1yss5ClSfGbSdQEK-85yFyK+fSdalMLalSay4AEeFyYirKsS3EhijAImbCGc7Em6-KuwQq6NGi565vDAI4BkGIEqhSsqpS90gyqqnMGtA0afboHtatAs6iM8CkFwFsYatcbSWQBuXHUtX1abR4vS4Gyqw3LkbwS6ZGuQZyl05Sc2N2DMrsao0bFHLWfnOTKnSNX1UYCRMoVbGKVAJq3w9ivGwywmxG3qaarWXvGqv2HpdQcGyGogZrfQkQ+a9QRa78v8tWGyssyiQsumFap+WyxSDyoYLyxm3y1LNa-GTSNgPSbatW3ChSWvU-XK26unWZEqP+AADSiieroryq+oKtcHeqlLLWDlyDcFbwhOvwGS1ReRGQMTGQ3DOwVwlpYGZV0rHxDral9KQI3FP0xoZCmHTv+rOUeNvwy1uUf1kHTqfwpMMjf17Sy2+Qqwyw4J9AzqrXLOJQYFlKpxaDgF5LgH5JTLgCFPhhFOLroXTouN8SDp5vaInt6KFPnjlSHnbC2G5lAjizkHTuqiptOBprivptEjSBZoIDZqIA5q5pnrTpbpWwXq4w1UoLkCEOmtuSDuSqZOiJFqopzGTI23JQUk1rhrpjq3TpLNkFvDLJzKpOIuNtWtzLUkgeUhSN0inqxtUjUg3N6mAZbo5jrOBIb1SHIpgBkUEyph6XDq0UjpzGju7yMgTr43SxZXaMIeIaExiRK2aXwY4FepYdcSOULq+MuVLofzzU3pbqrq4GgsGTv1rWYZ9BIbDuAl8hJTJSp2jo-1IroaLlzuxt0tSzH0CsKlQB32ByNzoU5sMdkDoA3tS33WjS9k5C3qLzlBgGprhn3qUwSwm20Znr0c5SIG7DVgzGMow2924aB3eACfd0aTg2gUAPgGKGgNSlesSeIAcCJB5wES8fbR0eap7n2NiECuwgKGCa9xKjCYxwruFKNMUlsYDwcZbuqlSxcd3rcZSqyASz9PvSTOBUHr-r9lQqzNTAQaBL3lhtPCAceOhS5uMalFRvAanIGYQtTDWsWcqHAWQYMbbOMbQZUgwYEamcMZmbSsyv-rGdpn2amkKZwmYNkDmb1v8ffzWFIGx1Szq38dcCiYgFMfiZKHUB1TsGO3Y0pCcb9wAtkH+cBcIZBdSbdD+YBfIConGZBwzkuZrOGQHLhlJ0mcuYUGubunkszBDr1rlGIFJBMKGcUBbuEiSLQY3P2fecCYkiSFpbEBgD4CJZwZ7jWtJasMKEQHUDQf8YSBZbZY5Zr0EVWbkpWa9goqzPQtkfniujUhUlRbokurHXIurJZCoprG5EYCBwhlEAgDEG1D1bVgx0NfEA0NNZYH1YtdMExdrIgDNYNepRtbtYGhAjAndfNYGnhkYDmAKHIj7nLOICIaUbeAeVuD1LYEKBRFOixpiBuAMJPX2j+pRE7F0QkR9E7VTcNlTBKg3VWhkxCy+SdDzMIjbuVt1Vxk0YUj7m-zOCwTQGTheGKwUgmXYA+SXleAJPvJ+1CzoWgCcDDDOmHdHZsDuAzK5xHZ9BsCYOjRsAeW4Qm07Y+SHxxxJYHY03VLGNnxsEgjUR6NMbXY3az23bC3HbnZ7eKxifgVPecD-QvaHe8Qnf1cNLwDoVoM53axOEKApTgGkknsuNMb7kKRUAMII3RgMC6QXjy1SzXZOE3ZqefZSmHZnYnfQ6vdsHnliG0Gqb9jXe5GQ79g5w6SazKWiTUX5jI9kWA9t1MZMViC7eI89zlFo-CS62AxUWo51PfQ6Xo8uNS2RZA-0PhjmDpwLyLjsHcGcSNYkAUMaYzhqC8FHaGG3iuWQ6UBqAzA01w-w7vablJdeps0VzWFMA2E5DHkY9WB7G4Ek8dHbi1xQbzvTpiTDmycE6ERs9oF4Ac9DjY4wvc6RPqIyb4WE++b3f86c4wX5RfWi5I+LjeDCzi4I+LxagS5SgZwMzFjXcYG3rhgMxTuarAEK-SbkCXkiu0E5DrmvFvBBcI4y+KAC9CaIaB1y6mi7fy5IhcAYDDEqipSm2K+mSSba4xxxhs5MToEy7AHVSDTkDy8QYW7lWG-5n5SDWOdfhtxE7r2zs4Yh0eoJYEZLpZTLrzVxmbF-YpD4A49A3ug47FjzaTxzCe4+Vxb3Av3gC4DNRGa3i4BfXmqBXwNBSSJgGeZbvWb0hccU4IDEGBiVsXxiD-Th45m2gVqWexI7Ku+EngIUXumGM-bNQB7khe+ycB8x94Gx7420fzrEYg20b0x-tBSEJJLNASNVWJ6gY5lmvR4-L24lKJKB-jT6e1RldOHJ5c9IFMt+7lBtRClZ-iL4DgtMt4QVEDYRcdH4kGm6GoD6iaFmbAfumtj+5RCDhZqHiXgwvYdl6aC-skKbvW7WiVVcDm4Pj9inJ++Iq9R14ELaaypOiIEHBDE9qO5YLK+GqPROcbpZQ+TK9jSUYYGy+XCp1MED-D+uPeCboVZuCJQJTp3nkoyp2z4j7SpIuj5RWIC8Hj47sG7KGT-0KzmDiVACkr+Em0el9L5zvk5dXQD4DUVuS8LVBIELZ9BLFD8GUfWNeYAoDlW-Y6XRg88H9Eu1DAB1BciAA)

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
- A reactive object `session_choice` corresponding to the `url` value of
  the selected row in the sessions table is supplied to the `restore()`
  method of the `StorageClass` instance.
- Additional information corresponding to the session name entered in a
  text input as well as the current time are saved as part of the
  bookmarkable state snapshot metadata, assembled as a
  [`list()`](https://rdrr.io/r/base/list.html) object with named
  elements for each variable.

### `app.R`

``` r
library(shiny)
library(shinystate)
library(dplyr)
library(DT)
library(rlang)
library(lubridate)

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
```

### `filter_module.R`

``` r
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
    available_fields <- names(eval_clean(data_expr())) %>%
      base::setdiff(names(filter_fields))

    showModal(modalDialog(
      title = "Add filter",

      radioButtons(ns("filter_field"), "Field to filter", available_fields),

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
      fieldname = fieldname
    )

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
      param <- input[[filter[["inputId"]]]]
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
    ui = sliderInput(
      id,
      fieldname,
      min = min(data),
      max = max(data),
      value = range(data)
    ),
    filterExpr = function(x, param) {
      expr(!!x >= !!param[1] & !!x <= !!param[2])
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
      if (length(param) == 0) {
        NULL
      } else {
        expr(!!x %in% !!param)
      }
    }
  )
}

createFilter.POSIXt <- createFilter.numeric
```

### `select_module.R`

``` r
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
      selectInput(
        ns("group_by"),
        "Group by",
        choices = vars(),
        multiple = TRUE
      ),
      selectInput(
        ns("operation"),
        "Summary operation",
        c("mean", "sum", "count")
      ),
      selectInput(
        ns("aggregate"),
        "Summary value",
        choices = vars(),
        multiple = TRUE
      )
    )
  })

  reactive({
    result_expr <- data_expr()
    if (length(input$group_by) > 0) {
      result_expr <- expr(!!result_expr %>% group_by(!!!syms(input$group_by)))
    }
    if (length(input$aggregate) > 0) {
      op <- switch(
        input$operation,
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
