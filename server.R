#Logic
library(shiny)
library(shinyjs)
library(readxl)
library(dplyr)
library(gtools)
library(pbapply)
library(ggplot2)
library(shinydashboard)
library(gridExtra)
library(plotly)
source("./utilities.R")

#Code outside the server function run once per R session
#Everything inside server function is different for each single user

palette(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
          "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"))


#here we assemble inputs and outputs
server <- function(input, output, session) {
  #what is evaluated inside reactive is passed to each caller at the same time.
  #we access the same outcome from different render function

  perms = NULL
  weeks = NULL
  goals = NULL
  predicted = NULL
  actual = NULL
  hide('loading')

  selectedData <- reactive({
    iris[, c(input$xcol, input$ycol)]
  })

  observeEvent(input$teams, {
    updateTextInput(session,"currPos",value=as.character(actual[input$teams]))
    updateTextInput(session,"expePos",value=as.character(predicted[input$teams]))
    if(input$expePos!=""){
      color = ifelse(actual[input$teams]<=predicted[input$teams],"DarkSeaGreen","LightCoral")
      runjs(paste0("document.getElementById('expePos').style.backgroundColor = '", color ,"'"))
    }
  })

  observeEvent(input$nrep, {
    if(input$nrep>1000){
    showNotification("ATTENZIONE! Un numero alto di simulazioni fornisce stime attendibili ma richiede molto tempo per essere calcolato. Scegli un numero basso oppure...mettiti comodo!", type = "warning")
    }
  })


  observeEvent(input$quickrun, {
    updateSliderInput(session,"nrep",value=100)
  })

  observeEvent(input$runFile2, {
    showModal(modalDialog(
      title = "Scarica file calendario",
      p("Scarri la pagina e cerca il pulsante",img(src="button.png",width="18%"), "per scaricare il calendario della tua lega."),
      tags$iframe(src=paste0("https://leghe.fantacalcio.it/",tolower(gsub(" ","-",input$file2)),"/calendario"), height=400, width=550)
    ))
  })

  observeEvent(input$file1, {
    req(input$file1)
    data = read_excel(input$file1$datapath)
    weeks <<- parse.weeks(data)
    names = team.names(weeks)
    goals <<- calculateGoals(weeks)
    actual <<-rank(-calculateFinal(goals,getActualRounds(weeks)),ties.method = "min")
    withProgress(message = 'Loading', value = 0, {
      perms <<- getPerms(names)
    })
    updateSliderInput(session,"nrep",max = nrow(perms))
    updateSelectInput(session, "teams", choices = names)
  })


  #' Hide the loading splashscreen
  #'
  #' @param modal the splashscreen to hide is on a modal
  #' @param query the splashscreen to hide is on a query panel
  hideLoading = function(){
    hideElement(id = 'loading')
  }

  #' Show the loading splashscreen
  #'
  #' @param modal show the loading splashscreen on a modal
  #' @param query show the loading splashscreen on the query panel
  showLoading = function(){
    showElement(id = 'loading')
  }


  observeEvent(input$run, {
    showLoading()
    withProgress(message = 'Loading', value = 0, {
    simul <- pbapply(perms[sample(1:nrow(perms), input$nrep, replace=FALSE),],1,function(row){
      rounds = getRounds(row,length(weeks))
      incProgress(1/input$nrep, detail = paste("Simulazione campionati..."))
      return(rank(-calculateFinal(goals,rounds),ties.method = "min"))
    })
    })

    predicted <<- rank(apply(simul, 1, mean),ties.method = "min")

    updateTextInput(session,"expePos",value=as.character(predicted[input$teams]))

    withProgress(message = 'Carico grafici...', value = 0, {
    piazz = sort((rowSums(simul)))

    podiums = na.replace(t(apply(simul,1,function(x){table(x)[c("1","2","3")]})),0)
    strlist = c()
    for(i in 1:nrow(podiums)){
    strlist = c(strlist, paste0("team:'",row.names(podiums)[i],"', First:",podiums[i,1],
           ", Second:",podiums[i,2],", Third:",podiums[i,3],collapse = ""))
    }
    s= paste0("{",strlist,"},",collapse = "")
    s= substr(s,1,nchar(s)-1)

    runjs(paste0("
      $('#vizStacked').empty();
      new roughViz.StackedBar(
        {
                element: '#vizStacked',
                data: [",s,"],
                labels: 'team',
                title: 'Piazzamenti Sul Podio',
                width: window.innerWidth / 3,
                strokeWidth: 2,
                roughness: 3,
                fillStyle: 'zigzag',
                fillWeight: 1.5,
                titleFontSize: '3rem',
                tooltipFontSize: '2rem',
                axisFontSize: '2rem'
          }
          );
    "))

    mean = apply(simul, 1, mean)
    sd = apply(simul, 1, sd)
    names = names(sd)
    df = data.frame(names,mean,sd)
    df$actual = actual[names]

    runjs(paste0("document.getElementById('introContainer').style.display = 'none'"))

    t= paste0("'",df$names,"',",collapse = "")
    t= substr(t,1,nchar(t)-1)

    v= paste0(df$mean,",",collapse = "")
    v= substr(v,1,nchar(v)-1)

    runjs(paste0("
      $('#vizBar').empty();
      new roughViz.Bar(
        {
                element: '#vizBar',
                data: {
                labels: [",t,"],
                values: [",v,"]
                },
                title: 'Posizionamento Medio',
                width: window.innerWidth/1.5,
                roughness: 3,
                stroke: 'skyblue',
                strokeWidth: 2,
                fillStyle: 'zigzag',
                fillWeight: 1.5,
                titleFontSize: '3rem',
                tooltipFontSize: '2rem',
                axisFontSize: '2rem'
}
          );
    "))

    output$plot <- renderPlotly({
      plot_ly(df, x = ~names, y = ~mean, type = 'bar', name = 'Expected')%>%
        add_trace(y = ~actual, name = 'Actual') %>%
        layout(yaxis = list(title = 'Posizionamento'),xaxis = list(title = 'Squadre'), barmode = 'group',
               plot_bgcolor  = "rgba(0, 0, 0, 0)", paper_bgcolor = "rgba(0, 0, 0, 0)")
    })
    incProgress(0.5, detail = 'Carico grafici...')

      #percentuale di vittorie
      position = 1
      count = table(names(which(simul==position,arr.ind = TRUE)[,1]))
      labels = paste(names(count), "\n", (count/input$nrep)*100,"%", sep="")

      df <- data.frame(count)
      names(df) <- c("teams","freq")
      df$labels = paste(round((df$freq/input$nrep)*100,1),"%",sep = "")
      df <- df %>%
        arrange(desc(teams)) %>%
        mutate(lab.ypos = cumsum(freq) - 0.5*freq)
      df <- df %>%
        mutate(end = 2 * pi * cumsum(freq)/sum(freq),
               start = lag(end, default = 0),
               middle = 0.5 * (start + end),
               hjust = ifelse(middle > pi, 1, 0),
               vjust = ifelse(middle < pi/2 | middle > 3 * pi/2, 0, 1))

    incProgress(0.25, detail = 'Carico grafici...')

    t= paste0("'",df$teams,"',",collapse = "")
    t= substr(t,1,nchar(t)-1)

    v= paste0(df$freq,",",collapse = "")
    v= substr(v,1,nchar(v)-1)

    runjs(paste0("
      $('#vizPie').empty();
      new roughViz.Pie(
        {
                element: '#vizPie',
                data: {
                labels: [",t,"],
                values: [",v,"]
                },
                title: 'Vittorie Campionato',
                width: window.innerWidth / 3,
                strokeWidth: 2,
                roughness: 3,
                fillStyle: 'zigzag',
                fillWeight: 1.5,
                titleFontSize: '3rem',
                tooltipFontSize: '2rem'
          }
          );
    "))

    output$plot2 <- renderPlotly({
      plot_ly(df, labels = ~teams, values = ~freq, type = 'pie') %>%
        layout(title = '',
               xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
               yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
               plot_bgcolor  = "rgba(0, 0, 0, 0)", paper_bgcolor = "rgba(0, 0, 0, 0)")
    })

    incProgress(0.25, detail = 'Carico grafici...')
    })

    color = ifelse(input$currPos<=input$expePos,"DarkSeaGreen","LightCoral")
    runjs(paste0("document.getElementById('expePos').style.backgroundColor = '", color ,"'"))
    hideLoading()
})
}
