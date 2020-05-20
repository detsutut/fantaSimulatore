#User Interface
library(shiny)
library(shinyjs)
library(shinydashboard)
library(plotly)

#here we declare graphical components in terms of inputs and outputs
ui <- fluidPage(
  useShinyjs(),
  theme = "somestyle.css",
  dashboardPage(
      dashboardHeader(title = "Fantasimulatore \u{26BD}",
                      titleWidth = 350),
      dashboardSidebar(
        width = 350,
        fluidRow(
          column(width = 9,
                 textInput(inputId = 'file2', label = 'Recupera da:', value = "", width = "100%", placeholder = "Nome-della-lega"),
                 style='padding-left:0px;padding-right:0px'
          ),
          column(width = 2, 
                 br(),
                 actionButton(inputId = "runFile2", label = "", width = NULL, icon = icon("search")),
                 style='margin-top:10px;padding-left:0px'
          ),
          style='margin:0%;'
        ),
        h6("oppure", style = "text-align: center"),
        fileInput(inputId =  "file1", "Carica file calendario",width = "95%",
                  multiple = FALSE),
        hr(),
        sliderInput("nrep", "Numero di simulazioni:",width = "95%",
                    min = 5, max = 1000,
                    value = 500),
        actionButton(inputId = "quickrun", label = "Imposta simulazione veloce", width = "87%", style = "background-color:orange"),
        actionButton(inputId = "run", label = "Simula", width = "87%", icon = icon("brain")),
        hr(),
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
      dashboardBody(
        plotlyOutput("plot"),
        plotlyOutput("plot2")
      )
    )
)