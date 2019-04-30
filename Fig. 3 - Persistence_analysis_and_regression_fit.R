# Practicum MeteoSwiss:  Analysis of persistent (i.e. consecutive) circulation types in 
#                       ERA-40/-Interim, CESM and CMIP5
# 
# Maurice Huguenin-Virchaux, 16. 10. 2018, 12:27 CET
# hmaurice@student.ethz.ch
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
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
method <- 'Z500' # or method <- 'PSL'
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# if plot theme messed up, run 'preamble' section again to update theme
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
                  panel.grid.major.y = element_line(colour = "grey"),
                  panel.grid.major = element_line(size = 0.1),
                  panel.grid.major.x = element_blank(),
                  panel.grid.minor = element_blank(),
                  panel.border = element_blank(),
                  legend.title = element_blank(),
                  plot.title = element_text(size = 20),
                  axis.title.x = element_text(size = 20),
                  axis.title.y = element_text(size = 20),
                  legend.text=element_text(size=20),
                  legend.position = "bottom",
                  panel.background = element_blank(), 
                  axis.text.x = element_text(size= 20), # set size of labels relative to
                  # default which is 11
                  axis.text.y = element_text(size= 20)))

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


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in reanalysis data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# read in table with above specified years of data
df_obs <- read.table("E:/Praktikum MeteoSchweiz/cost_files/WTC_MCH_19570901-20180831.dat", 
                     header=TRUE, skip = 0) # OBS first
df_obs <- df_obs[which(df_obs[,2]>=paste(past[1],'0101',sep='') & 
                       df_obs[,2]<=paste(past[2],'1231',sep='')),]
df_obs <- df_obs[, c('time', classification)] # only select time and GWT10 classification

# rewrite date to be in format YYYY-MM-DD
df_obs[["time"]] <- as.Date(as.character(df_obs[["time"]]),format="%Y%m%d")
year <- format(df_obs$time, "%Y")

# insert season vector as third column
d <- as.Date(cut(as.Date(df_obs$time, "%m/%d/%Y"), "month")) + 32
df_obs$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                        labels = c("winter", "spring", "summer", "fall"))
colnames(df_obs)[2] <- "type" # rename column
rm(d) # rm = remove, just like in bash


# our goal here: count consecutive days of a certain weather type in the dataset
# e.g. how frequent is a 10-day period with only pattern 5?



for (i in 1:10){
  # create array which stores the count weather type persistence
  bins_ERA <- data.frame(matrix(0, nrow = 20, ncol = 6))
  colnames(bins_ERA) <- c("period", "spring_era", "summer_era", "fall_era", "winter_era", "weather_pattern")
  bins_ERA[,1] <- 1:20 # persistence bin
  bins_ERA_perc <- bins_ERA # initiate empty data frame for percentage values
  
  bins_ERA[,6] <- i; bins_ERA_perc[,6] <- i # fill in info about weather pattern
  
  for (l in 1:4){ # loop over the four season, i.e. 1 = spring, 2 = summer, 3 = autumn, 4 = winter
    old <- Sys.time() # get start time
    
    if (l == 1){
      h = 'spring'
    } else if (l == 2){
      h = 'summer'
    } else if (l == 3){
      h = 'fall'
    } else if (l == 4){
      h = 'winter'
    }
    df_loop <- df_obs[df_obs$type == i & df_obs$season == h, c('time', 'type')]
    df_loop$last_Date <- c(as.Date("1970-01-01",format="%Y-%m-%d"),
                           df_loop[1:nrow(df_loop)-1,]$time) # add in the date of the day before
    df_loop$diff <- df_loop$time - df_loop$last_Date # calculate day difference
    
    df_loop$type <- c(0,df_loop[1:nrow(df_loop)-1,]$type) # I don't know what this makes
    df_loop$type <- ifelse(df_loop$type == df_loop$type,0,1)
    
    # set flag if day is consecutive
    df_loop$flag <- ifelse(df_loop$diff==1 & df_loop$type==0,0,1)
    
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
    # with the use of the rle function of base package we can count the consecutive days   #
    # function taken from the internet                                                     #
    # http://dni-institute.in/blogs/count-consecutive-number-of-days-with-condition-in-r/  #
    consecutive_count <- function(x)  {                                                    #
      x <- !x                                                                              #
      rl <- rle(x)                                                                         #
      len <- rl$lengths                                                                    #
      v <- rl$values                                                                       #
      cumLen <- cumsum(len)                                                                #
      z <- x                                                                               #
      # replace the 0 at the end of each zero-block in z by the                            #
      # negative of the length of the preceding 1-block....                                #
      iDrops <- c(0, diff(v)) < 0                                                          #
      z[ cumLen[ iDrops ] ] <- -len[ c(iDrops[-1],FALSE) ]                                 #
      # ... to ensure that the cumsum below does the right thing.                          #
      # We zap the cumsum with x so only the cumsums for the 1-blocks survive:             #
      x*cumsum(z)                                                                          #
    }                                                                                      #
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
    
    # count consecutive days
    df_loop$consecutive <- consecutive_count(df_loop$flag)
    # condence data.frames into smaller ones
    # add + 1 as the shortest consecutive time period is one day
    df_loop <- df_loop[,c("time", "last_Date", "consecutive")] 
    
    # remove consecutive weather patterns which only last one day
    # (as they are kind of redundant)
    # add +1 so that minimum persistence is two days
    df_loop[,3] <- df_loop[,3] +1
    
    # counting number of consecutive multiple day weather periods in this part here
    for (m in 1:nrow(df_loop)){ # loop through all data entries
      if (m < nrow(df_loop)){ # if loop variable is not the last entry
        
        # if entry is 1 and next one is also 1, then it's a 1-day consecutive period, i.e.
        # .-.-.-1-1-.-.-, otherwise it would be the end of a multiple-day period and the index
        # wouldn't be 1
        if (df_loop[m,3] == 1 && df_loop[m+1,3] == 1){ 
          # add +1 count to bins data.frame in that specific location
          bins_ERA[df_loop[m,3],l+1] <- bins_ERA[df_loop[m,3],l+1] +1
        # when we have the sequence: -1-2- where m is to the left
        } else if (df_loop[m,3] > df_loop[m-1,3] && df_loop[m+1,3] == 1){
          bins_ERA[df_loop[m,3],l+1] <- bins_ERA[df_loop[m,3],l+1] +1 # add +1 to counter
        }
        
      } else if (m == nrow(df_loop)){
        bins_ERA[df_loop[m,3],l+1] <- bins_ERA[df_loop[m,3],l+1] +1 # add +1 to counter
      }
    }

    # print elapsed time
    new <- Sys.time() - old # calculate difference
    print(new) # print in nice format
  } # finished loop over all seasons

  
  # creating annual mean of frequency and scaling data relative to it
  sum_ERA <- colSums(bins_ERA[,2:5], na.rm = TRUE) # calculate total of each seasons in last row
  for (s in 1:4){ # loop over all seasons
    bins_ERA_perc[1:20,s+1] <- bins_ERA[,s+1] / sum_ERA[s] * 100 # scaling relative to annual total which is 1.0 or 100%
  }
  # now all values in bins_obs and a are in [%] relative to total annual occurrence of that weather pattern
  
  # continualy expand data frame so it includes all 10 weather pattern in the end
  if (i == 1){
    bins_ERA_all_1 <- bins_ERA
    bins_ERA_perc_1 <- bins_ERA_perc
  } else {
    bins_ERA_all_1 <- rbind(bins_ERA_all_1, bins_ERA)
    bins_ERA_perc_1 <- rbind(bins_ERA_perc_1, bins_ERA_perc)
  }
  
} # finish loop over all weather patterns
bins_ERA_all_1[,2:5] <- bins_ERA_all_1[,2:5] / nyears # divide by total years to get mean annual distribution of consecutive 
bins_ERA_all_1[,2:5] <- round(bins_ERA_all_1[,2:5],1)
# circulation types instead of the total 

# ~~~~~~ threshold here: remove all values below 1% ~~~~~~ #
# bins_ERA_all[bins_ERA_all < 1] <- NA # this is my threshold: set all relative frequencies smaller than 1% to NA

rm(df_loop, classification, i, m, new, s, year, bins_ERA, df_obs, bins_ERA_perc) # clean up worspace


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

for (period in 1:2){ # loop over past (1980--2008) and future (2061--2099) periods
  old <- Sys.time() # get start time
  
  if(period == 1){
    start_year <- past[1]; end_year <- past[2] # period 1st Jan 1980 - 31st Dec 2017
  } else if(period == 2){
    start_year <- future[1]; end_year <- future[2] # period 1st Jan 2062 - 31st Dec 2099
  }  
  
  df_ens_loop <- df_ens[which(df_ens[,1]>=paste(start_year,"-01-01", sep = "") & 
                                df_ens[,1]<=paste(end_year,"-12-31", sep = "")),]
  # only select values from specific time period 
  
  # add season column
  d <- as.Date(cut(as.Date(df_ens_loop$time, "%m/%d/%Y"), "month")) + 32
  df_ens_loop$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                               labels = c("winter", "spring", "summer", "fall"))
  rm(d) # rm = remove, just like in bash
  
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
  # with the use of the rle function of base package we can count the consecutive days   #
  # function taken from the internet                                                     #
  # http://dni-institute.in/blogs/count-consecutive-number-of-days-with-condition-in-r/  #
  consecutive_count <- function(x)  {                                                    #
    x <- !x                                                                              #
    rl <- rle(x)                                                                         #
    len <- rl$lengths                                                                    #
    v <- rl$values                                                                       #
    cumLen <- cumsum(len)                                                                #
    z <- x                                                                               #
    # replace the 0 at the end of each zero-block in z by the                            #
    # negative of the length of the preceding 1-block....                                #
    iDrops <- c(0, diff(v)) < 0                                                          #
    z[ cumLen[ iDrops ] ] <- -len[ c(iDrops[-1],FALSE) ]                                 #
    # ... to ensure that the cumsum below does the right thing.                          #
    # We zap the cumsum with x so only the cumsums for the 1-blocks survive:             #
    x*cumsum(z)                                                                          #
  }                                                                                      #
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
  
  
  for (i in 1:84){ # loop through all ensembles
    for (weather_pattern in 1:10){ # loop over all ensembles
      # create array which stores the count of weather type persistence
      bins_CESM <- data.frame(matrix(NA, nrow = 20, ncol = 5))
      colnames(bins_CESM) <- c("period", "spring_cesm", "summer_cesm", "autumn_cesm", "winter_cesm")
      bins_CESM[,1] <- 1:20 # persistence bin
      bins_CESM[,2:5] <- 0 # set all cell values to zero at first, then continuously add +1 if certain condition is met
      
      for (l in 1:4){ # loop over the four season, i.e. 1 = spring, 2 = summer, 3 = autumn, 4 = winter
        if (l == 1){
          s = 'spring'
        } else if (l == 2){
          s = 'summer'
        } else if (l == 3){
          s = 'fall'
        } else if (l == 4){
          s = 'winter'
        }
        
        df_loop <- df_ens_loop[df_ens_loop[,i+1] == weather_pattern & df_ens_loop$season == s, c(1,i+1)]
        
        if (nrow(df_loop) == 0){ # break loop if subset of data is empty
          next
        }
        df_loop$last_Date <- c(as.Date("1970-01-01",format="%Y-%m-%d"),
                               df_loop[1:nrow(df_loop)-1,]$time) # add in the date of the day before
        df_loop$diff <- df_loop$time - df_loop$last_Date # calculate day difference
        
        df_loop$type <- c(0,df_loop[1:nrow(df_loop)-1,]$type) # I don't know what this makes
        df_loop$type <- ifelse(df_loop$type == df_loop$type,0,1)
        
        # set flag if day is consecutive
        df_loop$flag <- ifelse(df_loop$diff==1 & df_loop$type==0,0,1)
        
        # count consecutive days with the consecutive_count() function from above
        df_loop$consecutive <- consecutive_count(df_loop$flag)
        # condence data.frames into smaller ones
        # add + 1 as the shortest consecutive time period is one day
        df_loop <- df_loop[,c("time", "last_Date", "consecutive")] 
        
        # remove consecutive weather patterns which only last one day
        # (as they are kind of redundant)
        # add +1 so that minimum persistence is one day
        df_loop[,3] <- df_loop[,3] + 1
        
        
        # counting number of consecutive multiple day weather periods in this part here
        for (m in 1:nrow(df_loop)){ # loop through all data entries
          if (m < nrow(df_loop)){ # if loop variable is not the last entry
            
            # if entry is 1 and next one is also 1, then it's a 1-day consecutive period, i.e.
            # .-.-.-1-1-.-.-, otherwise it would be the end of a multiple-day period and the index
            # wouldn't be 1
            if (df_loop[m,3] == 1 && df_loop[m+1,3] == 1){ 
              # add +1 count to bins data.frame in that specific location
              bins_CESM[df_loop[m,3],l+1] <- bins_CESM[df_loop[m,3],l+1] +1
              # when we have the sequence: -1-2- where m is to the left
            } else if (df_loop[m,3] > df_loop[m-1,3] && df_loop[m+1,3] == 1){
              bins_CESM[df_loop[m,3],l+1] <- bins_CESM[df_loop[m,3],l+1] +1 # add +1 to counter
            }
            
          } else if (m == nrow(df_loop)){
            bins_CESM[df_loop[m,3],l+1] <- bins_CESM[df_loop[m,3],l+1] +1 # add +1 to counter
          }
        }
        
      }
      
    
      # add column with info on weather pattern
      bins_CESM[,6] <- weather_pattern; colnames(bins_CESM)[6] <- "type"
      

      # continualy expand data frame so it includes all 10 weather pattern in the end
      if (weather_pattern == 1){
        bins_CESM_all <- bins_CESM
      } else {
        bins_CESM_all <- rbind(bins_CESM_all, bins_CESM)
      }
    } # end of loop over all weather patterns
    
    # again, continually expand for each ensemble so that I have one very big data frame to work with
    if (i == 1){
      bins_CESM_ens <- bins_CESM_all
    } else {
      bins_CESM_ens <- rbind(bins_CESM_ens, bins_CESM_all)
    }
    
  } # end of loop over all ensembles
  
  # bins_CESM_ens[bins_CESM_ens < 1] <- NA # this is my threshold: set all relative frequencies smaller than 1% to NA
  
  bins_CESM_ens <- na.omit(bins_CESM_ens) # omit NA values in data frame 
  assign(paste("bins_CESM_all",period,sep="_"), bins_CESM_ens) 
  
  # print elapsed time
  new <- Sys.time() - old # calculate difference
  print(paste("Period ", period, sep=""))
  print(new) # print in nice format
} # end of loop over past (1) and future (2) period              


bins_CESM_all_1[,2:5] <- bins_CESM_all_1[,2:5] / nyears # divide by number of years to get mean annual occurrence of 
# consecutive circulation types
bins_CESM_all_2[,2:5] <- bins_CESM_all_2[,2:5] / nyears

####### ######### scaling here with past frequency, also for future period

# initiate new data.frames where I put in all the percentage values
bins_CESM_perc_1 <- bins_CESM_all_1; bins_CESM_perc_1[,2:5] <- NA
bins_CESM_perc_2 <- bins_CESM_all_2; bins_CESM_perc_2[,2:5] <- NA
  

vec <- 1:20 # I iterate over a block of 20 cell entries instead of the usual +1 iteration in loops
for (i in 1:840){ # loop through all ensembles (84) in blocks of ten cells (i in 1:840)
    for (s in 1:4){ # loop through all seasons
      a <- bins_CESM_all_1[vec+20*(i-1),c(1,s+1)] # subset data for past period
      a[,3] <- bins_CESM_all_2[vec+20*(i-1),c(s+1)] # subset data for future period and write in same data frame
      colnames(a) <- c("period", "CESM_1", "CESM_2") # change column names
      sum_CESM_1 <- colSums(a, na.rm=TRUE) # take the sum of that weather pattern over past period   
      
      # here the scaling part: relative to seasonal total of past period
      if (sum_CESM_1[2] == 0){  # if that circulation type does not occur we have a total sum of said
        # circulation type = 0
        bins_CESM_perc_1[vec+20*(i-1),s+1] <- 0
        bins_CESM_perc_2[vec+20*(i-1),s+1] <- 0
      } else {
        # scaling relative to seasonal total which is 1.0 or 100%
        # scale accordingly all data with percentage relative to past seasonal frequency
        bins_CESM_perc_1[vec+20*(i-1),s+1] <- a[1:20,2] / sum_CESM_1[2] * 100 
        bins_CESM_perc_2[vec+20*(i-1),s+1] <- a[1:20,3] / sum_CESM_1[2] * 100
      }
    }
}
  

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CMIP5 data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

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
  old <- Sys.time() # get start time
  
  if(period == 1){
    start_year <- past[1]; end_year <- past[2] # period 1st Jan 1980 - 31st Dec 2017
  } else if(period == 2){
    start_year <- future[1]; end_year <- future[2] # period 1st Jan 2062 - 31st Dec 2099
  }  
  
  df_ens_loop <- df_ens[which(df_ens[,1]>=paste(start_year,"-01-01", sep = "") & 
                                df_ens[,1]<paste(end_year,"-01-01", sep = "")),]
  # only select values from specific time period 
  
  # add season column
  d <- as.Date(cut(as.Date(df_ens_loop$time, "%m/%d/%Y"), "month")) + 32
  df_ens_loop$season <- factor(quarters(d), levels = c("Q1", "Q2", "Q3", "Q4"), 
                               labels = c("winter", "spring", "summer", "fall"))
  rm(d) # rm = remove, just like in bash
  
  
  total <- ncol(df_ens)-1
  for (i in 1:total){ # loop through all ensembles
    for (weather_pattern in 1:10){ # loop over all ensembles
      # create array which stores the count of weather type persistence
      bins_CMIP5 <- data.frame(matrix(NA, nrow = 20, ncol = 5))
      colnames(bins_CMIP5) <- c("period", "spring_cmip", "summer_cmip", "autumn_cmip", "winter_cmip")
      bins_CMIP5[,1] <- 1:20 # persistence bin
      bins_CMIP5[,2:5] <- 0 # set all cell values to zero at first, then continuously add +1 if certain condition is met
      
      for (l in 1:4){ # loop over the four season, i.e. 1 = spring, 2 = summer, 3 = autumn, 4 = winter
        if (l == 1){
          s = 'spring'
        } else if (l == 2){
          s = 'summer'
        } else if (l == 3){
          s = 'fall'
        } else if (l == 4){
          s = 'winter'
        }

        df_loop <- df_ens_loop[df_ens_loop[,i+1] == weather_pattern & df_ens_loop$season == s, c(1,i+1)]
        
        if (nrow(df_loop) == 0){ # break loop if subset of data is empty
          next
        }
        df_loop$last_Date <- c(as.Date("1970-01-01",format="%Y-%m-%d"),
                               df_loop[1:nrow(df_loop)-1,]$time) # add in the date of the day before
        df_loop$diff <- df_loop$time - df_loop$last_Date # calculate day difference
        
        df_loop$type <- c(0,df_loop[1:nrow(df_loop)-1,]$type) # I don't know what this makes
        df_loop$type <- ifelse(df_loop$type == df_loop$type,0,1)
        
        # set flag if day is consecutive
        df_loop$flag <- ifelse(df_loop$diff==1 & df_loop$type==0,0,1)
        
        # count consecutive days with the consecutive_count() function from above
        df_loop$consecutive <- consecutive_count(df_loop$flag)
        # condence data.frames into smaller ones
        # add + 1 as the shortest consecutive time period is one day
        df_loop <- df_loop[,c("time", "last_Date", "consecutive")] 
        
        # remove consecutive weather patterns which only last one day
        # (as they are kind of redundant)
        # add +1 so that minimum persistence is one day
        df_loop[,3] <- df_loop[,3] + 1
        
        
        # same as in reanalysis, loop through consecutive column and assign +1 integers to bins data.frame
        
        # counting number of consecutive multiple day weather periods in this part here
        for (m in 1:nrow(df_loop)){ # loop through all data entries
          if (m < nrow(df_loop)){ # if loop variable is not the last entry
            
            # if entry is 1 and next one is also 1, then it's a 1-day consecutive period, i.e.
            # .-.-.-1-1-.-.-, otherwise it would be the end of a multiple-day period and the index
            # wouldn't be 1
            if (df_loop[m,3] == 1 && df_loop[m+1,3] == 1){ 
              # add +1 count to bins data.frame in that specific location
              bins_CMIP5[df_loop[m,3],l+1] <- bins_CMIP5[df_loop[m,3],l+1] +1
              # when we have the sequence: -1-2- where m is to the left
            } else if (df_loop[m,3] > df_loop[m-1,3] && df_loop[m+1,3] == 1){
              bins_CMIP5[df_loop[m,3],l+1] <- bins_CMIP5[df_loop[m,3],l+1] +1 # add +1 to counter
            }
            
          } else if (m == nrow(df_loop)){
            bins_CMIP5[df_loop[m,3],l+1] <- bins_CMIP5[df_loop[m,3],l+1] +1 # add +1 to counter
          }
        }
      }
      
      
      # add column with info on weather pattern
      bins_CMIP5[,6] <- weather_pattern; colnames(bins_CMIP5)[6] <- "type"
      

      # continualy expand data frame so it includes all 10 weather pattern in the end
      if (weather_pattern == 1){
        bins_CMIP5_all <- bins_CMIP5
      } else {
        bins_CMIP5_all <- rbind(bins_CMIP5_all, bins_CMIP5)
      }
    } # end of loop over all weather patterns
    
    # again, continually expand for each ensemble so that I have one very big data frame to work with
    if (i == 1){
      bins_CMIP5_ens <- bins_CMIP5_all
    } else {
      bins_CMIP5_ens <- rbind(bins_CMIP5_ens, bins_CMIP5_all)
    }
    
  } # end of loop over all ensembles
  
  # bins_CESM_ens[bins_CESM_ens < 1] <- NA # this is my threshold: set all relative frequencies smaller than 1% to NA
  
  bins_CMIP5_ens <- na.omit(bins_CMIP5_ens)
  assign(paste("bins_CMIP5_all",period,sep="_"), bins_CMIP5_ens) 
  
  # print elapsed time
  new <- Sys.time() - old # calculate difference
  print(paste("Period ", period, sep=""))
  print(new) # print in nice format
  bins_CMIP5[,2:5] <- 0 # set all values to zero again for next iteration in loop
} # end of loop over past (1) and future (2) period              

bins_CMIP5_all_1[,2:5] <- bins_CMIP5_all_1[,2:5] / nyears # divide by number of years to get mean annual occurrence of 
# consecutive circulation types
bins_CMIP5_all_2[,2:5] <- bins_CMIP5_all_2[,2:5] / nyears

####### ######### scaling here with past frequency, also for future period

# initiate new data.frames where I put in all the percentage values
bins_CMIP5_perc_1 <- bins_CMIP5_all_1; bins_CMIP5_perc_1[,2:5] <- NA
bins_CMIP5_perc_2 <- bins_CMIP5_all_2; bins_CMIP5_perc_2[,2:5] <- NA


vec <- 1:20 # I iterate over a block of 20 cell entries instead of the usual +1 iteration in loops
for (i in 1:230){ # loop through all ensembles (23) in blocks of ten cells (i in 1:230)
  for (s in 1:4){ # loop through all seasons
    a <- bins_CMIP5_all_1[vec+20*(i-1),c(1,s+1)]
    a[,3] <- bins_CMIP5_all_2[vec+20*(i-1),c(s+1)]
    colnames(a) <- c("period", "CESM_1", "CESM_2") # change column names
    sum_CMIP5_1 <- colSums(a, na.rm=TRUE) # take the sum of that weather pattern over past period   
    
    # here the scaling part: relative to seasonal total of past period
    if (sum_CMIP5_1[2] == 0){  
      bins_CMIP5_perc_1[vec,s+1] <- 0
      bins_CMIP5_perc_2[vec,s+1] <- 0
    } else {
      # scaling relative to seasonal total which is 1.0 or 100%
      bins_CMIP5_perc_1[vec+20*(i-1),s+1] <- a[1:20,2] / sum_CMIP5_1[2] * 100 
      bins_CMIP5_perc_2[vec+20*(i-1),s+1] <- a[1:20,3] / sum_CMIP5_1[2] * 100
    }
    # bins_CESM_perc_1[bins_CESM_perc_1 == 0] <- NA; bins_CESM_perc_2[bins_CESM_perc_2 == 0] <- NA # set zeroes to NA
  }
}
# as in the CESM section above, we remove here the NA entries
bins_CMIP5_perc_1[is.na(bins_CMIP5_perc_1)] <- 0
bins_CMIP5_perc_2[is.na(bins_CMIP5_perc_2)] <- 0
for (i in 1:6){
  bins_CMIP5_perc_1[is.infinite(bins_CMIP5_perc_1[,i])] <- 0
  bins_CMIP5_perc_2[is.infinite(bins_CMIP5_perc_2[,i])] <- 0
}


rm(bins_CMIP5, bins_CMIP5_ens, bins_CMIP5_all, df_loop, df_ens, df_ens_loop,
   end_year, features, future, i, l, m, new, nyears, old,
   past, s, start_year, weather_pattern, period) # clean up workspace


######## double check if stuff I do is correct ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ################################
a <- bins_ERA_perc_1[1:20,c(1,3)]
b <- bins_CESM_perc_1[which(bins_CESM_perc_1[,6] == 1),c(1,3)]
c <- bins_CESM_perc_2[which(bins_CESM_perc_2[,6] == 1),c(1,3)]
d <- bins_CMIP5_perc_1[which(bins_CMIP5_perc_1[,6] == 1),c(1,3)]
e <- bins_CMIP5_perc_2[which(bins_CMIP5_perc_2[,6] == 1),c(1,3)]


for (p in 1:20){ # loop over consecutive day period
  a[p,3] <- mean(b[which(b[,1] == p),2], na.rm=TRUE) # CESM, past and future
  a[p,4] <- mean(c[which(c[,1] == p),2], na.rm=TRUE)
  a[p,5] <- mean(d[which(d[,1] == p),2], na.rm=TRUE) # the same for CMIP5, past and future
  a[p,6] <- mean(e[which(e[,1] == p),2], na.rm=TRUE)
}
# replace all zeroes with NA;
a[a == 0] <- NA

colnames(a) <- c("period", "ERA", "CESM_1", "CESM_2", "CMIP5_1", "CMIP5_2")
rm(b, c, d, e) # clean up
View(a)

aa <- bins_ERA_all_1[1:20,c(1,3)]
bb <- bins_CESM_all_1[which(bins_CESM_all_1[,6] == 1),c(1,3)]
cc <- bins_CESM_all_2[which(bins_CESM_all_2[,6] == 1),c(1,3)]
dd <- bins_CMIP5_all_1[which(bins_CMIP5_all_1[,6] == 1),c(1,3)]
ee <- bins_CMIP5_all_2[which(bins_CMIP5_all_2[,6] == 1),c(1,3)]


for (p in 1:20){ # loop over consecutive day period
  aa[p,3] <- mean(bb[which(bb[,1] == p),2], na.rm=TRUE) # CESM, past and future
  aa[p,4] <- mean(cc[which(cc[,1] == p),2], na.rm=TRUE)
  aa[p,5] <- mean(dd[which(dd[,1] == p),2], na.rm=TRUE) # the same for CMIP5, past and future
  aa[p,6] <- mean(ee[which(ee[,1] == p),2], na.rm=TRUE)
}
# replace all zeroes with NA;
aa[aa == 0] <- NA

colnames(aa) <- c("period", "ERA", "CESM_1", "CESM_2", "CMIP5_1", "CMIP5_2")
rm(bb, cc, dd, ee) # clean up
View(aa)

rm(bins_CESM, bins_CESM_ens, cesm_data, cmip5_data, h, p, sum_CESM_1, sum_CMIP5_1, 
   sum_ERA, total, vec)
######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine histogram first ~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# here I plot as an example the westerly wind (W) circulation type
# during summer -> this Figure used for the presentation
a <- bins_ERA_perc_1[1:20,c(1,3)]
b <- bins_CESM_perc_1[which(bins_CESM_perc_1[,6] == 1),c(1,3)]
c <- bins_CESM_perc_2[which(bins_CESM_perc_2[,6] == 1),c(1,3)]
d <- bins_CMIP5_perc_1[which(bins_CMIP5_perc_1[,6] == 1),c(1,3)]
e <- bins_CMIP5_perc_2[which(bins_CMIP5_perc_2[,6] == 1),c(1,3)]


for (p in 1:20){ # loop over consecutive day period
  a[p,3] <- mean(b[which(b[,1] == p),2], na.rm=TRUE) # CESM, past and future
  a[p,4] <- mean(c[which(c[,1] == p),2], na.rm=TRUE)
  a[p,5] <- mean(d[which(d[,1] == p),2], na.rm=TRUE) # the same for CMIP5, past and future
  a[p,6] <- mean(e[which(e[,1] == p),2], na.rm=TRUE)
}
# replace all zeroes with NA;
a[a == 0] <- NA

colnames(a) <- c("period", "ERA", "CESM_1", "CESM_2", "CMIP5_1", "CMIP5_2")
rm(b, c, d, e) # clean up
# View(a)


# now we rearrange this data into a long format
a_long <- melt(a, id = "period")

library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
# preliminary bar plot with ggplot -> only plot summer (as this season has all period lengths and no NAs)
dev.new()
p1 <- ggplot(data = a_long, aes(x = period, y = value, group = variable, fill = variable)) +
  geom_bar(stat='summary', position = 'dodge', fun.y = "mean") +
  scale_fill_manual(values = c("black", Blues[4],  Blues[7], Reds[4], Reds[7]), 
                    label = c("ERA-40/-Interim", "CESM past", "CESM future",
                              "CMIP5 past", "CMIP5 future")) + 
  scale_x_continuous(breaks = seq(0, 20, by = 2), limits = c(0.5,20.5)) +
  scale_y_continuous(breaks = seq(0, 70, by = 5), limit = c(0, 45)) +
  labs(x = "Number of consecutive days", y = "Frequency relative to seasonal occurrence [%]", colour = "grey") + 
  theme(legend.direction = "vertical") +
  ggtitle("a) Westerly wind in summer") 
p1 # ok great, the equation is correct: log(y) = ax + b, i.e. y = exp(a*x) * exp(b)

figure <- ggarrange(p1, ncol=1, nrow=1, legend="bottom")
print(figure)
# export as .png with specific filename
filename = paste('ERA_CESM_seasonal_frequency_histogram_west_summer_',method,'_2.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 7, height = 9, units = 'in', res = 600)
dev.off()


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine persistence of histogram (rel.) ~~~~~~~~~~ ########
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# GET LM EQUATION AND R-SQUARED AS STRING                                                      #
# SOURCE: http://goo.gl/K4yh                                                                   #
# https://stackoverflow.com/questions/7549694/adding-regression-line-equation-and-r2-on-graph  #
lm_eqn <- function(array){                                                                     #
  m <- lm(log(array[,2]) ~ array[,1]);                                                         #
  # eq <- substitute(italic(y) == e^(a  ~ b %.% italic(x))*","~~italic(r)^2~"="~r2,              #
  eq <- substitute(y == e^(beta[0] + beta[1] %.% x)*+ E[i]~~','~~italic(r)^2~"="~r2,              
                     list(a = format(summary(m)$coef[1], digits = 2),                            #
                        b = format(summary(m)$coef[2], digits = 2),                            #
                        r2 = format(summary(m)$r.squared, digits = 3)))                        #
  as.character(as.expression(eq));                                                             #
}                                                                                              #
# this is analogue to but the above function writes it into a fancy expression                 #
# model <- lm(data = bins_obs[,c(1,3)], log(summer_era) ~ period)                              #
# summary(model) # -> gives intercept and slop as well                                         #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)
library(cowplot)

for (i in 1:1){
  for (s in 2:2){
    a <- bins_ERA_perc_1[bins_ERA_perc_1[,6] == i,c(1,s+1)]
    b <- bins_CESM_perc_1[which(bins_CESM_perc_1[,6] == i),c(1,s+1)]
    c <- bins_CESM_perc_2[which(bins_CESM_perc_2[,6] == i),c(1,s+1)]
    d <- bins_CMIP5_perc_1[which(bins_CMIP5_perc_1[,6] == i),c(1,s+1)]
    e <- bins_CMIP5_perc_2[which(bins_CMIP5_perc_2[,6] == i),c(1,s+1)]
    
    for (p in 1:20){ # take mean over ensembles
      a[p,3] <- mean(b[which(b[,1] == p),2], na.rm=TRUE) # CESM, past and future
      a[p,4] <- mean(c[which(c[,1] == p),2], na.rm=TRUE)
      a[p,5] <- mean(d[which(d[,1] == p),2], na.rm=TRUE) # the same for CMIP5, past and future
      a[p,6] <- mean(e[which(e[,1] == p),2], na.rm=TRUE)
    }
  }
} 
# replace all zeroes with NA;
a[a == 0] <- NA

colnames(a) <- c("period", "ERA", "CESM_1", "CESM_2", "CMIP5_1", "CMIP5_2")
rm(b, c, d, e) # clean up

# preliminary bar plot with ggplot -> only plot summer (as this season has all period lengths and no NAs)
dev.new()
p1 <- ggplot() +
  geom_smooth(data=a,aes(x=period,y=ERA,color="ERA", fill = "grey"), method = "lm", na.rm = TRUE, se=FALSE) + 
  
  geom_smooth(data=a,aes(x=period,y=CESM_1,color="CESM past", fill = "grey"), method = "lm", na.rm = TRUE, se=FALSE) +
  geom_smooth(data=a,aes(x=period,y=CESM_2,color="CESM future", fill = "grey"), method = "lm", na.rm = TRUE, se=FALSE) +
  
  geom_smooth(data=a,aes(x=period,y=CMIP5_1,color="CMIP5 past", fill = "grey"), method = "lm", na.rm = TRUE, se=FALSE) + 
  geom_smooth(data=a,aes(x=period,y=CMIP5_2,color="CMIP5 future", fill = "grey"), method = "lm", na.rm = TRUE, se=FALSE) + 
  
  geom_point(data=a,aes(x=period, y=ERA, color = "ERA-40/-Interim"),size = 4,alpha=.8,na.rm=TRUE) +
  geom_point(data=a,aes(x=period, y=CESM_1, color = "CESM past"),size=4,alpha=.8,na.rm=TRUE) +
  geom_point(data=a,aes(x=period, y=CESM_2, color = "CESM future"),size=4,na.rm=TRUE) +
  geom_point(data=a,aes(x=period, y=CMIP5_1, color = "CMIP5 past"),size=4,na.rm=TRUE) +
  geom_point(data=a,aes(x=period, y=CMIP5_2, color = "CMIP5 future"),size=4,na.rm=TRUE) +

  scale_fill_manual(values = c("grey", "grey", "grey"), guide = FALSE) + 
  # legend labels are sorted alphabetically and with increasing number, i.e. CESM past > CESM future > ERA
  # adjust colours as well: CESM past = blue, CESM future = red, ERA = black
  scale_color_manual(values = c(Blues[7], Blues[4], Reds[7], Reds[4], "black", 'black',
                                Blues[4], Reds[4], Blues[7], Reds[7], "black")) +
  # scale_color_manual(values = c('#bb00bb',antarctica[5],'black',
  #                               antarctica[15], antarctica[5], '#00bb00', '#bb00bb', "black")) + 
  # label = c("CESM12-LE 1980-2018", "ERA40/-Interim 1980-2018", "test")) +
  scale_x_continuous(breaks = seq(0, 10, by = 1), limits = c(1,8), 
                     sec.axis = dup_axis(labels=NULL, name=NULL)) +
  scale_y_log10(breaks = c(0.1, 1, 2, 5, 10, 20, 50, 75), limit = c(1, 50), 
                sec.axis = dup_axis(labels=NULL, name=NULL)) +
  labs(x = "Number of consecutive days", y = "log(Frequency relative to past seasonal occurrence) [%]", colour = "grey") + 
  # create annotation with linear model (lm) regression equation using the 'lm_eqn' function
  # for this, select only first (2:10) and sixth (mean annual frequency) columns, e.g. bins_obs[, c(1,6)]
  # write text at x,y position in plot and align left (hjust = 0)
  geom_text() +
  # create annotation with linear model (lm) regression equation using the 'lm_eqn' function
  # for this, select only first (2:10) and sixth (mean annual frequency) columns, e.g. bins_obs[, c(1,6)]
  # write text at x,y position in plot and align left (hjust = 0)
  annotate("text", label = lm_eqn(a[,c(1,2)]), x = 1.75, y = 44, size = 7,
           colour = "black", parse = TRUE, hjust = 0) +
  annotate("text", label = lm_eqn(a[,c(1,3)]), x = 2.75, y = 32, size = 5,
           colour = Blues[4], parse = TRUE, hjust = 0) +
  annotate("text", label = lm_eqn(a[,c(1,4)]), x = 2.75, y = 27, size = 5,
           colour = Blues[7], parse = TRUE, hjust = 0) +
  annotate("text", label = lm_eqn(a[,c(1,5)]), x = 4.75, y = 15, size = 5,
           colour = Reds[4], parse = TRUE, hjust = 0) +
  annotate("text", label = lm_eqn(a[,c(1,6)]), x = 4.75, y = 12.5, size = 5,
           colour = Reds[7], parse = TRUE, hjust = 0) +
  

  # theme(panel.grid.minor = element_line(colour="grey", size=0.5)) +
  ggtitle("a) Westerly wind in summer") 

subplot_a <- ggarrange(p1, ncol=1, nrow=1, legend="bottom")
print(subplot_a)
# export as .png with specific filename
filename = paste('ERA_CESM_CMIP5_seasonal_frequency_persistence_with_slope.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width =9, height = 9, units = 'in', res = 300)
dev.off()

rm(a_long, aa, i, p, s)

########################
p2 <- p1 + ggtitle('b) Frequency increase')
p3 <- p1 + ggtitle('c) Persistence increase')

g2 <- ggarrange(p1,ggarrange(p2,p3,ncol=1,nrow=2,heights=c(1,1),legend="bottom",common.legend=TRUE),legend="bottom",common.legend=TRUE)
dev.new()
print(g2)
# export as .png with specific filename
filename = paste('test.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width =16, height = 9, units = 'in', res = 300)
dev.off()







######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ analysing persistence for ERA, CESM and CMIP ~~~~~~~~~~~~~~ ########

# ok now I have three main data.frames
# calculate persistence measure for all five data sets
# (1) bins_ERA_all_1 <- ERA data for 1988-2017
# (2) bins_CESM_all_1 <- CESM data for 1988-2017
# (3) bins_CESM_all_2 <- CESM data for 2070-2099
# (4) bins_CMIP5_all_1 <- CMIP5 data for 1988-2017
# (5) bins_CMIP5_all_2 <- CMIP5 data for 2070-2099

# initialize persistency measure data.frame
persist <- data.frame(matrix(NA, nrow = 10, ncol = 5))
colnames(persist) <- c("weather_type", "spring", "summer", "autumn", "winter")
persist[,1] <- 1:10 # name of weather patterns

persist_ERA <- persist; persist_CESM_1 <- persist; persist_CESM_2 <- persist
persist_CMIP5_1 <- persist; persist_CMIP5_2 <- persist


for (e in 1:84){ # loop over all CESM ensembles
  old <- Sys.time() # get start time
  for (i in 1:10){ # loop over all weather_patterns
    for (s in 1:4){ # loop over all four seasons
    # loop over block of 20 data entries for each ensemble instead of the usual i+1 iteration loop 
    # we here use blocks of [1:20], [21:40], [...] etc.
    vec <- 20; block <- c((vec*e-19):(vec*e))
    
    # subset data
    a <- bins_ERA_perc_1[bins_ERA_perc_1[,6]==i,c(1,s+1)]
    b <- bins_CESM_perc_1[bins_CESM_perc_1[,6]==i,c(1,s+1)]
    a[,3] <- b[block,2]; rm(b)
    b <- bins_CESM_perc_2[bins_CESM_perc_2[,6]==i,c(1,s+1)]
    a[,4] <- b[block,2]; rm(b)
    b <- bins_CMIP5_perc_1[bins_CMIP5_perc_1[,6]==i,c(1,s+1)]
    a[,5] <- b[block,2]; rm(b)
    b <- bins_CMIP5_perc_2[bins_CMIP5_perc_2[,6]==i,c(1,s+1)]
    a[,6] <- b[block,2]; rm(b)
    colnames(a) <- c('period', 'era', 'cesm_1', 'cesm_2', 'cmip5_1', 'cmip5_2')
    # ok now all data combined in one data.frame
    a[a <= 0.01] <- NA # set all values lower than 1% to NA
    if (e <= 23){
      a <- na.omit(a)
    } else {
      a <- na.omit(a[,c(1:4)])
    }
    # here creating log regression model and writing slope information into allocated data.frame
    if(nrow(a) == 0){
      persist_CESM_1[i,s+1] <- NA
      persist_CESM_2[i,s+1] <- NA
      persist_CMIP5_1[i,s+1] <- NA
      persist_CMIP5_2[i,s+1] <- NA
    } else {
    fit1 <- lm(data = a, log(a[,3]) ~ a[,1]) # slope for CESM_1
    persist_CESM_1[i,s+1] <- fit1$coef[[2]] 
    fit1 <- lm(data = a, log(a[,4]) ~ a[,1]) # slope for CESM_2
    persist_CESM_2[i,s+1] <- fit1$coef[[2]] 
    if (e <= 23){
      fit1 <- lm(data = a, log(a[,5]) ~ a[,1]) # slope for CMIP5_1
      persist_CMIP5_1[i,s+1] <- fit1$coef[[2]] 
      fit1 <- lm(data = a, log(a[,6]) ~ a[,1]) # slope for CMIP5_2
      persist_CMIP5_2[i,s+1] <- fit1$coef[[2]] 
    }  
    }

    }
  }
  # expand data frame for each ensemble
  if (e == 1){
    persist_CESM_all_1 <- persist_CESM_1; persist_CESM_all_2 <- persist_CESM_2
    persist_CMIP5_all_1 <- persist_CMIP5_1; persist_CMIP5_all_2 <- persist_CMIP5_2
  } else if (e <= 23){
    persist_CESM_all_1 <- rbind(persist_CESM_all_1, persist_CESM_1)
    persist_CESM_all_2 <- rbind(persist_CESM_all_2, persist_CESM_2)
    persist_CMIP5_all_1 <- rbind(persist_CMIP5_all_1, persist_CMIP5_1)
    persist_CMIP5_all_2 <- rbind(persist_CMIP5_all_2, persist_CMIP5_2)
  } else {
    persist_CESM_all_1 <- rbind(persist_CESM_all_1, persist_CESM_1)
    persist_CESM_all_2 <- rbind(persist_CESM_all_2, persist_CESM_2)
  }
  new <- Sys.time() - old # calculate time difference
  print(new) # print in nice format
}

# clean up workspace
rm(persist, persist_CESM_1, persist_CESM_2, persist_CMIP5_1, persist_CMIP5_2)
  
# as the slope in ERA changes dependent on the ensemble in CESM, CMIP, I do it here
# separately with the ensemble mean
for (i in 1:10){ # loop over all weather_patterns
  for (s in 1:4){ # loop over all four seasons
    # subset dat
    a <- bins_ERA_perc_1[bins_ERA_perc_1[,6]==i,c(1,s+1)]
    b <- bins_CESM_perc_1[bins_CESM_perc_1[,6]==i,c(1,s+1)]
    c <- bins_CESM_perc_2[bins_CESM_perc_2[,6]==i,c(1,s+1)]
    e <- bins_CMIP5_perc_1[bins_CMIP5_perc_1[,6]==i,c(1,s+1)]
    f <- bins_CMIP5_perc_2[bins_CMIP5_perc_2[,6]==i,c(1,s+1)]
    for (d in 1:20){ # loop over consecutive duration up to 20 days
      a[d,3] <- mean(b[b[,1]==d,2],na.rm=TRUE)
      a[d,4] <- mean(c[c[,1]==d,2],na.rm=TRUE)
      a[d,5] <- mean(e[e[,1]==d,2],na.rm=TRUE)
      a[d,6] <- mean(f[f[,1]==d,2],na.rm=TRUE)
    }
    rm(b,c,e,f)
    colnames(a) <- c('period', 'era', 'cesm_1', 'cesm_2', 'cmip5_1', 'cmip5_2')
    # ok now all data combined in one data.frame
    a[a <= 0.01] <- NA # set all values lower than 1% to NA
    a <- na.omit(a)

    # here creating log regression model and writing slope information into allocated data.frame
    fit1 <- lm(data = a, log(a[,2]) ~ a[,1])
    persist_ERA[i,s+1] <- fit1$coef[[2]] # put information about slope (i.e. the persistency measure)
    # into allocated array 
  }
}

# clean workspace
rm(a, bins_CESM_all, figure, fit1, block, d, filename, i, new, old, s, vec)

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ creating persistence dataframe and saving workspace ~~~~~~~ ########
mean_pers_CESM <- data.frame(matrix(NA, nrow = 10, ncol = 9))
colnames(mean_pers_CESM) <- c("type", "spring_1", "summer_1", "autumn_1", "winter_1",
                              "spring_2", "summer_2", "autumn_2", "winter_2")
mean_pers_CESM[,1] <- 1:10; 
mean_pers_CMIP5 <- mean_pers_CESM # copy-paste data frame structure

for (s in 1:4){ # loop over all four seasons
  for (i in 1:10){ # loop over all ten circulation types
    # subset data for specific type and season, then calculate ensemble mean and put value
    # into allocated mean_pers_CESM_data frame
    mean_pers_CESM[i,s+1] <- mean(persist_CESM_all_1[persist_CESM_all_1[,1]==i,s+1], na.rm=TRUE)
    mean_pers_CMIP5[i,s+1] <- mean(persist_CMIP5_all_1[persist_CMIP5_all_1[,1]==i,s+1], na.rm=TRUE)
    # for future period, we shift the data by four columns to have
    #      past           future
    # .............. | ..............
    # next to each other
    mean_pers_CESM[i,s+5] <- mean(persist_CESM_all_2[persist_CESM_all_2[,1]==i,s+1], na.rm=TRUE)
    mean_pers_CMIP5[i,s+5] <- mean(persist_CMIP5_all_2[persist_CMIP5_all_2[,1]==i,s+1], na.rm=TRUE)
  }
}

# persistence change in percent
# slope decrease = increase in persistence!
summer <- -100 + mean_pers_CESM[,7]/(mean_pers_CESM[,3]/100)
summer
winter <- -100 + mean_pers_CESM[,9]/(mean_pers_CESM[,5]/100)
winter



# preparing percentage persistence changes for saving as R workspace
#     # a decrease in the persistency slope means actually a positive increase in the persistence
#     # -> in order to make that logical conclusion: multiply by *(-1)
persist_perc_CESM <- (persist_CESM_all_2 / (persist_CESM_all_1 / 100) - 100)*(-1) 
persist_perc_CMIP5 <- (persist_CMIP5_all_2 / (persist_CMIP5_all_1 / 100) - 100)*(-1) 
persist_perc_CESM[,1] <- persist_CESM_all_1[,1] # replace again 1st column with correct data
persist_perc_CMIP5[,1] <- persist_CMIP5_all_1[,1] # for all ten circulation types

# checking if what I do is correct
# calculate mean persistence change for westerly wind in summer
a <- persist_perc_CESM[persist_perc_CESM[,1]==1,3]; mean(a)  
b <- persist_perc_CMIP5[persist_perc_CMIP5[,1]==1,3]; mean(b)


# Save persistence data to file
path <- 'E:/Praktikum MeteoSchweiz/r_scripts/'
filename = paste('workspace_persistence_for_summary_figure_CESM_CMIP5')
save(mean_pers_CESM, mean_pers_CMIP5, persist_perc_CESM, persist_perc_CMIP5,
     file = paste(path, filename, '.RData',sep=''))
# Restore the object
# load(file = paste(path, filename, '.RData',sep=''))



######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine significance boxplots a), b), c), d) ~~~~~ ########

library(ggplot2)
library(grid)
library(gridExtra)
library(ggpubr)

# preliminary plotting
for (s in 1:4){ # loop over all seasons
  ERA <- persist_ERA[,c(1,s+1)] # ERA data 1980-2018
  ERA[,3] <- "period_1" # complete ERA data with dummy variables so it 
  # works for plotting (I do not have future ERA data)
  ERA[11:20,1] <- 1:10; ERA[11:20,2] <- NA # only dots for those ERA circulation types which are more frequent than 
  # 5% each season, i.e. we only plot dots for 
  # West (W), Southwest (SW), Northwest (NW) and North (N)
  ERA[11:20,3] <- "period_2"
  colnames(ERA) <- c("type", "variable", "value")
    
  CESM <- persist_CESM_all_1[,c(1,s+1)]           # subset data for CESM12-LE ensembles 1960 - 2017
  CESM[,3] <- persist_CESM_all_2[,c(s+1)]         # CESM12-LE ensembles 2042 - 2099
  colnames(CESM) <- c("type", "1", "2")     
  CESM <- melt(CESM, id = "type")                 # write into format used for plotting 
  colnames(CESM) <- c('type','value','variable')

  CMIP5 <- persist_CMIP5_all_1[,c(1,s+1)]         # CMIP5 ensembles 1960 - 2017
  CMIP5[,3] <- persist_CMIP5_all_2[,c(s+1)]       # CMIP5 ensembles 2042 - 2099
  colnames(CMIP5) <- c("type", "3", "4") # ensemble type 3 and 4 = CMIP5    
  CMIP5 <- melt(CMIP5, id = "type")
  colnames(CMIP5) <- c('type','value','variable')
  
  all_model <- rbind(CESM[CESM[,2]==1,], CMIP5[CMIP5[,2]==3,]) # only select past values for
                                                               # CESM and CMIP5
  
  # # subset to only include first four circulation types
  # ERA <- ERA[ERA[,1]<=4,]
  # all_model <- all_model[all_model[,1]<=4,]
  
  title_string <- c('c) Spring', 'c) Summer', 'd) Autumn', 'd) Winter')
  xlabel <- c('Circulation Type','Circulation Type',NULL,NULL)
  # xlabel <- NULL
  ylabel <- NULL
  
  assign(paste("p",s, sep=""), ggplot() +
    geom_boxplot(data = all_model[all_model[,1]<5,], aes(type, variable, fill=interaction(type, value)), 
      notch = FALSE, notchwidth = 0.5) +
    geom_point(data = ERA[ERA[,1]<5,], aes(x=type, y=variable, group = value, colour = value), 
      size = 3, position=position_dodge(width=0.0)) + # ERA dot between the two past boxplots
    scale_x_continuous(position = 'top', breaks=seq(1, 4.5, by = 1),
       labels=c('W','SW','NW','N')) +
    # labels=c("W","SW","NW","N","NE","E","SE","S","C","A")) +
    scale_y_continuous(breaks = seq(-5, 5, by = .25), limits = c(-1.25, -0.25)) + 
    scale_fill_manual(values = c(rep(antarctica[15],4), rep(antarctica[5],4),
                                 rep(antarctica[5],4),rep('#bb00bb',4)),
      label = c('CESM12-LE past','','','','CESM12-LE future','','','',
                'CMIP5 past','','','','CMIP5 future')) + 
      # label = c(NULL, 'CESM12-LE 1980-2018', NULL, "CESM12-LE 2062-2100")) +
    scale_color_manual(values = c("black", "white"), label = 'ERA40/-Interim', drop=FALSE) +
      labs(x = xlabel, y = 'Persistence measure \n (i.e. slope of regression fit)', colour = "grey") +
    # add annotation text and arrows
    geom_segment(aes(x = 4.75, y = -0.8, xend = 4.75, yend = -1.25),
      size = .75, arrow = arrow(length = unit(0.03, "npc"))) +
    geom_segment(aes(x = 4.75, y = -0.7, xend = 4.75, yend = -.25),
      size = .75, arrow = arrow(length = unit(0.03, "npc"))) +
    # geom_text(aes(x=4.75, label="more pers.", y=-1.2, hjust=0),
    #   colour="black", angle=90, vjust = 1.2, size = 4.5)+
    geom_text(aes(x=4.75, label="more persistent", y=-0.7, hjust=0),
      colour="black", angle=90, vjust = 1.2, size = 4.5)+
    geom_text(aes(x=4.75, label="less persistent", y=-0.8, hjust=1),
      colour="black", angle=90, vjust = 1.2, size = 4.5)+
    ggtitle(title_string[s])) # adding subtitle

  }
dev.new()
figure <- ggarrange(p2, p4, p1, p3, ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
annotate_figure(figure)
                # bottom = text_grob('Circulation Type',size=18),
                # left = text_grob("Persistence measure (i.e. slope of regression fit)", rot=90, size=18))

# export as .png with specific filename
filename = paste('OBS_CESM_persistence_measure_significance_plots_', method, '.png', sep="")
# export as a .pdf image
path <- 'E:/Praktikum MeteoSchweiz/figures/'
dev.copy(png, paste(path, filename, sep = "/"), 
         width = 16, height = 9, units = 'in', res = 300)
dev.off()

