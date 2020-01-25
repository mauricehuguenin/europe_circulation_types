# Purpose: Plotting boxplots of the past (1988-2017) frequencies of all ten circulation types
#          as well as the absolute change in the frequency for the future (2070-2099) time period

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
#           Frequency and Persistence of Central European Circulation Types                     #
# My Name:  Maurice Huguenin-Virchaux                                                           #
# My Email: hmaurice@student.ethz.ch                                                            #
# Date:     16.10.2018, 11:59 CET                                                               #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# library(latex2exp) # package for LaTeX font in plots
library(base)
library(ggplot2) # for plotting
library(reshape)
library(RColorBrewer)
# define variables
past            <- c(1988, 2017) # 30 years
future          <- c(2070, 2099) # 30 years
nyears          <- future[2]-future[1] + 1 # number of years
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# choose classification method
#method <- 'Z500' # or 
method <- 'PSL'
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ preamble and data load in ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

if (method == 'Z500'){
  classification <- 'wkwtg1d0'
} else if (method == 'PSL'){
  classification <- 'wkwtp1d0'
}
cesm_data <- paste('E:/Praktikum MeteoSchweiz/cost_files/cost_CESM12-LE_historical_1960-2099_',method,'.dat', sep="")
# that's the data with all ensembles that work
cmip5_data <- paste('E:/Praktikum MeteoSchweiz/cost_files/cost_CMIP5_historical_rcp85_models_that_work_',method,'.dat',sep="")

# adapting ggplot theme to suit my needs
theme_set(theme_bw() + 
            theme(axis.line = element_line(colour = "black"),
                  panel.grid.major.y = element_line(colour = "grey"),
                  panel.grid.major = element_line(size = 0.1),
                  panel.grid.major.x = element_blank(),
                  panel.grid.minor = element_blank(),
                  panel.border = element_blank(),
                  legend.title = element_blank(),
                  plot.title = element_text(size = 20),
                  axis.title.x = element_text(size = 20),
                  axis.title.y = element_text(size = 20),
                  legend.text=element_text(size = 20),
                  legend.position = "bottom",
                  panel.background = element_blank(), 
                  axis.text.x = element_text(size= 17), # set size of labels relative to
                  # default which is 11
                  axis.text.y = element_text(size= 17)))

# colour bar 
# myblue = rgb(.19, .21, .58) # blue colour from my msc thesis
antarctica <- c('#960011', '#A50021', '#C80028', 
                '#D8152F', '#F72735', '#FF3D3D', '#FF7856', 
                '#FFAC75', '#FFD699', '#FFF1BC', '#BCF9FF', 
                '#99EAFF', '#75D3FF', '#56B0FF', '#3D87FF', 
                '#2857FF', '#181CF7', '#1E00E6', '#2400D8', 
                '#2D00C8')
Reds <- brewer.pal(9, "Reds")      # red colour scale with 9 entries
Blues <- brewer.pal(9, "Blues")    # blue colour scale with 9 entries

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in reanalysis data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# read in table with above specified years of data
df_obs <- read.table("E:/Praktikum MeteoSchweiz/cost_files/WTC_MCH_19570901-20180831.dat", 
                     header=TRUE, skip = 0) # OBS first
df_obs <- df_obs[which(df_obs[,2]>=paste(past[1],"0101",sep='') & 
                       df_obs[,2]<=paste(past[2],"1231",sep='')),]
df_obs <- df_obs[, c('time', classification)] # only select time and GWT10 classification

# rewrite date to be in format YYYY-MM-DD
df_obs[["time"]] <- as.Date(as.character(df_obs[["time"]]),format="%Y%m%d")
year <- format(df_obs$time, "%Y")

# insert season vector as third column
d <- as.Date(cut(as.Date(df_obs$time, "%m/%d/%Y"), "month")) + 32
df_obs$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                        labels = c("4", "1", "2", "3"))
rm(d) # rm = remove, just like in bash


# initiating data.frame where I put in my stuff
count_ERA <- data.frame(matrix(NA, nrow = 10, ncol = 5))
count_ERA[,1] <- 1:10
colnames(count_ERA) <- c("type", "spring_ERA", "summer_ERA", "autumn_ERA", "winter_ERA") # change name of column
  
for (i in 1:10){ # loop over all weather_patterns
  for (s in 1:4){ # loop over all seasons
    df_obs_loop <- df_obs[which(df_obs[,3] == s & df_obs[,2] == i),] # subset data for each season
    count_ERA[i,s+1] <- table(df_obs_loop[,2]) / nyears # divide by number of years to get the mean seasonal 
  }
}
rm(df_obs, df_obs_loop)

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CESM ensemble data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# read in table with header
df_ens <- read.table(cesm_data, header=FALSE, skip=0)
df_ens[is.na(df_ens)] <- 0 # set NA to zero
# join the three columns and create the date vector
df_ens$V1 <- as.Date(with(df_ens, paste(V1, V2, V3,sep="-")), "%Y-%m-%d")
df_ens$V2 <- NULL
df_ens$V3 <- NULL
features <- c(sprintf("e%02d", seq(1,84))) # label each ensemble column numerically with suffix 'e',
# e.g. 'e01', 'e02', 'e03', ...

colnames(df_ens)[2:85]= features # rename column names
colnames(df_ens)[1] <- "time" # change name of column

for (period in 1:2){ # loop over past (1980--2008) and future (2061--2099) periods
  if(period == 1){
    start_year <- past[1]; end_year <- past[2] # period 1st Jan 1980 - 31st Dec 2017
  } else if(period == 2){
    start_year <- future[1]; end_year <- future[2] # period 1st Jan 2062 - 31st Dec 2099
  } 
  # initiating data.frame where I put in my stuff
  count <- data.frame(matrix(NA, nrow = 10, ncol = 5))
  count[,1] <- 1:10
  colnames(count) <- c("type", "spring_CESM", "summer_CESM", "autumn_CESM", "winter_CESM") # change name of column
  
  # only select values from specific time period 
  df_ens_loop <- df_ens[which(df_ens[,1]>=paste(start_year,"-01-01", sep = "") & 
                                df_ens[,1]<=paste(end_year,"-01-01", sep = "")),]
  
  # add season column
  d <- as.Date(cut(as.Date(df_ens_loop$time, "%m/%d/%Y"), "month")) + 32
  df_ens_loop$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                               labels = c("4", "1", "2", "3"))
  rm(d) # rm = remove, just like in bash
  
  for (i in 1:84){ # loop over all ensembles
    old <- Sys.time() # get start time
    for (s in 1:4){ # loop over season
      t <- df_ens_loop[which(df_ens_loop[,86] == s),c(1,i+1,86)] # subset data
      t <- t[which(t[,2] >= 1),] # remove those days which have a 0 as entry, i.e. are leap days
      t <- table(t[,2]) / nyears # divide by number of years to get the mean seasonal 
      t <- as.data.frame(t) # format as a data.frame

      for (m in 1:nrow(t)){ # loop over all weather patterns in the subset
        count[m,s+1] <- t[m,2]
      }
    }
    # continualy expand data frame so it includes all 84 ensemble members in the end
    if (i == 1){
      count_CESM <- count
    } else {
      count_CESM <- rbind(count_CESM, count)
    }
    # print elapsed time
    new <- Sys.time() - old # calculate difference
    print(new) # print in nice format
  } # end of for loop over all ensemble members
  
  assign(paste("count_CESM",period,sep="_"), count_CESM)
  rm(count, count_CESM)
} # end of loop over past (1) and future (2) period
    
######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CMIP5 ensemble data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# read in table with header
df_ens <- read.table(cmip5_data, header=FALSE, skip=0)
df_ens[is.na(df_ens)] <- 0 # set NA to zero
# join the three columns and create the date vector
df_ens$V1 <- as.Date(with(df_ens, paste(V1, V2, V3,sep="-")), "%Y-%m-%d")
df_ens$V2 <- NULL
df_ens$V3 <- NULL
features <- c(sprintf("e%02d", seq(1,84))) # label each ensemble column numerically with suffix 'e',
# e.g. 'e01', 'e02', 'e03', ...

colnames(df_ens)[2:ncol(df_ens)]= features[1:ncol(df_ens)-1] # rename column names
colnames(df_ens)[1] <- "time" # change name of column

for (period in 1:2){ # loop over past (1980--2008) and future (2061--2099) periods
  if(period == 1){
    start_year <- past[1]; end_year <- past[2] # period 1st Jan 1980 - 31st Dec 2017
  } else if(period == 2){
    start_year <- future[1]; end_year <- future[2] # period 1st Jan 2062 - 31st Dec 2099
  } 
  # initiating data.frame where I put in my stuff
  count <- data.frame(matrix(NA, nrow = 10, ncol = 5))
  count[,1] <- 1:10
  colnames(count) <- c("type", "spring_CESM", "summer_CESM", "autumn_CESM", "winter_CESM") # change name of column
  
  # only select values from specific time period 
  df_ens_loop <- df_ens[which(df_ens[,1]>=paste(start_year,"-01-01", sep = "") & 
                                df_ens[,1]<=paste(end_year,"-01-01", sep = "")),]
  
  # add season column
  d <- as.Date(cut(as.Date(df_ens_loop$time, "%m/%d/%Y"), "month")) + 32
  df_ens_loop$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                               labels = c("4", "1", "2", "3"))
  rm(d) # rm = remove, just like in bash
  
  # find how many columns the dataframe has, i.e. it is dependent on how many ensembles I have
  total <- ncol(df_ens_loop)
  
  for (i in 1:(total-2)){ # loop over all ensembles
    old <- Sys.time() # get start time
    for (s in 1:4){ # loop over season
      t <- df_ens_loop[which(df_ens_loop[,total] == s),c(1,i+1,total)] # subset data
      t <- t[which(t[,2] >= 1),] # remove those days which have a 0 as entry, i.e. are leap days
      t <- table(t[,2]) / nyears # divide by number of years to get the mean seasonal 
      t <- as.data.frame(t) # format as a data.frame
      
      for (m in 1:nrow(t)){ # loop over all weather patterns in the subset
        count[m,s+1] <- t[m,2]
      }
    }
    # continualy expand data frame so it includes all 84 ensemble members in the end
    if (i == 1){
      count_CMIP5 <- count
    } else {
      count_CMIP5 <- rbind(count_CMIP5, count)
    }
    # print elapsed time
    new <- Sys.time() - old # calculate difference
    print(new) # print in nice format
  } # end of for loop over all ensemble members
  
  assign(paste("count_CMIP5",period,sep="_"), count_CMIP5)
  rm(count, count_CMIP5)
} # end of loop over past (1) and future (2) period


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine seasonal frequency past period ~~~~~~~~~~~~ ########

library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
library(reshape)
b <-  rep(antarctica[c(1,4,8)],10)

for (s in 1:4){ # loop over the four seasons; assign correct data each loop iteration
  # for plotting I need: CESM data from past period, Era data from past period
  ERA <- count_ERA[,c(1,s+1)]    # subset data for that specific season
                                 # i.e. select all rows from 1st and (s+1)th column
  colnames(ERA)[2] <- "value"

  CESM <- count_CESM_1[,c(1,s+1)]
  CESM[,3] <- 1 # insert new column with data for interaction
  colnames(CESM)[c(2,3)] <- c("value", "ensemble_type")

  mean_CESM <- c(1:10)
  for (i in 1:10){    mean_CESM[i] <- mean(CESM[CESM[,1]==i,2])  }
  CMIP5<- count_CMIP5_1[,c(1,s+1)]
  CMIP5[,3] <- 2 # insert new column with data for interaction
  colnames(CMIP5)[c(2,3)] <- c("value", "ensemble_type")
  
  mean_CMIP5 <- c(1:10)
  for (i in 1:10){    mean_CMIP5[i] <- mean(CMIP5[CMIP5[,1]==i,2])  }
  
  # merge data for boxplot interaction
  all_model <- rbind(CESM, CMIP5)
  
  # calculate frequency of rare types, i.e. from type 5 onward
  # NE, E, SE, S, C and A
  rare <- round(sum(ERA[5:10,2]) / (sum(ERA[,2])/100),1) 
  
  # initialise title
  if (s == 1){ 
    title <- "a) Spring"; xlabel <- NULL; ylabel <- NULL; rare_number <- rare
    } else if (s == 2){
      title <- "b) Summer";xlabel <- NULL; ylabel <- NULL; rare_number <- rare
    } else if (s == 3){
      title <- "c) Autumn"; xlabel <- "Circulation Type"; ylabel <- NULL
      rare_number <- rare
    } else if (s == 4){
      title <- "d) Winter"; xlabel <- "Circulation Type"; ylabel <- NULL; rare_number <- rare
    }

cmip_col <- c(rep(antarctica[5],10), rep('#00bb00', 10), rep('#bb00bb', 10), rep('black', 10))
#cmip_col <- rep(c(antarctica[5],'#00bb00','#bb00bb'), 10)

assign(paste("g",s, sep=""), ggplot() +
    # shading of area with rare circulation
    # geom_rect(aes(xmin=4.5, xmax=10.5, ymin=0, ymax=Inf), colour= 'grey', alpha='0.2') + 
    # plot whiskers and error bars
    # stat_boxplot(data = all_model, aes(x=type, y=value, group=type), geom ='errorbar', width = 0.3) + 
    # boxplot from data which has the correct format
    geom_boxplot(data = all_model, aes(x=type, y=value, fill = interaction(type, ensemble_type), 
                                  middle = mean(value)), outlier.shape=1, outlier.size = 1) +
    # black dots where Era40/-Interim is
    #geom_boxplot(data = CMIP5, aes(x=type, y=value, group=type, fill=antarctica[5], middle = mean(value)), outlier.shape=1, outlier.size = 1) +
    # black dots where Era40/-Interim is
    geom_point(data = ERA, aes(x=type, y=value, colour = "black"), size = 3, shape = 16) +
    # replace labels on x-axis
    scale_x_continuous(breaks=seq(1, 10, by = 1),
                      labels=c("W","SW","NW","N","NE","E","SE","S","C","A")) +
    # adjusted scale for y-axis
    scale_y_continuous(breaks = seq(0, 100, by = 5), limits = c(0, 50)) + 
    # labels; no label on x-axis since it's the same as in lower subplot
    labs(x = xlabel, y = ylabel, colour = "grey") +
    # fill in colours and plot legends; then in Microsoft paint adjust legend to middle and so on
    scale_fill_manual(values = c(rep(Blues[4],10), rep(Reds[4], 10)), 
                      label = c('CESM12-LE', 'CMIP5')) + 
    scale_color_manual(values = 'black', 
                       label = c('ERA-40/-Interim'), drop=FALSE) +
    # geom_text(aes(5,42.25,label = paste('less frequent than ',rare[s],'%',sep='')), 
              # color='black', size=5, hjust=0) +
    ggtitle(title)) # adding subtitle
}
  

dev.new()
figure <- ggarrange(g1, g2, g3, g4, ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure,
                left = text_grob("Frequency 1960-2018 [days]", rot=90, size=18))

#print(figure)
# export as .png with specific filename
filename = paste('OBS_CESM12-LE_boxplot_seasonal_frequency_1980-2018_with_differences_', method, '_rev2.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 16, height = 9, units = 'in', res = 300)
dev.off()

# clean up workspace
rm(s, title, xlabel, ylabel, all_model, CESM, CMIP5, ERA, df_ens, 
   df_ens_loop, figure, t, b, cesm_data, end_year, features, future, i, 
   m, new, nyears, old, past, path, period, rare, rare_number, start_year, 
   year, cmip_col, cmip5_data, classification)


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ downscaling CESM, CMIP5 boxplot with mean of past boxplot ~~ ########
# to plot absolute change relative to the past period, downscaling of future data is necessary

# initialise empty mean array
mean_CESM_1 <- data.frame(matrix(NA, nrow = 10, ncol = 5))
mean_CESM_1[,1] <- 1:10
colnames(mean_CESM_1) <- c("type", "spring_CESM_1", "summer_CESM_1", "autumn_CESM_1", "winter_CESM_1") # change name of column

# copy-paste data frame structure for the other data sets
mean_CESM_2 <- mean_CESM_1
mean_CMIP5_1 <- mean_CESM_1 
mean_CMIP5_2 <- mean_CESM_1 


for (s in 1:4){ # loop over the four seasons
  CESM_1 <- count_CESM_1[,c(1,s+1)]; colnames(CESM_1)[2] <- "value" # subset data
  CESM_2 <- count_CESM_2[,c(1,s+1)]; colnames(CESM_2)[2] <- "value" # subset data
  CMIP5_1 <- count_CMIP5_1[,c(1,s+1)]; colnames(CMIP5_1)[2] <- "value" # subset data
  CMIP5_2 <- count_CMIP5_2[,c(1,s+1)]; colnames(CMIP5_2)[2] <- "value" # subset data
  
  # calculate mean of past and future boxplots
  for (l in 1:10){
    # calculate mean for past period to determine how much to scale
    a <- apply(CESM_1[which(CESM_1[,1] == l),],2,mean,na.rm=TRUE)
                                               # 1 calculate mean/median by row
                                               # 2 calculate mean/median by column
    b <- apply(CESM_2[which(CESM_2[,1] == l),],2,mean,na.rm=TRUE)
    c <- apply(CMIP5_1[which(CMIP5_1[,1] == l),],2,mean,na.rm=TRUE)
    d <- apply(CMIP5_2[which(CMIP5_2[,1] == l),],2,mean,na.rm=TRUE)
    # put data into allocated grid cell in data frame
    mean_CESM_1[l,s+1] <- a[2];     mean_CESM_2[l,s+1] <- b[2]
    mean_CMIP5_1[l,s+1] <- c[2];    mean_CMIP5_2[l,s+1] <- d[2]
  } # end of loop over all circulation types
} # end of loop over all season

# repeat mean data frame 84/23 times for easy subtraction
mean_CESM_1 <-mean_CESM_1[rep(1:nrow(mean_CESM_1), 84),]
mean_CMIP5_1 <-mean_CMIP5_1[rep(1:nrow(mean_CMIP5_1), total-2),]

# initialise empty data frame
abs_change_CESM_2 <- data.frame(matrix(NA, nrow = 840, ncol = 5))
abs_change_CESM_2[,1] <- 1:10
colnames(abs_change_CESM_2) <- c("type","spring_CESM_2","summer_CESM_2",
                                 "autumn_CESM_2","winter_CESM_2") # change name of column
abs_change_CMIP5_2 <- data.frame(matrix(NA, nrow = 10*(total-2), ncol = 5))
abs_change_CMIP5_2[,1] <- 1:10
colnames(abs_change_CMIP5_2) <- c("type", "spring_CMIP5_2", "summer_CMIP5_2", "autumn_CMIP5_2", "winter_CMIP5_2") # change name of column

# remove mean of past period from future period to get the absolute change 
# in circulation type frequency
abs_change_CESM_2[,2:5] <- count_CESM_2[,2:5] - mean_CESM_1[,2:5]
abs_change_CMIP5_2[,2:5] <- count_CMIP5_2[,2:5] - mean_CMIP5_1[,2:5]

# clean up workspace
rm(a, b, l, s, CESM_1, CMIP5_1, df_ens, df_ens_loop, t, cesm_data, cmip5_data, 
   i, m, new, old, period, start_year, end_year, classification, year, nyears, 
   future, features, past)

# evaluating absolute ensemble mean change
mean_CESM_diff <- mean_CESM_2 - mean_CESM_1[1:10,]
mean_CMIP5_diff <- mean_CMIP5_2 - mean_CMIP5_1[1:10,]
# again insert the circulation type index in the first column
mean_CESM_diff[,1] <- 1:10; mean_CMIP5_diff[,1] <- 1:10


# relabel the columns
colnames(mean_CESM_diff)[2:5] <- c(1,2,3,4)
mean_CESM_diff[,6] <- 1; colnames(mean_CESM_diff)[6] <- 'ensemble_type'
colnames(mean_CMIP5_diff)[2:5] <- c(1,2,3,4)
mean_CMIP5_diff[,6] <- 2; colnames(mean_CMIP5_diff)[6] <- 'ensemble_type'

a <- melt(mean_CESM_diff, id = c('type', 'ensemble_type'))
b <- melt(mean_CMIP5_diff, id = c('type', 'ensemble_type'))

all_model_mean_future_change <- rbind(a, b); rm(a,b)
colnames(all_model_mean_future_change)[3] <- 'season'

# creating mean data for past period as well
a <- mean_CESM_1[1:10,]; b <- mean_CMIP5_1[1:10,]
# relabel the columns
colnames(a)[2:5] <- c(1,2,3,4); colnames(b)[2:5] <- c(1,2,3,4)
# add ensemble type data
a[,6] <- 1; colnames(a)[6] <- 'ensemble_type'; b[,6] <- 2; colnames(b)[6] <- 'ensemble_type'

a <- melt(a, id = c('type', 'ensemble_type'))
b <- melt(b, id = c('type', 'ensemble_type'))

all_model_mean_past <- rbind(a, b); rm(a,b)
colnames(all_model_mean_past)[3] <- 'season'




######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine abs. & rel. change in seas. frequency ~~~~~ ########
library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
library(reshape)

for (s in 1:4){ # loop over the four seasons; assign correct data each loop iteration
  # for plotting I need: downscaled CESM data
  CESM <- abs_change_CESM_2[,c(1,s+1)];  colnames(CESM)[2] <- "value"
  CESM[,3] <- 1 # insert new column with data for i(CESM)[2] <- "value"
  mean_CESM <- mean_CESM_diff[,c(1,s+1)];  colnames(mean_CESM)[2] <- 'value'
  colnames(CESM)[c(2,3)] <- c("value", "ensemble_type")
  
  CMIP5 <- abs_change_CMIP5_2[,c(1,s+1)];  colnames(CMIP5)[2] <- "value"
  mean_CMIP5 <- mean_CMIP5_diff[,c(1,s+1)];  colnames(mean_CMIP5)[2] <- "value"

  CMIP5[,3] <- 2 # insert new column with data for interaction
  colnames(CMIP5)[c(2,3)] <- c("value", "ensemble_type")
  
  # merge data for boxplot interaction
  all_model <- rbind(CESM, CMIP5)
  
  # initialise title
  if (s == 1){ 
    title <- "a) Spring"
    xlabel <- NULL
    ylabel <- NULL
    reference = NULL
  } else if (s == 2){
    title <- "b) Summer"
    xlabel <- NULL
    ylabel <- NULL
    reference = "Reference period: 1960-2018"
  } else if (s == 3){
    title <- "c) Autumn"
    xlabel <- "Circulation type"
    ylabel <- NULL
    reference = NULL
  } else if (s == 4){
    title <- "d) Winter"
    xlabel <- "Circulation type"
    ylabel <- NULL
    reference = NULL
  }
  assign(paste("h",s, sep=""), ggplot() +
           # plot boxplot
           # interaction between 'type' and 'ensemble_type' to plot both CESM and CMIP5 next to
           # each other
           geom_boxplot(data = all_model, aes(x=type, y=value, fill = interaction(type, ensemble_type), 
                                              middle = mean(value)), outlier.shape=1, outlier.size = 1) +
           # plot horizontal grey line at y-axis = 0
           geom_hline(yintercept=0, color = 'black', size = .2) +
           scale_x_continuous(breaks=seq(1, 10, by = 1),
                              labels=c("W","SW","NW","N","NE","E","SE","S","C","A")) +
           # adjusted scale for y-axis
           scale_y_continuous(breaks = seq(-100, 100, by = 2), limits = c(-7, 10)) + 
           # labels; no label on x-axis since it's the same as in lower subplot
           labs(x = xlabel, y = ylabel, colour = "grey") +
           geom_text(data = mean_CESM, aes(label = paste(value, '%', sep=""), group=type, x=type-0.2, y = -5.5, color=antarctica[5])) +
           geom_text(data = mean_CMIP5, aes(label = paste(value, '%', sep=""), group=type, x=type+0.2, y = -6.5, color='#00bb00')) +
           # fill in colours and plot legends; then in Microsoft paint adjust legend to middle and so on
           scale_fill_manual(values = c(rep('#00bb00',10), rep('#bb00bb', 10)), 
                             label = c('CESM12-LE 2042-2099', 'CMIP5 192042-2099')) + 
           scale_color_manual(values = c('#bb00bb', '#00bb00'), guide = FALSE) +
           ggtitle(title)) # adding subtitle

  
  
}
dev.new()
figure <- ggarrange(h1, h2, h4, h4, ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure, 
                top = text_grob("Reference period: 1960-2018",color='black',hjust = -1),
                left = text_grob("Absolute change in frequency [days]", rot=90, size=18))


#print(figure)
# export as .png with specific filename
filename = paste('OBS_CESM12-LE_boxplot_absolute_seasonal_frequency_change_2062-2100_', method, '_rev3.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 16, height = 9, units = 'in', res = 300)
dev.off()

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine two seasons combined ~~~~~~~~~~~~~~~~~~~~~~ ########

library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
library(reshape)
b <-  rep(antarctica[c(1,4,8)],10)



for (s in c(1:4)){ # loop over the four seasons; assign correct data each loop iteration
# prepare past data
  ERA <- count_ERA[,c(1,s+1)]    # subset data for that specific season
  colnames(ERA)[2] <- "value"
  
  CESM <- count_CESM_1[,c(1,s+1)]
  CESM[,3] <- 1 # insert new column with data for interaction
  colnames(CESM)[c(2,3)] <- c("value", "ensemble_type")
  CMIP5<- count_CMIP5_1[,c(1,s+1)]
  CMIP5[,3] <- 2 # insert new column with data for interaction
  colnames(CMIP5)[c(2,3)] <- c("value", "ensemble_type")
  all_model <- rbind(CESM, CMIP5)
  
  
# prepare future data
  CESM_f <- abs_change_CESM_2[,c(1,s+1)];  colnames(CESM_f)[2] <- "value"
  CESM_f[,3] <- 1 # insert new column with data for interaction
  colnames(CESM_f)[c(2,3)] <- c("value", "ensemble_type")
  
  CMIP5_f <- abs_change_CMIP5_2[,c(1,s+1)];  colnames(CMIP5_f)[2] <- "value"
  CMIP5_f[,3] <- 2 # insert new column with data for interaction
  colnames(CMIP5_f)[c(2,3)] <- c("value", "ensemble_type")
  
  # merge data for boxplot interaction  
  all_model_f <- rbind(CESM_f, CMIP5_f)
  
  all_model_mean_future_line <- all_model_mean_future_change[all_model_mean_future_change[,3]==s,c(1,2,4)]
  all_model_mean_past_line <- all_model_mean_past[all_model_mean_past[,3]==s,c(1,2,4)]
  
  # initialise title
  if (s == 1){ 
    title <- "a) Past period: 1988-2017"; xlabel <- NULL; ylabel <- NULL;
    title_f <- "c) Future change: 2070-2099"; xlabel <- NULL; ylabel <- NULL;
    axis_labels <- c("W","SW","NW","N","NE","E","SE","S","C","A")
    xlabel <- 'Circulation type'
    # ylabel <- 'Frequency [days]'
    # ylabel_2 <- 'Frequency change [days]'
    rares <- paste('rare types')
  } else if (s == 2){
    title <- "a) Past period: 1988-2017";xlabel <- NULL; ylabel <- NULL; 
    title_f <- "c) Future change: 2070-2099";xlabel <- NULL; ylabel <- NULL; 
    axis_labels <- c("W","SW","NW","N","NE","E","SE","S","C","A")
    xlabel <- 'Circulation type'
    # ylabel <- 'Frequency [days]'
    # ylabel_2 <- 'Frequency change [days]'
    # rares <- paste('rare types: ',11.2,'% in ERA data')
  } else if (s == 3){
    title <- "b) Past period: 1988-2017"; xlabel <- NULL; ylabel <- NULL
    title_f <- "d) Future change: 2070-2099"; xlabel <- NULL; ylabel <- NULL
    axis_labels <- c("W","SW","NW","N","NE","E","SE","S","C","A")
    xlabel <- 'Circulation type'
    # ylabel <- 'Frequency [days]'
    # ylabel_2 <- 'Frequency change [days]'
    # rares <- paste('rare types: ',19.2,'% in ERA data')
  } else if (s == 4){
    title <- "b) Past period: 1988-2017"; xlabel <- NULL; ylabel <- NULL; 
    title_f <- "d) Future change: 2070-2099"; xlabel <- NULL; ylabel <- NULL; 
    axis_labels <- c("W","SW","NW","N","NE","E","SE","S","C","A")
    xlabel <- 'Circulation type'
    # ylabel <- 'Frequency [days]'
    # ylabel_2 <- 'Frequency change [days]'
    rares <- paste('rare types')
  }
  cmip_col <- c(rep(antarctica[5],10), rep('#00bb00', 10), rep('#bb00bb', 10), rep('black', 10))

assign(paste("g",s, sep=""), ggplot() +
  geom_boxplot(data = all_model, aes(x=type, y=value, fill = interaction(type, ensemble_type), 
      middle = mean(value)), outlier.shape=1, outlier.size = 1, fatten=NULL) +
  geom_point(data = ERA, aes(x=type, y=value, colour = "black"), size = 3, shape = 16) +
    
  # mean for all boxplots
  geom_segment(data = all_model_mean_past_line[all_model_mean_past_line[,2]=='1',],
    aes(x=type-.01,y=value,xend=type-.37,yend=value), color='black') +
  geom_segment(data = all_model_mean_past_line[all_model_mean_past_line[,2]=='2',],
    aes(x=type+.01,y=value,xend=type+.37,yend=value), color='black') +
    
  scale_x_continuous(breaks=seq(1, 10, by = 1),
                     labels=axis_labels, sec.axis = dup_axis(labels=NULL)) +
  scale_y_continuous(breaks = seq(0, 100, by = 5), 
                     limits = c(0, 47), sec.axis = dup_axis(labels=NULL)) + 
  labs(x = NULL, y = ylabel, colour = "grey") +
  scale_fill_manual(values = c(rep(Blues[4],10), rep(Reds[4], 10)), 
    label = c('CESM past','CESM future','','','','','','','','','','',
              'CMIP5 past','CMIP5 future')) + 
    scale_color_manual(values = 'black', 
    label = c('ERA-40/-Interim'), drop=FALSE) +
  geom_rect(aes(xmin=4.5, xmax=10.5, ymin=-Inf, ymax=Inf), colour= NA, alpha='0.1') + 
  geom_text(aes(x=5, label=rares, y=32.5, hjust=0), colour="black",size = 4.5) +
  ggtitle(title)) # adding subtitle

assign(paste("h",s, sep=""), ggplot() +
  geom_rect(aes(xmin=4.5, xmax=10.5, ymin=-Inf, ymax=Inf), colour= NA, alpha='0.1') + 
  geom_boxplot(data = all_model_f, aes(x=type, y=value, fill = interaction(type, ensemble_type), 
    middle = mean(value)), outlier.shape=1, outlier.size = 1, fatten=NULL) +
  
  # mean for all boxplots
  geom_segment(data = all_model_mean_future_line[all_model_mean_future_line[,2]=='1',],
    aes(x=type-.01,y=value,xend=type-.37,yend=value), color='black') +
    
  geom_segment(data = all_model_mean_future_line[all_model_mean_future_line[,2]=='2',],
    aes(x=type+.01,y=value,xend=type+.37,yend=value), color='black') +
    
  geom_hline(yintercept=0, color = 'black', size = .3) +
  # geom_hline(yintercept=-8, color = 'white', size = .3) +
  # geom_segment(mapping=aes(x=4.5, y=-8, xend=Inf, yend=-8), 
  #   size=.3, color='grey') +     
  scale_x_continuous(breaks=seq(1, 10, by = 1), 
                     labels=axis_labels, sec.axis = dup_axis(labels=NULL, name=NULL)) +
  scale_y_continuous(breaks = seq(-100, 100, by = 4), limits = c(-10, 11), 
                     sec.axis = dup_axis(labels=NULL)) + 
  labs(x = xlabel, y = ylabel, colour = "grey") +
  # geom_text(data = mean_CESM[1:4,], aes(label = paste(value, '%', sep=""), group=type, x=type-0.2, y = -7.5, color=antarctica[5])) +
  # geom_text(data = mean_CMIP5[1:4,], aes(label = paste(value, '%', sep=""), group=type, x=type+0.2, y = -9.5, color='#00bb00')) +
    scale_fill_manual(values = c(rep(Blues[7],10), rep(Reds[7], 10)), 
                      label = c('CESM12-LE 2042-2099', 'CMIP5 192042-2099')) + 
  scale_color_manual(values = c('#bb00bb', '#00bb00'), guide = FALSE) +
  ggtitle(title_f)) # adding subtitle


}

# combine SUMMER and WINTER season for plot in main manuscript
dev.new()
figure <- ggarrange(g2,g4,h2,h4, heights=c(1.3, 1),ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure, 
                left = text_grob("Frequency (days per season)", rot=90, size=20),
                top = text_grob(
'Summer                                                                Winter', size=20))
# export as .png with specific filename
 filename = paste('frequencies_summer_winter_',method,'.png', sep="")
# # export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
        width = 12, height = 9, units = 'in', res = 500)
dev.off()

# combine SPRING and AUTUMN season for plot in supporting material
dev.new()
figure <- ggarrange(g1,g3,h1,h3, heights=c(1.6, 1),ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure, 
                left = text_grob("Frequency [days per season]", rot=90, size=20),
                top = text_grob(
                  'Spring                                                                Autumn', size=20))
# export as .png with specific filename
filename = paste('frequencies_spring_autumn_',method,'.png', sep="")
# # export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 12, height = 7, units = 'in', res = 500)
dev.off()
# ######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ frequency table for summary figure ~~~~~~~~~~~~~~~~~~~~~~~ ########
# 
# # initiating data.frame where I put in my stuff
# mean_freq_CESM <- data.frame(matrix(NA, nrow = 10, ncol = 9))
# colnames(mean_freq_CESM) <- c("type", "spring_1", "summer_1", "autumn_1", "winter_1",
#                               "spring_2", "summer_2", "autumn_2", "winter_2")
# mean_freq_CESM[,1] <- 1:10 
# 
# mean_freq_CMIP5 <- mean_freq_CESM # copy-paste data frame structure
# 
# for (s in 1:4){ # loop over all four seasons
#   for (i in 1:10){ # loop over all ten circulation types
#     # subset data for specific type and season, then calculate ensemble mean and put value
#     # into allocated mean_pers_CESM_data frame
#     mean_freq_CESM[i,s+1] <- mean(count_CESM_1[count_CESM_1[,1]==i,s+1],na.rm=TRUE)
#     mean_freq_CMIP5[i,s+1] <- mean(count_CMIP5_1[count_CMIP5_1[,1]==i,s+1],na.rm=TRUE)
#     # for future period, we shift the data by four columns to have
#     #      past           future
#     # .............. | ..............
#     # next to each other
#     mean_freq_CESM[i,s+5] <- mean(count_CESM_2[count_CESM_1[,1]==i,s+1],na.rm=TRUE)
#     mean_freq_CMIP5[i,s+5] <- mean(count_CMIP5_2[count_CMIP5_1[,1]==i,s+1],na.rm=TRUE)
#   }
# }
# 
# # clean up workspace
# rm(all_model, all_model_f, CESM, CESM_1, CESM_2, CESM_f,
#    CMIP5, CMIP5_1, CMIP5_2, CMIP5_f, data, ERA, figure, g1, g2, g3, g4, h1, h2, h3, h4, 
#    axis_labels, i, s, reference, title, title_f, total, xlabel, ylabel)
# 
# 
# # save variable for later import in summary figure script:
# # 'OBS_CESM12-LE_CMIP5_summary_figure_all_parameters_combined.R'
# 
# # preparing percentage frequency changes for saving as R workspace
# freq_perc_CESM <- (count_CESM_2 / (count_CESM_1 / 100) - 100)
# freq_perc_CMIP5 <- (count_CMIP5_2 / (count_CMIP5_1 / 100) - 100)
# freq_perc_CESM[,1] <- count_CESM_1[,1]   # replace again 1st column with correct data
# freq_perc_CMIP5[,1] <- count_CMIP5_1[,1] # for all ten circulation types
# 
# # checking if what I do is correct
# # calculate mean persistence change for westerly wind in summer
# a <- freq_perc_CESM[freq_perc_CESM[,1]==1,3]; mean(a)  
# b <- freq_perc_CMIP5[freq_perc_CMIP5[,1]==1,3]; mean(b)
# 
# 
# 
# # Save frequency data to file
# path <- 'E:/Praktikum MeteoSchweiz/r_scripts/'
# filename = paste('workspace_frequency_for_summary_figure_CESM_CMIP5')
# save(mean_freq_CESM, mean_freq_CMIP5, freq_perc_CESM, freq_perc_CMIP5,
#      file = paste(path, filename, '.RData',sep=''))
# # Restore the object
# # load(file = paste(path, filename, '.RData',sep=''))
