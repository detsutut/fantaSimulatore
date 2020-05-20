parse.weeks = function(raw_data){
  nteams = 2*(which(raw_data=="3\U00AA Giornata lega")-which(raw_data=="1\U00AA Giornata lega")-1)
  offset.col = 6
  offset.row = nteams/2+1
  offset.beginning = 4
  week.height = nteams/2-1
  week.width = 4
  weeks = list()
  for(i in 0:((nrow(raw_data)-2)/((nteams/2)+1)-1)){
    week = raw_data[(offset.beginning+offset.row*i):(offset.beginning+offset.row*i+week.height),1:week.width]
    names(week) = c("team1","pts1","pts2","team2")
    week$pts1 = as.numeric(week$pts1)
    week$pts2 = as.numeric(week$pts2)
    weeks = append(weeks,list(week))
    week = raw_data[(offset.beginning+offset.row*i):(offset.beginning+offset.row*i+week.height),(1+offset.col):(week.width+offset.col)]
    names(week) = c("team1","pts1","pts2","team2")
    week$pts1 = as.numeric(week$pts1)
    week$pts2 = as.numeric(week$pts2)
    weeks = append(weeks,list(week))
  }
  return(weeks)
}

team.names = function(weeks){
  return(c(weeks[[1]]$team1,weeks[[1]]$team2))
}

calculateGoals = function(weeks){
  scores = matrix(0,nrow = length((weeks)),ncol = length(team.names(weeks)))
  colnames(scores) = team.names(weeks)
  for(i in 1:length(weeks)){
    week = weeks[[i]]
    weekResults = lapply(getMatches(week), calculateResults)
    scores[i,] = updateScores(scores[i,],weekResults)
  }
  return(scores)
}

calculateResults = function(match){
  goal1 = floor((as.numeric(match["pts1"])-60)/6)
  goal2 = floor((as.numeric(match["pts2"])-60)/6)
  if(goal1<0) goal1 = 0
  if(goal2<0) goal2 = 0
  results = c(goal1,goal2)
  names(results) = c(match["team1"],match["team2"])
  return(results)
}

updateScores = function(scores, results){
  res = unlist(results)
  names(res) = unlist(lapply(names(unlist(results)),function(x){substring(x, 3)}))
  for(r in results){
    scores[names(r)]=scores[names(r)]+r[names(r)]
  }
  return(scores)
}

getMatches = function(week){
  return(suppressWarnings(split(week,row(week))))
}

getRounds = function(teamNames,nrounds){
  teams <- teamNames
  n = length(teams)
  rounds <- list()
  for( i in 1:nrounds){
    round <- 
      data.frame(
        round = i,
        team1 = teams[1:(n/2)], 
        team2 = rev(teams)[1:(n/2)])
    rounds[[i]] <- round
    teams <- c( teams[1],  last(teams), head(teams[-1],-1) ) 
  }
  return(suppressWarnings(bind_rows(rounds)))
}

calculateFinal = function(goals,rounds){
  nrounds = nrow(goals)
  finals = array(0,dim = ncol(goals))
  names(finals)=colnames(goals)
  for(round in 1:nrounds){
    week = rounds[which(rounds$round==round),]
    for(i in 1:nrow(week)) {
      g1 = goals[round,week[i,"team1"]]
      g2 = goals[round,week[i,"team2"]]
      if(g1>g2) finals[week[i,"team1"]] = finals[week[i,"team1"]]+3
      else if (g1<g2) finals[week[i,"team2"]] = finals[week[i,"team2"]]+3
      else{
        finals[week[i,"team2"]] = finals[week[i,"team2"]]+1
        finals[week[i,"team1"]] = finals[week[i,"team1"]]+1
      }
    }
  }
  return(finals)
}

getPerms <- function(x) {
  incProgress(0.75, detail = paste("Calcolo permutazioni..."))
  Sys.sleep(1)
  incProgress(0.15, detail = paste(factorial(length(x))/1000,"mila permutazioni da calcolare...potrebbe volerci un po'!"))
  p = permutations(n=length(x),r=length(x),v=x)
  incProgress(0.10, detail = paste("Fine!"))
  return(p)
}

getActualRounds <- function(weeks){
  rounds = data.frame()
  for(i in 1:length(weeks)){
    week = weeks[[i]]
    round = data.frame(cbind(rep(i,length(week$team1)),week$team1,week$team2),stringsAsFactors = FALSE)
    names(round) = c("round","team1","team2")
    round$round = as.integer(round$round)
    rounds <- rbind(rounds,round)
  }
  return(rounds)
}
