library(shiny)
library(shinyjs)
library(shinydashboard)
library(plotly)

ui <- fluidPage(
  useShinyjs(),
  theme = "somestyle.css",
  includeScript(path = "https://unpkg.com/rough-viz@1.0.6"),
  dashboardPage(
      dashboardHeader(title = "Fantasimulatore \u{26BD}", titleWidth = 350),
      dashboardSidebar(
        width = 350,
        div(id="controls",
          fluidRow(
            column(width = 9,
                   textInput(inputId = 'file2', label = 'Recupera calendario da:', value = "", width = "100%", placeholder = "Inserisci nome della tua lega"),
                   style='padding-left:0px;padding-right:0px'
            ),
            column(width = 2,
                   br(),
                   actionButton(inputId = "runFile2", label = "", width = NULL, icon = icon("search")),
                   style='margin-top:10px;padding-left:0px'
            ),
            style='margin:0%;'
          ),
          fileInput(inputId =  "file1", "Carica il calendario della competizione",width = "95%", multiple = FALSE),
          actionButton(inputId = "run", label = "Simula", width = "87%", icon = icon("brain")),
          checkboxInput(inputId = "advanced", "Opzioni Avanzate", value = FALSE, width = NULL)
        ),
        div(id="advancedOptions", style="display: none;",
          hr(style="border-top-color:rgba(0,0,0,.1"),
          sliderInput("nrep", "Numero di simulazioni:",width = "95%",
                      min = 5, max = 1000,
                      value = 500),
          actionButton(inputId = "quickrun", label = "Imposta simulazione veloce", width = "87%", style = "background-color:orange")
        ),
        div(id="teamsPanel", style="display: none;",
          hr(style="border-top-color:rgba(0,0,0,.1"),
          selectInput(inputId = 'teams', label = 'Squadre', choices = NULL, width = "95%"),
          fluidRow(
            column(width = 6,
                   textInput(inputId = 'currPos', label = 'Piazzamento attuale', value = "", width = "95%", placeholder = NULL),
                   style='margin:0%;padding-left:0px;padding-right:0px'
            ),
            column(width = 6,
                   textInput(inputId = 'expePos', label = 'Atteso', value = "", width = "95%", placeholder = NULL),
                   style='margin:0%;padding-left:0px;padding-right:0px'
            ),
            style='margin:0%;padding-left:0px;padding-right:0px'
          )
        ),
        hr(style="border-top-color:rgba(0,0,0,.1"),
        div(p(style="user-select: none; color: #C2BCB7; text-align:center","\u{00A9}",
              tags$u(a("Detsutut - 2020",href="https://github.com/detsutut"))))
      ),
      dashboardBody(
        div(id= "loading", class = "loading",'Loading&#8230;'),
        div(id="introContainer",
          br(),
          img(src="info.png",width="45%",style="display: block;margin-left: 0px;"),
          br(),
          br(),
          img(src="example3.png",width="97%",style="display: block;margin-left: auto;margin-right: auto;")
        ),
        div(id="chartContainer",
          fluidRow(
            column(width = 5, div(id="vizPie")),
            column(width = 5, div(id="vizStacked")),
            style='margin:0%;'
          ),
          br(),
          br(),
          div(id="vizBar",style="display: block;margin-left: auto;margin-right: auto; width: 99%")
        )
      )
    )
)
