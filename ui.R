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
        fileInput(inputId =  "file1", "Carica il calendario della competizione",width = "95%",
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
        ),
        hr(style="border-top-color:rgba(0,0,0,.1"),
        div(p(style="user-select: none; color: #C2BCB7; text-align:center","\u{00A9}",
              tags$u(a("Detsutut - 2020",href="https://github.com/detsutut"))))
      ),
      dashboardBody(
        div(id="introContainer", style="background-image: url(texture.jpg); background-repeat: repeat;",
        div(id="introduction",
            div(id ="introText", style="text-align: center; padding: 10px 10px 10px 10px;",
            h4("Il tuo tridente da sogno ti ha lasciato fuori dal podio?"),
            h4("La tua media di 4 gol a partita non ha impedito al tuo dream team di subire più gol del Benevento?"),
            h4("Hai comprato Higuain nell'anno del record e sei riuscito comunque ad arrivare secondo?"),
            br(),
            h4("Scopri quanto sei sfigato con il ",tags$b("Fantasimulatore!"))
            )
        ),
        br(),
        div(id="introduction2",
            div(id ="introText2", style="text-align: center; padding: 10px 10px 10px 10px;",
                h5("Per vincere il fantacalcio serve un mix di bravura, pianificazione, talent scouting e...fortuna. Tanta fortuna."),
                h5("Costruire la rosa più forte possibile talvolta può non essere sufficiente di fronte ad un calendario poco favorevole, dove roboanti pareggi 4-4 si affiancano a risicate vittorie per 1-0."),
                h5("Spesso, infatti, la disposizione delle squadre ai blocchi di partenza quando si genera il calendario del campionato si rivela fondamentale per la classifica finale, più degli effettivi risultati ottenuti sul campo."),
                br(),
                h5("Lo scopo di ",tags$b("Fantasimulatore"),"è quello di rimuovere il Fattore C - dove C non sta per Calendario - dal fantacalcio andando a calcolare tutti i possibili sorteggi di calendario e simulando l'esito del campionato per ciascuno di essi.")
            )
        ),
        br(),
        div(id="introduction3", style="align: center;",
            img(src="example3.png",width="90%",style="  display: block;margin-left: auto;margin-right: auto;")
        )
        ),
        plotlyOutput("plot"),
        plotlyOutput("plot2")
      )
    )
)
