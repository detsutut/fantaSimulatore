library("readxl")
library(dplyr)
library(pbapply)
library(ggplot2)
data <- read_excel(file.choose())

parse.weeks = function(raw_data){
  nteams = 2*(which(raw_data=="3ª Giornata lega")-which(raw_data=="1ª Giornata lega")-1)
  offset.col = 6
  offset.row = nteams/2+1
  offset.beginning = 4
  week.height = nteams/2-1
  week.width = 4
  weeks = list()
  for(i in 0:((nrow(raw_data)-2)/((nteams/2)+1)-1)){
    week = data[(offset.beginning+offset.row*i):(offset.beginning+offset.row*i+week.height),1:week.width]
    names(week) = c("team1","pts1","pts2","team2")
    week$pts1 = as.numeric(week$pts1)
    week$pts2 = as.numeric(week$pts2)
    weeks = append(weeks,list(week))
    week = data[(offset.beginning+offset.row*i):(offset.beginning+offset.row*i+week.height),(1+offset.col):(week.width+offset.col)]
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
  if (length(x) == 1) {
    return(x)
  }
  else {
    res <- matrix(nrow = 0, ncol = length(x))
    for (i in seq_along(x)) {
      res <- rbind(res, cbind(x[i], Recall(x[-i])))
    }
    return(res)
  }
}


#============================================

weeks = parse.weeks(data)
names = team.names(weeks)
goals = calculateGoals(weeks)
perms = getPerms(names)
nrep = 1000
a = pbapply(perms[sample(1:nrow(perms), nrep, replace=FALSE),],1,function(row){
  rounds = getRounds(row,length(weeks))
  return(rank(-calculateFinal(goals,rounds),ties.method = "min"))
})

#piazzamento medio
piazz = sort((rowSums(a)))

mean = apply(a, 1, mean)
sd = apply(a, 1, sd)
names = names(sd)
df = data.frame(names,mean,sd)

plot1 = ggplot(df) +
  geom_bar( aes(x=names, y=mean), stat="identity", fill="skyblue", alpha=0.7) +
  ggtitle("Indice di scarsezza") +
  xlab("Squadre") + ylab("Scarsezza")+
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5))+
  geom_errorbar( aes(x=names, ymin=mean-sd, ymax=mean+sd), width=0.4, colour="orange", alpha=0.9, size=1.3)

#percentuale di vittorie
position = 1
count = table(names(which(a==position,arr.ind = TRUE)[,1]))
labels = paste(names(count), "\n", (count/nrep)*100,"%", sep="")

df <- data.frame(count)
names(df) <- c("teams","freq")
df$labels = paste(round((df$freq/nrep)*100,1),"%",sep = "")
df <- df %>%
   arrange(desc(teams)) %>%
   mutate(lab.ypos = cumsum(freq) - 0.5*freq)
df <- df %>% 
  mutate(end = 2 * pi * cumsum(freq)/sum(freq),
         start = lag(end, default = 0),
         middle = 0.5 * (start + end),
         hjust = ifelse(middle > pi, 1, 0),
         vjust = ifelse(middle < pi/2 | middle > 3 * pi/2, 0, 1))

plot2 <- ggplot(df, aes(x = 2, y = freq, fill = teams)) +
  geom_bar(stat = "identity", color = "white") +
  coord_polar(theta = "y", start = 0)+
  geom_text(aes(y = lab.ypos, label = paste(teams,"\n (",df$labels,")",sep = "")))+
  ggtitle("Percentuale Vittorie") +
  theme_void()+
  theme(legend.position = "none", plot.title = element_text(hjust = 0.5))+
  xlim(0.5, 2.5)

grid.arrange(plot1, plot2, nrow = 1,top = "Statistiche Lega")
 