# Purpose:  Plot time series of frequency of seasonal circulation types 
# each year, their linear trend with slope and pvalue indices throughout 1960-2100 and
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
#           Frequency and Persistence of Central European Circulation Types                     #
# My Name:  Maurice Huguenin-Virchaux                                                           #
# My Email: hmaurice@student.ethz.ch                                                            #
# Date:     19.03.2019, 13:15 CET                                                               #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# library(latex2exp) # package for LaTeX font in plots
library(base)
library(ggplot2) # for plotting
library(reshape)
library(RColorBrewer)

# define variable
past            <- c(1988, 2017) # 30 years
future          <- c(2070, 2099) # 30 years
nyears          <- future[2]-future[1] + 1 # number of years
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# choose classification method
method <- 'Z500' # or method <- 'PSL'
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ preamble and data load in ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

if (method == 'Z500'){
  classification <- 'wkwtg1d0'
} else if (method == 'PSL'){
  classification <- 'wkwtp1d0'
}
cesm_data <- paste('E:/Praktikum MeteoSchweiz/cost_files/cost_CESM12-LE_historical_1960-2099_',method,'.dat', sep="")
# that's the data with all ensembles that work
cmip5_data <- paste('E:/Praktikum MeteoSchweiz/cost_files/cost_CMIP5_historical_rcp85_models_that_work.dat')

# adapting ggplot theme to suit my needs
theme_set(theme_bw() + 
            theme(axis.line = element_line(colour = "black"),
                  panel.grid.major.y = element_line(colour = 'grey'),
                  panel.grid.major = element_line(size = 0.1),
                  panel.grid.major.x = element_blank(),
                  panel.grid.minor = element_blank(),
                  panel.border = element_blank(),
                  legend.title = element_blank(),
                  plot.title = element_text(size = 15),
                  axis.title.x = element_text(size = 15),
                  axis.title.y = element_text(size = 15),
                  legend.text=element_text(size=15),
                  legend.position = "bottom",
                  panel.background = element_blank(), 
                  axis.text.x = element_text(size= 15), # set size of labels relative to
                  # default which is 11
                  axis.text.y = element_text(size= 15)))

# colour bar 
# myblue = rgb(.19, .21, .58) # blue colour from my msc thesis
Reds <- brewer.pal(9, "Reds")      # red colour scale with 9 entries
Blues <- brewer.pal(9, "Blues")    # blue colour scale with 9 entries

# cseason <- c('#AFD145', '#EE2926', '#8E1C1C', '#4892D2')
# season_light <- c('#7fcf7f', '#ff9e9e', '#ca7f88', '#967fe3')
# season_dark <- c('#00a000', '#FF3D3D', '#960011', '#2D00C8')
# season_dark <- c("lightgreen", "red", "darkred", "blue")
# cseason_trans[1] <- rgb(175,209,69,0.5) # transparent colours
# cseason_trans[2] <- rgb(238, 41, 38, 0.5)
# cseason_trans[3] <- rgb(142, 28, 28, 0.5)
# cseason_trans[4] <- rgb(72, 151, 210, 0.5)

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in reanalysis data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# read in table with above specified years of data
df_obs <- read.table("E:/Praktikum MeteoSchweiz/cost_files/WTC_MCH_19570901-20180831.dat", 
                     header=TRUE, skip = 0) # OBS first
df_obs <- df_obs[which(df_obs[1:nrow(df_obs),2]>=19600101 & df_obs[1:nrow(df_obs),2]<20180101),]
df_obs <- df_obs[, c('time', classification)] # only select time and GWT10 classification

# rewrite date to be in format YYYY-MM-DD
df_obs[["time"]] <- as.Date(as.character(df_obs[["time"]]),format="%Y%m%d")
year <- format(df_obs$time, "%Y")

# insert season vector as third column
d <- as.Date(cut(as.Date(df_obs$time, "%m/%d/%Y"), "month")) + 32
df_obs$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                        labels = c("4", "1", "2", "3"))
colnames(df_obs)[2] <- "type" # rename column
rm(d) # rm = remove, just like in bash

# only show year value in first column
df_obs[,1] <- year

for (s in 1:4){ # loop over all seasons
  # create array which stores the count weather type persistence
  bins_ERA <- data.frame(matrix(0, nrow = 58, ncol = 12))
  colnames(bins_ERA) <- c("period", 1:10, "season")
  bins_ERA[,1] <- c(1960:2017); # yearly time index
  bins_ERA[,12] <- s # seasonal data (1 = spring, 2 = summer, 3 = autumn and 4 = winter)
  # create array in which I store trend data
  trends_ERA <- data.frame(matrix(0, nrow = 10, ncol = 3))
  colnames(trends_ERA) <- c('weather_pattern', 'trend_past', 'season')
  trends_ERA[,1] <- 1:10; trends_ERA[,3] <- s 
  
  for (i in 1:10){
    
    old <- Sys.time() # get start time
    
    df_loop <- df_obs[df_obs[,2] == i & df_obs[,3] == s, c('time', 'type')]
    
    # now I extracted the seasonal frequency of a certain weather type during each year
    # now counting how many times this one occurs each year
    
    a <- as.data.frame(table(df_loop))[,c(1,3)]
    for (m in 1:nrow(a)){
      bins_ERA[bins_ERA[,1] == a[m,1],i+1] <- a[m,2] # fill in yearly data into respective bins data
      # bins_ERA[where the first column = first column entry of loop data frame] <- put the data there
    }
    # trend over past period
    fit <- lm(bins_ERA[bins_ERA[,1]>=past[1] & bins_ERA[,1]<=past[2],i+1] ~ 
                bins_ERA[bins_ERA[,1]>=past[1] & bins_ERA[,1]<=past[2],1])
    trends_ERA[i,2] <- summary(fit)$coefficients[2]; rm(fit)
    
    # print elapsed time
    new <- Sys.time() - old # calculate difference
    print(new) # print in nice format
  } # finished loop over weather types
  
  if (s == 1){
    bins_ERA_all <- bins_ERA
    trends_ERA_all <- trends_ERA
  } else {
    bins_ERA_all <- rbind(bins_ERA_all, bins_ERA)
    trends_ERA_all <- rbind(trends_ERA_all, trends_ERA)
  }
} # finish loop over all seasons

bins_ERA_all[bins_ERA_all == 0] <- NA # set zeroes to NA
# clean up workspace
rm(a, bins_ERA, trends_ERA, df_loop, df_obs, i, m, new, nyears, s)


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CESM data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

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

# add season column
d <- as.Date(cut(as.Date(df_ens$time, "%m/%d/%Y"), "month")) + 32
df_ens$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                        labels = c("4", "1", "2", "3"))
year <- format(df_ens[,1], "%Y")
df_ens[,1] <- year # only show year value in date column

rm(d) # rm = remove, just like in bash

for (e in 1:84){ # loop through all ensembles
  old <- Sys.time() # get start time
  for (s in 1:4){ # loop over all seasons
    # create array which stores the count weather type persistence
    bins_CESM <- data.frame(matrix(0, nrow = 140, ncol = 12))
    colnames(bins_CESM) <- c("period", 1:10, "season")
    bins_CESM[,1] <- c(1960:future[2]); # yearly time index
    bins_CESM[,12] <- s # seasonal data (1 = spring, 2 = summer, 3 = autumn and 4 = winter)
    # create array in which I store trend data
    trends_CESM <- data.frame(matrix(0, nrow = 10, ncol = 3))
    colnames(trends_CESM) <- c('type', 'trend', 'season')
    trends_CESM[,1] <- 1:10
    trends_CESM[,3] <- s # seasonal data (1 = spring, 2 = summer, 3 = autumn and 4 = winter)
    
    for (i in 1:10){
      
      df_loop <- df_ens[df_ens[,e+1] == i & df_ens[,86] == s, c(1,e+1)] # subset data
      # only select 1 (out of 84) ensemble members, 1 (out of 10) weather patterns and 1
      # (out of 4) seasons at a time
      
      # now I extracted the seasonal frequency of a certain weather type during each year
      # now counting how many times this one occurs each year
      
      a <- as.data.frame(table(df_loop))[,c(1,3)]
      for (m in 1:nrow(a)){
        bins_CESM[bins_CESM[,1] == a[m,1],i+1] <- a[m,2] # fill in yearly data into respective bins data
        # bins_ERA[where the first column = first column entry of loop data frame] <- put the data there
      }
      # trend over the full 112 year time period 1988-2099
      fit <- lm(bins_CESM[bins_CESM[,1]>=past[1] & bins_CESM[,1]<=past[2],i+1] ~ bins_CESM[bins_CESM[,1]>=past[1] & bins_CESM[,1]<=past[2],1])
      trends_CESM[i,2] <- summary(fit)$coefficients[2]; rm(fit)
      
      
    } # finished loop over weather types
    
    if (s == 1){
      bins_CESM_loop <- bins_CESM
      trends_CESM_loop <- trends_CESM
      
    } else {
      bins_CESM_loop <- rbind(bins_CESM_loop, bins_CESM) # concatenate all four seasons
      trends_CESM_loop <- rbind(trends_CESM_loop, trends_CESM) # concatenate all four seasons
    }
  } # finish loop over all seasons
  if (e == 1){
    bins_CESM_all <- bins_CESM_loop
    trends_CESM_all <- trends_CESM_loop
    
  } else {
    bins_CESM_all <- rbind(bins_CESM_all, bins_CESM_loop) # concatenate all 84 ensemble members
    trends_CESM_all <- rbind(trends_CESM_all, trends_CESM_loop) # concatenate all 84 ensemble members
  }
  # print elapsed time
  new <- Sys.time() - old # calculate difference
  print(new) # print in nice format
  
} # finish loop over all ensembles

bins_CESM_all[bins_CESM_all == 0] <- NA # set zeroes to NA
trends_CESM_all[trends_CESM_all == 0] <- NA # set zeroes to NA
# clean up workspace
rm(a, bins_CESM, trends_CESM, trends_CESM_loop, bins_CESM_loop, df_loop, df_ens, i, m, e, new, s)

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CMIP5 data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# read in table with header
df_ens <- read.table(cmip5_data, header=FALSE, skip=0)
df_ens[is.na(df_ens)] <- 0 # set NA to zero
# join the three columns and create the date vector
df_ens$V1 <- as.Date(with(df_ens, paste(V1, V2, V3,sep="-")), "%Y-%m-%d")
df_ens$V2 <- NULL
df_ens$V3 <- NULL
features <- c(sprintf("e%02d", seq(1,23))) # label each ensemble column numerically with suffix 'e',
# e.g. 'e01', 'e02', 'e03', ...

colnames(df_ens)[2:24]= features # rename column names
colnames(df_ens)[1] <- "time" # change name of column

# add season column
d <- as.Date(cut(as.Date(df_ens$time, "%m/%d/%Y"), "month")) + 32
df_ens$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                        labels = c("4", "1", "2", "3"))
year <- format(df_ens[,1], "%Y")
df_ens[,1] <- year # only show year value in date column

rm(d) # rm = remove, just like in bash

for (e in 1:23){ # loop through all ensembles
  old <- Sys.time() # get start time
  for (s in 1:4){ # loop over all seasons
    # create array which stores the count weather type persistence
    bins_CMIP5 <- data.frame(matrix(0, nrow = 140, ncol = 12))
    colnames(bins_CMIP5) <- c("period", 1:10, "season")
    bins_CMIP5[,1] <- c(1960:future[2]); # yearly time index
    bins_CMIP5[,12] <- s # seasonal data (1 = spring, 2 = summer, 3 = autumn and 4 = winter)
    # create array in which I store trend data
    trends_CMIP5 <- data.frame(matrix(0, nrow = 10, ncol = 3))
    colnames(trends_CMIP5) <- c('type', 'trend', 'season')
    trends_CMIP5[,1] <- 1:10
    trends_CMIP5[,3] <- s # seasonal data (1 = spring, 2 = summer, 3 = autumn and 4 = winter)
    
    for (i in 1:10){
      
      df_loop <- df_ens[df_ens[,e+1] == i & df_ens[,25] == s, c(1,e+1)] # subset data
      # only select 1 (out of 84) ensemble members, 1 (out of 10) weather patterns and 1
      # (out of 4) seasons at a time
      
      # now I extracted the seasonal frequency of a certain weather type during each year
      # now counting how many times this one occurs each year
      
      a <- as.data.frame(table(df_loop))[,c(1,3)]
      for (m in 1:nrow(a)){
        bins_CMIP5[bins_CMIP5[,1] == a[m,1],i+1] <- a[m,2] # fill in yearly data into respective bins data
        # bins_ERA[where the first column = first column entry of loop data frame] <- put the data there
      }
      # trend over the full 112 year time period 1988-2099
      fit <- lm(bins_CMIP5[bins_CMIP5[,1]>=past[1] & bins_CMIP5[,1]<=past[2],i+1] ~ bins_CMIP5[bins_CMIP5[,1]>=past[1] & bins_CMIP5[,1]<=past[2],1])
      trends_CMIP5[i,2] <- summary(fit)$coefficients[2]; rm(fit)
      
    } # finished loop over weather types
    
    if (s == 1){
      bins_CMIP5_loop <- bins_CMIP5
      trends_CMIP5_loop <- trends_CMIP5
    } else {
      bins_CMIP5_loop <- rbind(bins_CMIP5_loop, bins_CMIP5) #T concatenate all four seasons
      trends_CMIP5_loop <- rbind(trends_CMIP5_loop, trends_CMIP5) #T concatenate all four seasons
    }
  } # finish loop over all seasons
  if (e == 1){
    bins_CMIP5_all <- bins_CMIP5_loop
    trends_CMIP5_all <- trends_CMIP5_loop
  } else {
    bins_CMIP5_all <- rbind(bins_CMIP5_all, bins_CMIP5_loop) # concatenate all 84 ensemble members
    trends_CMIP5_all <- rbind(trends_CMIP5_all, trends_CMIP5_loop) # concatenate all 84 ensemble members
  }
  # print elapsed time
  new <- Sys.time() - old # calculate difference
  print(new) # print in nice format
  
} # finish loop over all ensembles

bins_CMIP5_all[bins_CMIP5_all == 0] <- NA # set zeroes to NA
trends_CMIP5_all[trends_CMIP5_all == 0] <- NA # set zeroes to NA
# clean up workspace
rm(a, bins_CMIP5, trends_CMIP5, trends_CMIP5_loop, bins_CMIP5_loop, 
   df_loop, df_ens, i, m, e, new, s, cesm_data, classification, cmip5_data, 
   features, old, year)









######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine for time series subplots and trends ~~~~ ########
library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# GET LM EQUATION AND R-SQUARED AS STRING                                                      #
# SOURCE: http://goo.gl/K4yh                                                                   #
# https://stackoverflow.com/questions/7549694/adding-regression-line-equation-and-r2-on-graph  #
lm_beta <- function(array){                                                                    #
  m <- lm(array[,2] ~ array[,1]);                                                              #
  eq <- substitute(beta[1]~"="~b,                                                              #
                   list(rvalue = sprintf("%.2f",sign(coef(m)[2])*sqrt(summary(m)$r.squared)),  #
                        b = format(summary(m)$coefficients[2,1], digits = 2),                  #
                        pval = format(summary(m)$coefficients[2,4], digits = 2)))              #
  as.character(as.expression(eq));                                                             #  
}                                                                                              #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# preliminary plotting
for (s in c(2,4)){ # loop over seasons -> c(2,4) = summer and winter seasons
  for (i in 1:4){ # loop over all weather pattern
      
      # assign ERA data
      ERA <- bins_ERA_all[bins_ERA_all[,12]==s,c(1,i+1,12)]
      # assign CESM data, calculate mean, upper and lower percentile
      CESM <- bins_CESM_all[bins_CESM_all[,12] == s, c(1,i+1,12)]
      CMIP5 <- bins_CMIP5_all[bins_CMIP5_all[,12] == s, c(1,i+1,12)]
      
        beta_1 <- ''
        beta_2 <- lm_beta(ERA[ERA[,1]>=1988 & ERA[,1]<=2017,c(1,2)])
        pval_1 <- ''
        pval_2 <- lm_pval(ERA[ERA[,1]>=1988 & ERA[,1]<=2017,c(1,2)])
        trend_colour <- c(NULL, 'black')

      a <- data.frame(matrix(0, nrow = 140, ncol = 5)); a[,1] <- 1960:2099
      colnames(a) <- c("period", 'lower', 'median', 'upper', 'mean'); 
      b <- a; # the same data frame structure for CMIP5 data
      # prepare and combine model data for boxplots
      CESM[,4] <- 1; CMIP5[,4] <- 2; colnames(CESM) <- c('period','value','season','ensemble_type')
      colnames(CMIP5) <- c('period','value','season','ensemble_type')
      
    
      for (y in 1:140){ # loop through all years 1960 - 2099                                      
        # 0% 25% 50% (median) 75% 100%
        m_CESM <- median(CESM[CESM[,1] == a[y,1],2], na.rm=TRUE) # calculate median
        sd_CESM <- sd(CESM[CESM[,1] == a[y,1],2], na.rm=TRUE) # calculate standard deviation
        a[y,2] <-  m_CESM - 2*sd_CESM# -2 standard deviation
        a[y,3] <-  m_CESM # median
        a[y,4] <-  m_CESM + 2*sd_CESM# -2 standard deviation
        a[y,5] <- mean(CESM[CESM[,1] == a[y,1],2], na.rm=TRUE) # calculate mean
        a[a <= 0] <- 0 # set all negative values to zero, this is important for the CI as it
        # cannot go below zero frequency (negative frequency would mean -days of some
        # weather pattern which does not make sense)
        # this way I include 95.43% of the variability
        m_CMIP5 <- median(CMIP5[CMIP5[,1] == a[y,1],2], na.rm=TRUE) # calculate median
        sd_CMIP5 <- sd(CMIP5[CMIP5[,1] == a[y,1],2], na.rm=TRUE) # calculate standard deviation
        b[y,2] <-  m_CMIP5 - 2*sd_CMIP5# -2 standard deviation
        b[y,3] <-  m_CMIP5 # median
        b[y,4] <-  m_CMIP5 + 2*sd_CMIP5# -2 standard deviation
        b[y,5] <- mean(CMIP5[CMIP5[,1] == b[y,1],2], na.rm=TRUE) # calculate mean
        b[b <= 0] <- 0 # set all negative values to zero
        # this here shows how to calculate the quartiles instead
        # b[y,2:6] <- quantile(CMIP5[CMIP5[,1] == a[y,1],2], probs = c(0, 0.25, 0.5, 0.75, 1), na.rm=TRUE) 
  }
      CESM <- a; CMIP5 <- b; rm(a, b, m_CESM, m_CMIP5, sd_CESM, sd_CMIP5)

      colnames(ERA) <- c('period', 'value', 'season') # rename columns
      
      xlabel <- NULL # no x- and y-labels on the plot
      ylabel <- NULL
      
      title_string_l <- c('a) West (W)', 'b) Southwest (SW)', 'c) Northwest (NW)', 
                          'd) North (N)', 'i) Northeast (NE)', 'l) East (E)', 
                          'n) Southeast (SE)', 'p) South (S)', 'r) Cyclonic (C)', 
                          't) Anticyclonic (A)', '')
      title_string_r <- c('b) West (W): Trend', 'd) Southwest: Trend', 'b) Northwest: Trend', 
                          'h) North: Trend', 'k) Northeast: Trend', 'm) East: Trend', 
                          'o) Southeast: Trend', 'q) South: Trend', 's) Cyclonic: Trend', 
                          'u) Anticyclonic: Trend', '')
      overhead_title <- c("SPRING", "SUMMER", "AUTUMN", "WINTER")
      colours <- c('#00bb00', antarctica[5], '#bb00bb', antarctica[15])
      
      # ~~~~~~~~~~~~~~ Subplot with time series ~~~~~~~~~~~~~~~~~~~~~~~~~~ #
      # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
      
      assign(paste("g",s,i, sep=""), ggplot() + 
             # add 95.4% confidence intervall and fill it with colour
             geom_ribbon(data=CESM[29:58,], aes(x=period, ymin=lower ,ymax=upper, fill=Reds[2],alpha=.1)) +
               geom_ribbon(data=CMIP5[29:58,], aes(x=period, ymin=lower ,ymax=upper, fill=Blues[2],alpha=.1)) +
               # add annual data for all three dataset
             geom_line(data=ERA[29:58,], aes(x=period, y=value, colour = 'black'), size = 1) + # ERA data
             geom_line(data=CESM[29:58,], aes(x=period, y=mean, colour = Blues[4]), size = 1) + # CESM data
             geom_line(data=CMIP5[29:58,], aes(x=period, y=mean, colour = Reds[4]), size = 1) + # CMIP5 data
               # add colours  
               scale_colour_manual(values = c(Blues[7],Reds[7],'black','black', Reds[7]), 
                                   labels = c('CESM mean     ', 'CMIP5 mean     ', 'ERA-40/-Interim        ERA-40/-Interim trend     ')) +
               scale_fill_manual(values = c(Reds[4], Blues[4], Reds[4], Blues[4]), 
                                 label = c('CESM spread     ', 'CMIP5 spread     ')) + 
               scale_x_continuous(breaks = seq(1988, 2017, by = 5), 
                                  sec.axis = dup_axis(labels=NULL, name=NULL)) +
               scale_y_continuous(breaks = seq(0, 100, by = 10),limits = c(0, 65), 
                                  sec.axis = dup_axis(labels=NULL, name=NULL)) +
               labs(x='Year',y='Frequency (days)', colour = "grey") + 
               ggtitle(paste(title_string_l[i])) + 
               # add past trend for the reanalyis data
               geom_smooth(data=ERA[ERA[,1]>=past[1] & ERA[,1]<=past[2],],aes(x=period,y=value),linetype='dashed',method="lm",se=FALSE,
                            colour=trend_colour[1],size=1) +
               # add the text to the top left from the p-value analysis above
               annotate("text",label=pval_2,x=1988,y=63,size=4,colour="black",parse=TRUE,hjust=0))
  }
}

# ~~~~~~~~~~~~ Save SUMMER figure ~~~~~~~~~~~~ #
dev.new()
# combine the four subplots: g21 = the subplot for the (2) summer season and the (1) westerly circulaton type, hence the '21' label
figure <- ggarrange(g21,g22,g23,g24,ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure, 
                 top = text_grob('Summer', size=20))
# print(figure)
# export as .png with specific filename
filename = paste('time_series_and_trends_revision_summer.png', sep="")
# # export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 16, height = 9, units = 'in', res = 300)
dev.off()
# ~~~~~~~~~~~~ Save WINTER figure ~~~~~~~~~~~~ #
dev.new()
# only combine summer and winter season as of 07. 02. 2019m 09:13 CET
figure <- ggarrange(g41,g42,g43,g44,ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure, 
                top = text_grob('Winter', size=20))
# print(figure)
# export as .png with specific filename
filename = paste('time_series_and_trends_revision_winter.png', sep="")
# # export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 16, height = 9, units = 'in', res = 300)
dev.off()

# clean up workspace
rm(figure, filename, colours, overhead_title, path, s, 
   xlabel, ylabel, y)

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine boxplots of trends with ERA data as a bullet point ~~~~~~~~~~~~~ ########

library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
library(reshape)
b <-  rep(antarctica[c(1,4,8)],10)

for (s in 1:4){ # loop over the four seasons; assign correct data each loop iteration
  # for plotting I need: CESM data from past period, Era data from past period
  ERA <- trends_ERA_all[trends_ERA_all[,3]==s,]    # subset data for that specific season
  # i.e. select all rows from 1st and (s+1)th column
  colnames(ERA) <- c('type', 'value', 'season')
  
  CESM <- trends_CESM_all[trends_CESM_all[,3]==s,c(1,2)] # only select the past trend as reference
  CESM[,3] <- 1 # insert new column with data for interaction
  colnames(CESM) <- c('type', 'value', 'ensemble_type')
  
  CMIP5<- trends_CMIP5_all[trends_CMIP5_all[,3]==s,c(1,2)]
  CMIP5[,3] <- 2 # insert new column with data for interaction
  colnames(CMIP5) <- c('type', 'value', 'ensemble_type')
  
  # merge data for boxplot interaction
  all_model <- rbind(CESM, CMIP5)
  
  # initialise title
  if (s == 1){ 
    title <- "a) Spring"
  } else if (s == 2){
    title <- "b) Summer"
  } else if (s == 3){
    title <- "c) Autumn"
  } else if (s == 4){
    title <- "d) Winter"
  }
  
  ylabel <- NULL
  
  cmip_col <- c(rep(antarctica[5],10), rep('#00bb00', 10), rep('#bb00bb', 10), rep('black', 10))
  #cmip_col <- rep(c(antarctica[5],'#00bb00','#bb00bb'), 10)
  
  assign(paste("g",s, sep=""), ggplot() +
           # plot whiskers and error bars
           # stat_boxplot(data = all_model, aes(x=type, y=value, group=type), geom ='errorbar', width = 0.3) + 
           # boxplot from data which has the correct format
           geom_boxplot(data = all_model[all_model[,1]<=4,], aes(x=type, y=value*10/3, fill = interaction(type, ensemble_type), 
                                              middle = mean(value)), outlier.shape=1, outlier.size = 1) +
           # black dots where Era40/-Interim is
           # geom_boxplot(data = CMIP5, aes(x=type, y=value, group=type, fill=antarctica[5], middle = mean(value)), outlier.shape=1, outlier.size = 1) +
           # black dots where Era40/-Interim is
           geom_point(data = ERA[c(1:4),], aes(x=type, y=value/3*10, colour = "black"), size = 3, shape = 16) +
           # replace labels on x-axis
           scale_x_continuous(breaks=seq(1, 10, by = 1),
                              labels=c("W","SW","NW","N","NE","E","SE","S","C","A")) +
           # adjusted scale for y-axis
           scale_y_continuous(breaks = seq(-5,5, by = 1), limits = c(-2,2)) + 
           # labels; no label on x-axis since it's the same as in lower subplot
           labs(x = 'Circulation type', y = 'Trend in frequency (days/decade)', colour = "grey") +
           geom_hline(yintercept=0, color = 'grey', size = .3) + # horizontal line
           # fill in colours and plot legends; then in Microsoft paint adjust legend to middle and so on
           scale_fill_manual(values = c(rep(Blues[4],4), rep(Reds[4], 4),'black'), 
                             label = c('CESM past', '','','','','','CMIP5 past')) + 
           scale_color_manual(values = 'black', 
                              label = c('ERA-40/-Interim'), drop=FALSE) +
           ggtitle(title)) # adding subtitle
}
dev.new()
figure <- ggarrange(g1,g2,g3,g4, ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure)

#print(figure)
# export as .png with specific filename
filename = paste('OBS_CESM12-LE_boxplot_trends_', method, '_rev2.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"),
         width = 10, height = 9, units = 'in', res = 300)
dev.off()

# clean up workspace
rm(g1, g2, g3, g4, s, title, ylabel)




