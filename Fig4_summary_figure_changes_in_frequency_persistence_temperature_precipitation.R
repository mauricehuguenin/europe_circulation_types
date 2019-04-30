# Purpose: Summary plot with future changes to frequency, persistence, temperature and precipitation
#          to the main circulation types (W, NW, SW and N) during seasons
#          (2, 4) summer and winter, or during the seasons
#          (1, 3) spring and autumn.
#          In addition, create a second plot with future changes in all ensemble members
#          (boxplots) for the Supporting Information
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
#           Frequency and Persistence of Central European Circulation Types                     #
# My Name:  Maurice Huguenin-Virchaux                                                           #
# My Email: hmaurice@student.ethz.ch                                                            #
# Date:     19.03.2019, 10:12 CET                                                               #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# library(latex2exp) # package for LaTeX font in plots
library(base); library(ggplot2) # for plotting
library(reshape); library(magrittr); library(ggrepel) # for repelling (non-overlapping) labels
library(ggnewscale); library(shadowtext)
library(RColorBrewer) # for csutom colours
library(grid); library(gridExtra); library(ggpubr)


# choose whether to include either the first four most frequent circulation types or the rare ones
main <- 1             # or main <- 0    (1 = yes; create figure with W, SW, NW and N)
#                                         (0 = no; create figure with NE, E, SE, S, C and A)
seasons <- c(1,3)       # or seasons <- (1,3)  (2, 4) = create plots for summer & winter season
#                                         (1, 3) = create plots for spring & autumn season
######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ preamble and data load in ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

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
Reds <- brewer.pal(9, "Reds")      # red colour scale with 9 entries
Blues <- brewer.pal(9, "Blues")    # blue colour scale with 9 entries

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CESM and CMIP5 data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# initiating data.frame where I put in my stuff
CESM <- data.frame(matrix(NA, nrow = 10, ncol = 7))
CESM[,1] <- c('W','SW','NW','N','NE','E','SE','S','C','A')
colnames(CESM) <- c('type', 'temperature', 'precipitation', 
                    'frequency', 'persistence', 'period', 'model_type')
CMIP5 <- CESM  # copy-paste data frame structure

# # load in frequency of past and future data for CESM and CMIP5
path <- 'E:/Praktikum MeteoSchweiz/r_scripts/'
f1 = paste('workspace_frequency_for_summary_figure_CESM_CMIP5')
f2 = paste('workspace_persistence_for_summary_figure_CESM_CMIP5')
load(file = paste(path, f1, '.RData',sep=''))
load(file = paste(path, f2, '.RData',sep=''))
# delete those newly imported variables which I do not need this time around
rm (mean_freq_CESM, mean_freq_CMIP5, mean_pers_CESM, mean_pers_CMIP5)

freq_perc_CESM[,6] <- 1; colnames(freq_perc_CESM)[c(1,6)] <- c('type','model_type')
freq_perc_CMIP5[,6] <- 2; colnames(freq_perc_CMIP5)[c(1,6)] <- c('type','model_type')
# combine data from CESM and CMIP5
all_model_freq <- rbind(freq_perc_CESM,freq_perc_CMIP5)

persist_perc_CESM[,6] <- 1; colnames(persist_perc_CESM)[c(1,6)] <- c('type','model_type')
persist_perc_CMIP5[,6] <- 2; colnames(persist_perc_CMIP5)[c(1,6)] <- c('type','model_type')
# combine data from CESM and CMIP5
all_model_pers <- rbind(persist_perc_CESM,persist_perc_CMIP5)

# again, clean up workspace
rm(freq_perc_CESM, freq_perc_CMIP5, persist_perc_CESM, persist_perc_CMIP5)


for (s in seasons){ # plot figures for (2) summer and (4) winter season only
  if (s == 1){ # spring
    f3 = paste('domain_temp_diff_cmip5_season_',s,sep='')
    f4 = paste('domain_precip_diff_cmip5_season_',s,sep='')
    
    f5 = paste('domain_temp_diff_cesm_season_',s,sep='')
    f6 = paste('domain_precip_diff_cesm_season_',s,sep='')
    # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
    
    # ~~~~~ read in values for CESM
    temp <- read.table(file = paste(path, f5, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f6, '.txt',sep=''))
    
    
    temp[,85] <- 'temperature'; precip[,85] <- 'precipitation'
    
    CESM <- temp;
    CESM[11:20,] <- precip;
    CESM[,86] <- 1; CESM[,87] <- s
    colnames(CESM)[86] <- 'model_type'
    colnames(CESM)[1] <- 'type'
    colnames(CESM)[85] <- 'var'
    colnames(CESM)[87] <- 'season'
    
    # ~~~~~ read in values for CMIP5
    temp <- read.table(file = paste(path, f3, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f4, '.txt',sep=''))
    
    
    temp[,25] <- 'temperature'; precip[,25] <- 'precipitation'; 
    
    CMIP5 <- temp;
    CMIP5[11:20,] <- precip;
    CMIP5[,26] <- 2; CMIP5[,27] <- s
    colnames(CMIP5)[26] <- 'model_type'
    colnames(CMIP5)[1] <- 'type'
    colnames(CMIP5)[25] <- 'var'
    colnames(CMIP5)[27] <- 'season'
    
    
    # allocate data frame for summer
    CESM_first_season <- CESM; CMIP5_first_season <- CMIP5; rm(CESM, CMIP5, temp, precip)
    
  }            
  else if (s == 2){ # summer
    f3 = paste('domain_temp_diff_cmip5_season_',s,sep='')
    f4 = paste('domain_precip_diff_cmip5_season_',s,sep='')
    
    f5 = paste('domain_temp_diff_cesm_season_',s,sep='')
    f6 = paste('domain_precip_diff_cesm_season_',s,sep='')
    # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
    
    # ~~~~~ read in values for CESM
    temp <- read.table(file = paste(path, f5, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f6, '.txt',sep=''))
    
    
    temp[,85] <- 'temperature'; precip[,85] <- 'precipitation'
    
    CESM <- temp;
    CESM[11:20,] <- precip;
    CESM[,86] <- 1; CESM[,87] <- s
    colnames(CESM)[86] <- 'model_type'
    colnames(CESM)[1] <- 'type'
    colnames(CESM)[85] <- 'var'
    colnames(CESM)[87] <- 'season'
    
    # ~~~~~ read in values for CMIP5
    temp <- read.table(file = paste(path, f3, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f4, '.txt',sep=''))
    
    
    temp[,25] <- 'temperature'; precip[,25] <- 'precipitation'; 
    
    CMIP5 <- temp;
    CMIP5[11:20,] <- precip;
    CMIP5[,26] <- 2; CMIP5[,27] <- s
    colnames(CMIP5)[26] <- 'model_type'
    colnames(CMIP5)[1] <- 'type'
    colnames(CMIP5)[25] <- 'var'
    colnames(CMIP5)[27] <- 'season'
    
    
    # allocate data frame for summer
    CESM_first_season <- CESM; CMIP5_first_season <- CMIP5; rm(CESM, CMIP5, temp, precip)
    
  }
  else if (s == 3){ # autumn
    f3 = paste('domain_temp_diff_cmip5_season_',s,sep='')
    f4 = paste('domain_precip_diff_cmip5_season_',s,sep='')
    
    f5 = paste('domain_temp_diff_cesm_season_',s,sep='')
    f6 = paste('domain_precip_diff_cesm_season_',s,sep='')
    # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
    
    # ~~~~~ read in values for CESM
    temp <- read.table(file = paste(path, f5, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f6, '.txt',sep=''))
    
    
    temp[,85] <- 'temperature'; precip[,85] <- 'precipitation'
    
    CESM <- temp;
    CESM[11:20,] <- precip;
    CESM[,86] <- 1; CESM[,87] <- s
    colnames(CESM)[86] <- 'model_type'
    colnames(CESM)[1] <- 'type'
    colnames(CESM)[85] <- 'var'
    colnames(CESM)[87] <- 'season'
    
    # ~~~~~ read in values for CMIP5
    temp <- read.table(file = paste(path, f3, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f4, '.txt',sep=''))
    
    
    temp[,25] <- 'temperature'; precip[,25] <- 'precipitation'; 
    
    CMIP5 <- temp;
    CMIP5[11:20,] <- precip;
    CMIP5[,26] <- 2; CMIP5[,27] <- s
    colnames(CMIP5)[26] <- 'model_type'
    colnames(CMIP5)[1] <- 'type'
    colnames(CMIP5)[25] <- 'var'
    colnames(CMIP5)[27] <- 'season'
    
    
    # allocate data frame for summer
    CESM_second_season <- CESM; CMIP5_second_season <- CMIP5; rm(CESM, CMIP5, temp, precip)
    
  }            
  else if (s == 4){ # summer
    f3 = paste('domain_temp_diff_cmip5_season_',s,sep='')
    f4 = paste('domain_precip_diff_cmip5_season_',s,sep='')
    
    f5 = paste('domain_temp_diff_cesm_season_',s,sep='')
    f6 = paste('domain_precip_diff_cesm_season_',s,sep='')
    # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- # -- #
    
    # ~~~~~ read in values for CESM
    temp <- read.table(file = paste(path, f5, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f6, '.txt',sep=''))
    
    
    temp[,85] <- 'temperature'; precip[,85] <- 'precipitation'
    
    CESM <- temp;
    CESM[11:20,] <- precip;
    CESM[,86] <- 1; CESM[,87] <- s
    colnames(CESM)[86] <- 'model_type'
    colnames(CESM)[1] <- 'type'
    colnames(CESM)[85] <- 'var'
    colnames(CESM)[87] <- 'season'
    
    # ~~~~~ read in values for CMIP5
    temp <- read.table(file = paste(path, f3, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f4, '.txt',sep=''))
    
    
    temp[,25] <- 'temperature'; precip[,25] <- 'precipitation'; 
    
    CMIP5 <- temp;
    CMIP5[11:20,] <- precip;
    CMIP5[,26] <- 2; CMIP5[,27] <- s
    colnames(CMIP5)[26] <- 'model_type'
    colnames(CMIP5)[1] <- 'type'
    colnames(CMIP5)[25] <- 'var'
    colnames(CMIP5)[27] <- 'season'
    
    
    # allocate data frame for winter
    CESM_second_season <- CESM; CMIP5_second_season <- CMIP5; rm(CESM, CMIP5, temp, precip)
    
  }            
}
                   
  # combine data for two seasons                 
  CESM <- rbind(CESM_first_season,CESM_second_season); 
  CMIP5 <- rbind(CMIP5_first_season, CMIP5_second_season)               
                          
  a <- melt(CESM, id=c('type', 'model_type','var','season'))
  b <- melt(CMIP5, id=c('type', 'model_type','var','season'))
  all_model <- rbind(a, b); rm(a, b)


  # here in this part I create the ensemble mean data frame
  # I know this is a horrible way to do it with all these copy-paste fragements but time is 
  # running out (only 4 more days to go until 30th APril 2019) and it does the job
  # ...besides I also need to create more figures for the supplementary information
  # and hadn't even written anything during the last three weeks so far
  
  # tl;dr: I AM STRESSED.
  
  all_model_mean <- data.frame(matrix(NA, nrow = 20, ncol = 10))
  colnames(all_model_mean) <- c('type',paste('frequency_s',seasons[1],sep=''),
                                     paste('frequency_s',seasons[2],sep=''),
                                     paste('persistence_s',seasons[1],sep=''),
                                     paste('persistence_s',seasons[2],sep=''),
                                     paste('temperature_s',seasons[1],sep=''),
                                     paste('temperature_s',seasons[2],sep=''),
                                     paste('precipitation_s',seasons[1],sep=''),
                                     paste('precipitation_s',seasons[2],sep=''),'model_type')
  all_model_mean[1:10,1] <- 1:10;   all_model_mean[1:10,10] <- 1; # CESM data
  all_model_mean[11:20,1] <- 1:10;   all_model_mean[11:20,10] <- 2; # CESM data
  # calculate ensemble means for ensemble plot further down

  # replace Inf values with NA
  all_model[all_model==Inf] <- NA
  all_model_freq[all_model_freq==Inf] <- NA
  all_model_pers[all_model_pers==Inf] <- NA
  
  for (i in 1:10){
    # ensemble mean temperature for CESM in summer
    all_model_mean[i,6] <- mean(all_model[all_model[,1] == i & # select circulation type
                                all_model[,2] == 1 & # select model type (CESM/CMIP5)
                                all_model[,3] == 'temperature' & # select variable
                                all_model[,4] == seasons[1],6],na.rm=TRUE) # select season
                           # and calculate ensemble mean
    all_model_mean[i,7] <- mean(all_model[all_model[,1] == i & 
                                  all_model[,2] == 1 & 
                                  all_model[,3] == 'temperature' & 
                                  all_model[,4] == seasons[2],6],na.rm=TRUE) 
    all_model_mean[i+10,6] <- mean(all_model[all_model[,1] == i & 
                                  all_model[,2] == 2 & 
                                  all_model[,3] == 'temperature' & 
                                  all_model[,4] == seasons[1],6],na.rm=TRUE) 
    all_model_mean[i+10,7] <- mean(all_model[all_model[,1] == i & 
                                  all_model[,2] == 2 & 
                                  all_model[,3] == 'temperature' & 
                                  all_model[,4] == seasons[2],6],na.rm=TRUE)
    
    all_model_mean[i,8] <- mean(all_model[all_model[,1] == i & 
                                  all_model[,2] == 1 & 
                                  all_model[,3] == 'precipitation' & 
                                  all_model[,4] == seasons[1],6],na.rm=TRUE)
    all_model_mean[i,9] <- mean(all_model[all_model[,1] == i & 
                                all_model[,2] == 1 & 
                                all_model[,3] == 'precipitation' & 
                                all_model[,4] == seasons[2],6],na.rm=TRUE) 
    all_model_mean[i+10,8] <- mean(all_model[all_model[,1] == i & 
                                all_model[,2] == 2 & 
                                all_model[,3] == 'precipitation' & 
                                all_model[,4] == seasons[1],6],na.rm=TRUE) 
    all_model_mean[i+10,9] <- mean(all_model[all_model[,1] == i & 
                                all_model[,2] == 2 & 
                                all_model[,3] == 'precipitation' & 
                                all_model[,4] == seasons[2],6],na.rm=TRUE)
    
    # frequency CESM
    all_model_mean[i,2] <- mean(all_model_freq[all_model_freq[,1] == i & 
                                                 all_model_freq[,6] == 1,seasons[1]+1],na.rm=TRUE)
    all_model_mean[i,3] <- mean(all_model_freq[all_model_freq[,1] == i & 
                                                 all_model_freq[,6] == 1,seasons[2]+1],na.rm=TRUE)
    # persistence CESM
    all_model_mean[i,4] <- mean(all_model_pers[all_model_pers[,1] == i & 
                                                 all_model_pers[,6] == 1,seasons[1]+1],na.rm=TRUE)
    all_model_mean[i,5] <- mean(all_model_pers[all_model_pers[,1] == i & 
                                                 all_model_pers[,6] == 1,seasons[2]+1],na.rm=TRUE)
    # frequency CMIP5
    all_model_mean[i+10,2] <- mean(all_model_freq[all_model_freq[,1] == i & 
                                                 all_model_freq[,6] == 2,seasons[1]+1],na.rm=TRUE)
    all_model_mean[i+10,3] <- mean(all_model_freq[all_model_freq[,1] == i & 
                                                 all_model_freq[,6] == 2,seasons[2]+1],na.rm=TRUE)
    # persistence CMIP5
    all_model_mean[i+10,4] <- mean(all_model_pers[all_model_pers[,1] == i & 
                                                 all_model_pers[,6] == 2,seasons[1]+1],na.rm=TRUE)
    all_model_mean[i+10,5] <- mean(all_model_pers[all_model_pers[,1] == i & 
                                                 all_model_pers[,6] == 2,seasons[2]+1],na.rm=TRUE)
    
  }
  

  
  # subset data, only choose W, SW, NW and N for the main figures in the manuscript
  # else for the supplementary material choose the remaining, rare circulation types
  if (main == 1){
    # combine future W, SW, NW and N from both models
    all_model <- all_model[all_model[,1] <= 4,]
    all_model_pers <- all_model_pers[all_model_pers[,1] <= 4,]
    all_model_freq <- all_model_freq[all_model_freq[,1] <= 4,]
    all_model_mean <- all_model_mean[all_model_mean[,1] <= 4,]
    # replace circulation type labels with actual alphabetic indices
    # i.e. 'W', 'SW', 'NW', and 'N', etc.
    #                          repeat circulation types two times, for CESM and CMIP5
    all_model_mean[,1] <- rep(c('W','SW','NW','N'),2)
    
  } else if (main == 0){
    # combine future NE, E, SE, S, C and A from both models 
    all_model <- all_model[all_model[,1] > 4,]
    all_model_pers <- all_model_pers[all_model_pers[,1] > 4,]
    all_model_freq <- all_model_freq[all_model_freq[,1] > 4,]
    all_model_mean <- all_model_mean[all_model_mean[,1] > 4,]
    all_model_mean[,1] <- rep(c('NE','E','SE','S','C','A'),2)
    
  }


rm(CESM,CMIP5,CESM_first_season,CESM_second_season,
   CMIP5_first_season,CMIP5_second_season,f1,f2,f3,f4,f5,f6,i)


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine for all 8 subplots ~~~~~~~~~~~~~~~~~~~~~~~~ ########
for (e in 1:8){ # loop over the four seasons; assign correct data each loop iteration

    caption <- c('a)','b)','c)','d)','e)','f)','g)','h)')
    xlabel <- c('Circulation type')
    
  # subset correct data for that plot       2+1
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # frequency change -- SUMMER / SPRING
      if (e == 1){ 
        # subset model data
        all_model_sub <- all_model_freq[,c(1,seasons[1]+1,6)]; colnames(all_model_sub)[2] <- 'value'
        plot_limits <- c(-40, 40); label_ticks <- 20
        ylabel <- 'Change in \n frequency [%]'
  # frequency change -- WINTER / AUTUMN
      } else if (e == 2){ 
        all_model_sub <- all_model_freq[,c(1,seasons[2]+1,6)]; colnames(all_model_sub)[2] <- 'value'
        plot_limits <- c(-40, 40); label_ticks <- 20
        ylabel <- 'Change in \n frequency [%]'
        
  # persistence change -- SUMMER / SPRING        
      } else if (e == 3){ 
        all_model_sub <- all_model_pers[,c(1,seasons[1]+1,6)]; colnames(all_model_sub)[2] <- 'value'
        plot_limits <- c(-40, 40); label_ticks <- 20
        ylabel <- 'Change in \n persistence [%]'
  # persistence change -- WINTER / AUTUMN
      } else if (e == 4){ 
        all_model_sub <- all_model_pers[,c(1,seasons[2]+1,6)]; colnames(all_model_sub)[2] <- 'value'
        plot_limits <- c(-40, 40); label_ticks <- 20
        ylabel <- 'Change in \n persistence [%]'
        
  # temperature change -- SUMMER / SPRING 
      } else if (e == 5){ 
        all_model_sub <- all_model[all_model[,3]=='temperature' & all_model[,4]==seasons[1],]
        plot_limits <- c(0, 10); label_ticks <- 2
        ylabel <- 'Change in \n temperature [°C]'
  # temperature change -- WINTER / AUTUMN
      } else if (e == 6){ 
        all_model_sub <- all_model[all_model[,3]=='temperature' & all_model[,4]==seasons[2],]
        plot_limits <- c(0, 10); label_ticks <- 2
        ylabel <- 'Change in \n temperature [°C]'
        
  # precipitation change -- SUMMER / SPRING        
      } else if (e == 7){ 
        all_model_sub <- all_model[all_model[,3]=='precipitation' & all_model[,4]==seasons[1],]
        plot_limits <- c(-60, 60); label_ticks <- 20
        ylabel <- 'Change in \n precipitation [%]'
  # precipitation change -- WINTER / AUTUMN
      } else if (e == 8){ 
        all_model_sub <- all_model[all_model[,3]=='precipitation' & all_model[,4]==seasons[2],]
        plot_limits <- c(-60, 60); label_ticks <- 20
        ylabel <- 'Change in \n precipitation [%]'
      }
      
      # small data frame for plotting mean values
      m_CESM <- all_model_mean[all_model_mean[,10]==1,c(1,e+1)];
      m_CMIP5 <- all_model_mean[all_model_mean[,10]==2,c(1,e+1)]; 
      if (main == 1){
        m_CESM[,1] <- 1:4        # four circulation types in main plot
        m_CMIP5[,1] <- 1:4       # W, SE, NW and N
        new_col <- c(rep(Blues[7],4), rep(Reds[7],4)) # colours
        types_char <- c('W','NW','SW','N') # labels for circulation types
        anzahl_types <- 4
      } else if (main == 0){
        m_CESM[,1] <- 5:10        # six circulation types in rare plot
        m_CMIP5[,1] <- 5:10       # NE, E, SE, S, C and A
        new_col <- c(rep(Blues[7],6), rep(Reds[7],6)) # colours
        types_char <- c('NE','E','SE','S','C','A') # labels for circulation types
        anzahl_types <- 6
      }
      colnames(m_CESM)[2] <- 'value'; colnames(m_CMIP5)[2] <- 'value'
      
      # here plot with ggplot function
      assign(paste("g",e, sep=""), ggplot() +
        # boxplot from data which has the correct format
        # interaction to plot both CESM and CMIP5 side by side next to each other for each
        # circulation type
          geom_boxplot(data = all_model_sub, aes(x=type, y=value, fill = interaction(type, model_type), 
              middle = mean(value)), outlier.shape=1, outlier.size = 1) +
          # plot ensemble mean as a point in the boxplot - median is the horizontal line
            geom_point(data = m_CESM, aes(x=type-0.185,y=value),color=Blues[3]) +
            geom_point(data = m_CMIP5, aes(x=type+0.185,y=value),color=Reds[3]) +
            # insert horizontal line at zero 
            geom_hline(yintercept=0, color = 'grey', size = .3) +
            # replace labels on x-axis
            scale_x_continuous(breaks=seq(m_CESM[1,1], m_CESM[1,1]+anzahl_types-1, by = 1), # either 4 or 6 entries for
              labels=types_char) +                                   # the circulation type labels
            # adjusted scale for y-axis
            scale_y_continuous(breaks = seq(-100, 100, by = label_ticks), limits=plot_limits[c(1,2)]) + 
            # labels; no label on x-axis since it's the same as in lower subplot
            labs(x = xlabel, y = ylabel, colour = "grey") +
            # fill in colours and plot legends; then in Microsoft paint adjust legend to middle and so on
            scale_fill_manual(values = new_col, 
                              label = c('CESM future','','','','','','CMIP5 future','')) +
            ggtitle(caption[e])) # adding subtitle
    

  }
    
if (seasons[1] == 1){
  main_title <- c("          Spring                                              Autumn")
} else if (seasons[1] == 2){
  main_title <- c("          Summer                                              Winter")
}   

    
dev.new()
  
  figure <- ggarrange(g1,g2,g3,g4,g5,g6,g7,g8, ncol=2, nrow=4, widths = 1.5, heights = 1,legend="bottom", common.legend=TRUE)
  annotate_figure(figure,
                  top = text_grob(main_title, rot=0, size=20))

    # export as .png with specific filename
    filename = paste('Summary_figure_boxplots_seasons_s',
                     seasons[1],'_s',seasons[2],'_main_',main,'.png', sep="")
    # export as a .pdf image
    path_out <- 'E:/Praktikum MeteoSchweiz/figures/summary_figure/'
    dev.copy(png, paste(path_out, filename, sep = "/"),
             width = 9, height = 12, units = 'in', res = 300)
    dev.off()


######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ plotting routine ensemble mean ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########
# adapting ggplot theme to suit my needs
    theme_set(theme_bw() + # black-and-white theme as a base
                theme(axis.line = element_line(colour = "black"),
                      panel.grid.major.y = element_line(colour = "grey"),
                      panel.grid.major = element_line(size = 0.1),
                      panel.grid.major.x = element_line(colour = "grey"),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      legend.title = element_text(size=16),
                      plot.title = element_text(size = 16),
                      axis.title.x = element_text(size = 16),
                      axis.title.y = element_text(size = 16),
                      legend.text=element_text(size=16),
                      legend.position = "right",
                      legend.box="vertical",
                      panel.background = element_blank(), 
                      aspect.ratio=1/1,
                      axis.text.x = element_text(size= 16), # set size of labels relative to
                      # default which is 11
                      axis.text.y = element_text(size= 16)))
    
    title_str <- c('a)','a)','b)','b)')
    title_str2 <- c('c)','c)','d)','d)')
    
    # plot limits and ticks
    if (main == 1 & seasons[1] == 2){ # plot limits for main types in summer & winter
      plot_limits <- c(-10,12,-23,14) # limits axis in frequency/persistence plot
                                      # range of frequency -> [-10%, 12%]
                                      # range of persistence -> [-23%, 14%]
      plot_limits2 <- c(-25,20,0,7)   # limit axis of temperature/precipitation plot
      model_names <- c('CESM future','CMIP5 future') # legend labels
      label_ticks <- c(5,10,10,2)     # label spacing on x- and y-axis
    } else if (main == 1 & seasons[1] == 1){ # plot limits for main types in spring & autumn
        plot_limits <- c(-10,12,-23,14) 
        plot_limits2 <- c(-25,20,0,10)
        model_names <- c('CESM future','CMIP5 future')
        label_ticks <- c(5,10,10,2) 
    } else if (main == 0 & seasons[1] == 2 | seasons[1] == 1){ # plot limits for rare types in summer & winter
      plot_limits <- c(-50,25,-50,25) 
      plot_limits2 <- c(-40,60,0,8)
      model_names <- c('','') # legend labels
      label_ticks <- c(25,25,20,2) 
    }
    
    
for (s in seasons){
  if (s == 1 | s == 2){
    model_data <- all_model_mean[,c(1,2,4,6,8,10)]
  } else if (s == 3 | s == 4){
    model_data <- all_model_mean[,c(1,3,5,7,9,10)]
  }
  # new column names to match code below
  colnames(model_data) <- c('type','frequency','persistence',
                            'temperature','precipitation','model_type')
  label_colours <- c(rep(Blues[7],anzahl_types), rep(Reds[7],anzahl_types)) # green and purple colours
  
assign(paste("g",s, sep=""), ggplot() +
  # vertical lines through the origin of the plot (0, 0)
  geom_segment(aes(x=-Inf,y=0,xend=Inf,yend=0),size=1, color='grey') +
  geom_segment(aes(x=0,y=-Inf,xend=0,yend=Inf),size=1, color='grey') +
  # labels of the circulation type in x/y (frequency/persistence) plot
  geom_label(data = model_data, aes(x=round(frequency,0),y=persistence, label=type), 
    # colour labeling according to the data (CESM = blue, CMIP5 = red)
    color=label_colours,fill='white',size=5,fontface='bold', # shading, text colour and size of labels
    # adjust labels inside the rectangular box
    hjust='inward',vjust='inward') +
  # manual colours
  scale_color_manual(values = c('black','white'), guide = FALSE) +
  ggtitle(title_str[s]) + # title     
  # axis labels over two lines with '\n'
  labs(y='Change in persistence [%]',x='Change in frequency [%]',
    shape='Change in \n precipitation [%]',
    fill='Change in \n temperature [°C]') + # axis labels
  # set y axis limits and breaks
  scale_y_continuous(breaks=seq(-100, 100, by = label_ticks[1]), limits=plot_limits[c(1,2)]) + # x-axis range
  # set x-axis limits and breaks
  scale_x_continuous(breaks=seq(-100, 100, by = label_ticks[2]),limits=plot_limits[c(3,4)]) + # y-axis range
  # theme(axis.text.x = element_text(hjust=+50)) +
  theme(axis.line = element_blank()) + # set x- and y-axis (the original ones) transparent
  geom_label_repel(aes(x=-20,y=11.5, label=model_names[2]),
    fill='white',color = label_colours[5],size = 5,fontface='bold',
    hjust=0.5,point.padding = NA,segment.color='grey') +
  geom_label_repel(aes(x=10,y=11.5, label=model_names[1]),
    fill='white',color = label_colours[1],size = 5,fontface='bold',
    hjust=0.5, point.padding = NA,segment.color='grey') +

theme(legend.key.width = unit(1.2,'cm'))) # set width of colourbar in the legend
    
# for tempearature and precipitation subplots same procedure as above
assign(paste("h",s, sep=""), ggplot() +
  # vertical line through the origin of the plot as guidance for the eye
  geom_segment(aes(x=-Inf,y=0,xend=Inf,yend=0),size=1, color='grey') +
  geom_segment(aes(x=0,y=-Inf,xend=0,yend=Inf),size=1, color='grey') +
  geom_label(data = model_data, aes(x=temperature,y=precipitation, label=type), 
            color=label_colours,fill='white',size=5,fontface='bold') + # shading, text colour and size of labels
  scale_color_manual(values = c('black','white'), guide = FALSE) +
  ggtitle(title_str2[s]) + # title     
  labs(y='Change in precipitation [%]',x='Change in temperature [°C]',
      shape='Change in \n precipitation [%]',
      fill='Change in \n temperature [°C]') + # axis labels
  # set y axis limits and breaks
  scale_y_continuous(breaks=seq(-100, 100, by = label_ticks[3]), limits=plot_limits2[c(1,2)]) + # x-axis range
  # set x-axis limits and breaks
  scale_x_continuous(breaks=seq(-100, 100, by = label_ticks[4]),limits=plot_limits2[c(3,4)]) + # y-axis range
  theme(axis.line = element_blank()) + # set x- and y-axis (the original ones) transparent
  theme(legend.key.width = unit(1.2,'cm'))) # set width of colourbar in the legend
}  



# arrange subplots to create a big one with a), b), c) and d)
if (seasons[1] == 2){
  dev.new()
  figure <- grid.arrange(arrangeGrob(g2,g4,top=textGrob('      Summer                                              Winter',hjust=0.5,gp=gpar(fontsize=20)),ncol=2), 
                         arrangeGrob(h2,h4, ncol=2),nrow = 2)
} else if (seasons[1] == 1){
  dev.new()
  figure <- grid.arrange(arrangeGrob(g1,g3,top=textGrob('      Spring                                              Autumn',hjust=0.5,gp=gpar(fontsize=20)),ncol=2), 
                         arrangeGrob(h1,h3, ncol=2),nrow = 2)
}

# export as .png with specific filename
filename = paste('Summary_figure_means_seasons_s',
                 seasons[1],'_s',seasons[2],'_main_',main,'.png', sep="")
# export as a .pdf image
path_out <- 'E:/Praktikum MeteoSchweiz/figures/summary_figure/'
dev.copy(png, paste(path_out, filename, sep = "/"),
         width = 9, height = 9, units = 'in', res = 300)
dev.off()












    
    
    
    
    
    
    
    
    
    
    
    
    