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
library(base)
library(ggplot2) # for plotting
library(reshape)
library(magrittr)
library(ggrepel)
library(ggnewscale)
library(shadowtext)
library(RColorBrewer)
library(grid)
library(gridExtra)
library(ggpubr)


# choose whether to include either the first four most frequent circulation types or the rare ones
main <- 1               # or main <- 0    (1 = yes; create figure with W, SW, NW and N)
                        #                 (0 = no; create figure with NE, E, SE, S, C and A)
seasons <- c(2,4)       # or seasons <- (1,3)  (2, 4) = create plots for summer & winter season
                        #                      (1, 3) = create plots for spring & autumn season

######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ preamble and data load in ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

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


# colour bar 
# red - white - blue colourbar
RdBu_short <- rev(c('#053061','#124C8F','#2166AC','#307DB9','#4393C3',
                '#68ADD1','#92C5DE','#B4D7E8','#D1E5F0','#E9F1F5',
                '#F7F7F7','#FBEEE6','#FDDBC7','#FAC3A5','#F4A582',
                '#E78465','#D6604D','#C63839','#B2182B','#920823',
                '#67001F'))
                # rev = reverse or flip colours from right to left
                # so that it goes: blue - white - red
Reds <- brewer.pal(9, "Reds")      # red colour scale with 9 entries
Blues <- brewer.pal(9, "Blues")    # blue colour scale with 9 entries



######## ~~~~~~~~~~~~~~~~~~~~~~~~~~ load in CESM and CMIP5 data ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ########

# initiating data.frame where I put in my stuff
CESM <- data.frame(matrix(NA, nrow = 10, ncol = 7))
CESM[,1] <- c('W','SW','NW','N','NE','E','SE','S','C','A')
colnames(CESM) <- c('type', 'temperature', 'precipitation', 
                    'frequency', 'persistence', 'period', 'model_type')
CMIP5 <- CESM  # copy-paste data frame structure

# load in frequency of past and future data for CESM and CMIP5
path <- 'E:/Praktikum MeteoSchweiz/r_scripts/'
f1 = paste('workspace_frequency_for_summary_figure_CESM_CMIP5')
f2 = paste('workspace_persistence_for_summary_figure_CESM_CMIP5')
load(file = paste(path, f1, '.RData',sep=''))
load(file = paste(path, f2, '.RData',sep=''))

## change persistence and frequency into percentage values, past period = 100%
for(i in 1:10){
  for(s in 1:4){
    # a decrease in the persistency slope means actually a positive increase in the persistence
    # -> in order to make that logical conclusion: multiply by *(-1)
    mean_pers_CESM[i,s+5] <- (mean_pers_CESM[i,s+5] / (mean_pers_CESM[i,s+1] / 100) - 100)*(-1)
    mean_pers_CMIP5[i,s+5] <- (mean_pers_CMIP5[i,s+5] / (mean_pers_CMIP5[i,s+1] / 100) - 100)*(-1)
    mean_freq_CESM[i,s+5] <- mean_freq_CESM[i,s+5] / (mean_freq_CESM[i,s+1] / 100) - 100
    mean_freq_CMIP5[i,s+5] <- mean_freq_CMIP5[i,s+5] / (mean_freq_CMIP5[i,s+1] / 100) - 100
  }
}

for (s in seasons){ # plot figures for (2) summer and (4) winter season only
  if (s == 1){ # spring
    # [T] <- hard-coded from my spatial maps created in MATLAB
    CESM[1:10,2] <- c(0.19,1.29,0.81,-1.31,-0.81,-0.15,0.6,1.17,-1.28,2.25)
    CESM[11:20,2] <- c(3.92,5.05,3.05,2.83,3.74,4.63,4.92,5.24,2.62,6.64)
    CMIP5[1:10,2] <- c(-0.08,1.17,-1.14,-1.54,-0.41,1.01,1.74,1.77,-1.55,3.51)
    CMIP5[11:20,2] <- c(3.11,4.48,1.94,1.66,3.03,4.15,5.07,5.01,2.03,6.31)
    # [P]
    CESM[1:10,3] <- c(1.97,2.87,1.32,0.83,1.03,1.8,2.69,3.49,3.02,0.92)
    CESM[11:20,3] <- c(1.75,2.8,1.02,0.77,1.08,1.88,2.74,3.6,3.49,0.7)
    CMIP5[1:10,3] <- c(2.14,2.79,1.57,1.23,1.52,2.27,2.92,3.32,3.53,0.92)
    CMIP5[11:20,3] <- c(2.08,2.84,1.48,1.2,1.54,2.56,3,3.48,3.97,0.83)
    title_str <- 'a)'
    title_str2 <- 'c)'
    visibility_colours <- c('white','black','black')
  } 
  else if (s == 2){ # summer
    f3 = paste('domain_temp_diff_cmip5_season_',s,sep='')
    f4 = paste('domain_precip_diff_cmip5_season_',s,sep='')
    
    f5 = paste('domain_temp_diff_cesm_season_',s,sep='')
    f6 = paste('domain_precip_diff_cesm_season_',s,sep='')
    
    temp <- read.table(file = paste(path, f3, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f4, '.txt',sep=''))
    
    # [SAT] as a unit of [°C] change
    CMIP5[1:10,2] <- round(rowMeans(temp[,2:24],na.rm=TRUE),2) # first column = circulation type
    # [Pr] as a unit of [%] change
    CMIP5[1:10,3] <- round(rowMeans(precip[,2:24],na.rm=TRUE),2)
    
    temp <- read.table(file = paste(path, f5, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f6, '.txt',sep=''))
    
    # [SAT] as a unit of [°C] change
    CESM[1:10,2] <- round(rowMeans(temp[,2:84],na.rm=TRUE),2) # first column = circulation type
    # [Pr] as a unit of [%] change
    CESM[1:10,3] <- round(rowMeans(precip[,2:84],na.rm=TRUE),2)
    
    
    # [T] <- hard-coded from my spatial maps created in MATLAB
    # difference = future - past data
    # CESM[1:10,2] <- c(6.06,6.04,5.79,5.73,6.15,6.26,6.25,5.39,4.04,8.91) - 
    #                 c(0.21,0.49,-0.53,-0.82,-0.42,-0.26,-0.08,-0.58,-2.04,1.7)
                    
    # CMIP5[1:10,2] <- c(0.01,0.6,-0.68,-0.6,0,0.31,0.42,0.47,-1.67,2.1)
    # CMIP5[11:20,2] <- c(4.96,5.38,4.16,4.03,4.6,5.03,5.18,5.05,2.59,7.51)
    # [P]
    # CESM[1:10,3] <- c(1.26,2.13,0.77,0.9,1.4,2.04,2.34,2.95,2.98,0.84) - 
    #                 c(1.42,2.43,0.89,1.02,1.62,2.19,2.58,3.39,3.36,1.1)
                    
    # CMIP5[1:10,3] <- c(1.9,2.83,1.35,1.4,1.95,2.68,3.12,3.35,4.01,1.3)
    # CMIP5[11:20,3] <- c(1.53,2.5,1.05,1.18,1.72,2.39,2.67,3.12,3.78,0.96)
    title_str <- 'a)'
    title_str2 <- 'c)'
    visibility_colours <- c('black','black','white')
    # inside the triangles
  } 
  else if (s == 3){ # autumn
      # [T] <- hard-coded from my spatial maps created in MATLAB
      CESM[1:10,2] <- c(0.7,1.14,-0.7,-2.19,-2.42,-2.02,-1.28,-0.2,-1.76,0.34)
      CESM[11:20,2] <- c(4.94,5.15,3.95,3.23,3.86,4.21,4.36,4.38,3.16,5.56)
      CMIP5[1:10,2] <- c(0.41,1.23,-0.95,-1.99,-1.5,-1.04,0.06,0.84,-2.02,1.73)
      CMIP5[11:20,2] <- c(4.37,5,3.12,2.36,3.32,3.76,3.71,4.41,2.74,5.75)
      # [P]
      CESM[1:10,3] <- c(2.22,3.97,1.19,0.73,0.82,1.57,2.87,4.74,3.35,1.05)
      CESM[11:20,3] <- c(2.06,4.28,1.02,0.72,0.94,1.58,2.92,5.27,3.82,0.84)
      CMIP5[1:10,3] <- c(2.73,3.41,1.63,1.1,1.2,1.86,2.81,4.08,3.77,0.75)
      CMIP5[11:20,3] <- c(2.22,3.55,1.42,1.05,1.21,1.61,3,4.51,4.51,0.53)
      title_str <- 'b)'
      title_str2 <- 'd)'
      visibility_colours <- c('black','black','black','white')
  }
  else if (s == 4){ # winter
    f3 = paste('domain_temp_diff_cmip5_season_',s,sep='')
    f4 = paste('domain_precip_diff_cmip5_season_',s,sep='')
    
    f5 = paste('domain_temp_diff_cesm_season_',s,sep='')
    f6 = paste('domain_precip_diff_cesm_season_',s,sep='')
    
    temp <- read.table(file = paste(path, f3, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f4, '.txt',sep=''))
    
    # [SAT] as a unit of [°C] change
    CMIP5[1:10,2] <- round(rowMeans(temp[,2:24],na.rm=TRUE),2) # first column = circulation type
    # [Pr] as a unit of [%] change
    CMIP5[1:10,3] <- round(rowMeans(precip[,2:24],na.rm=TRUE),2)
    
    temp <- read.table(file = paste(path, f5, '.txt',sep=''))
    # colnames(temp)[1] <- 'type'
    precip <- read.table(file = paste(path, f6, '.txt',sep=''))
    
    # [SAT] as a unit of [°C] change
    CESM[1:10,2] <- round(rowMeans(temp[,2:84],na.rm=TRUE),2) # first column = circulation type
    # [Pr] as a unit of [%] change
    CESM[1:10,3] <- round(rowMeans(precip[,2:84],na.rm=TRUE),2)
    
    title_str <- 'b)'
    title_str2 <- 'd)'
    visibility_colours <- c('white','black','black','white')
  }
  
  # # convert to temperature and precipitation change by calculating future - past period
  # CESM[11:20,2] <- CESM[11:20,2] - CESM[1:10,2]
  # CESM[11:20,3] <- CESM[11:20,3] - CESM[1:10,3]
  # CMIP5[11:20,2] <- CMIP5[11:20,2] - CMIP5[1:10,2]
  # CMIP5[11:20,3] <- CMIP5[11:20,3] - CMIP5[1:10,3]

  # frequency in interval [-6, 6] degrees Celsius
  # difference = future - past data
  CESM[1:10,4] <- unlist(mean_freq_CESM[,s+5])              
  CMIP5[1:10,4] <- unlist(mean_freq_CMIP5[,s+5])

  # persistence in interval [-6, 6] degrees Celsius
  # difference = future - past data
  CESM[1:10,5] <- unlist(mean_pers_CESM[,s+5]) 
  CMIP5[1:10,5] <- unlist(mean_pers_CMIP5[,s+5])

  # add columns with factor variable: 
  # column 6: (2) = difference
  CESM[1:10,6] <- 2
  CMIP5[1:10,6] <- 2
  # column 7: (1) CESM and (2) CMIP5
  CESM[,7] <- 1; CMIP5[,7] <- 2


# function from the web which allows to round to a given interval of pre-defined
# values, e.g. round to the nearest of [1, 5, 10, 20, 50]
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
  iround <- function(x, interval){
    ## Round numbers to desired interval
    ##
    ## Args:
    ##   x:        Numeric vector to be rounded
    ##   interval: The interval the values should be rounded towards.
    ## Retunrs:
    ##   a numeric vector with x rounded to the desired interval.
    ##
    ## example:
    ## a <- iround(0:100, c(1, 5, 10, 20, 50))
    interval[ifelse(x < min(interval), 1, findInterval(x, interval))]
  }
  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
  
  # round persistence change to absolute values to colour frequency value with more visibility
  # i.e. frequency changes between [-5, 0, 5]% will get a black colour
  # and those values smaller and bigger than [-10, 10] will get coloured white
  a <- round(abs(CESM[,2]),0); a
  b <- round(abs(CMIP5[,2]),0); b
  
  for (i in 1:nrow(CESM)){
    if (a[i] <= 5){
      CESM[i,8] <- 'black'
    } else {
      CESM[i,8] <- 'white'
    }
  }  
  
  for (i in 1:nrow(CMIP5)){
    if (b[i] <= 5){
      CMIP5[i,8] <- 'black'
    } else {
      CMIP5[i,8] <- 'white'
    }
  }
  colnames(CESM)[8] <- 'visibility'
  colnames(CMIP5)[8] <- 'visibility'
  
  if (main == 1){
    # combine future W, SW, NW and N from both models
    model_data <- rbind(CESM[1:4,], CMIP5[1:4,]) 
    
    # remove sign of frequency and store it as the 9th column further down
    model_data[,9] <- c(CESM[1:4,4],CMIP5[1:4,4]) # as an 8th column, insert absolute frequency
    model_data[,10] <- sign(c(CESM[1:4,3],CMIP5[1:4,3])) * 10
    for (d in 1:nrow(model_data)){
      if (model_data[d,10] == 0){
        model_data[d,10] <- 10
      }
    }
    colnames(model_data)[c(9,10)] <- c('abs_frequency','factor_shape')        
    label_colours <- c(rep(Blues[7],4), rep(Reds[7],4)) # green and purple colours
    # # insert dummy data for manual-made legend entries
    # model_data[9,] <- model_data[1,]; model_data[9,c(2,3,4,9)] <- c(.5,1.3,0,-1)
    # model_data[10,] <- model_data[1,]; model_data[10,c(2,3,4,9)] <- c(1.5,1.3,5,-1)
    # model_data[11,] <- model_data[1,]; model_data[11,c(2,3,4,9)] <- c(3,1.3,10,-1)
    # model_data[12,] <- model_data[1,]; model_data[12,c(2,3,4,9)] <- c(5,1.3,15,-1)
    # model_data[13,] <- model_data[1,]; model_data[13,c(2,3,4,9)] <- c(7,1.3,20,-1)
    
    } else if (main == 0){
    # combine future NE, E, SE, S, C and A from both models 
    model_data <- rbind(CESM[15:20,], CMIP5[15:20,]) 
    
    model_data[,9] <- c(CESM[5:10,4],CMIP5[5:10,4]) # as an 8th column, insert absolute frequency
    model_data[,10] <- sign(c(CESM[15:20,3],CMIP5[15:20,3])) * 10
    colnames(model_data)[c(9,10)] <- c('abs_frequency','factor_shape')        
    label_colours <- c(rep('#00bb00',6), rep('#bb00bb',6)) # green and purple colours
    }
  if (main == 1){
    plot_limits <- c(-10,12,-23,14) 
    plot_limits2 <- c(-25,15,0,7)
    model_names <- c('CESM future','CMIP5 future')
    label_ticks <- c(5,10,10,2) # label spacing on x- and y-axis
    } else {
      plot_limits <- c(-50,50,-75,75)
      model_names <- c('','')
      label_ticks <- c(25,25) # label spacing on x- and y-axis
      
}

  assign(paste("g",s, sep=""), ggplot() +
      # vertical line through the origin of the plot as guidance for the eye
      geom_segment(aes(x=-Inf,y=0,xend=Inf,yend=0),size=1, color='grey') +
      geom_segment(aes(x=0,y=-Inf,xend=0,yend=Inf),size=1, color='grey') +
      # line connecting the circulation types in the past (1) and future (2) periods
      # geom_line(data=model_data, aes(x=temperature,y=precipitation,group=type),color='grey',size=1) +
      # plot bubbles with a bit of transparency (alpha)
      # geom_point(data=model_data, aes(x=round(frequency,0),y=persistence),
      #    shape=21,fill='black',size=3,alpha=.8,stroke=1) + # stroke=border thickness
      # for shape either an upward or downward toblerone piece
      # guide -> specifies legend entries to the right
      # scale_shape_manual(values=c(25,24), guide=guide_legend(title.position="top",
      #   direction="vertical",ticks.linewidth = 1.5),labels=c('positive','negative')) +
      # set radius scale and limits
      # scale_radius(range = c(0,20), limits=c(-40, 10), labels=c('','','','negative','','positive')) + # relative size of circle plots
      # insert text labels for each circulation type
      # green labels for CESM purple labels for CMIP5 future data
      annotate("text",label='-0.6 -75',x=15,y=-76,size=6,colour='black',parse=TRUE,hjust=0) +
      geom_label(data = model_data, aes(x=round(frequency,0),y=persistence, label=type), 
        color=label_colours,fill='white',size=5,fontface='bold', # shading, text colour and size of labels
        hjust='inward',vjust='inward') +
      # plot frequency values into each data triangle
      # geom_text(data=model_data, aes(x=round(frequency,0),y=persistence,
      #   label=round(precipitation,0),colour=factor(visibility)),
      #   size=5.5,check_overlap = FALSE,fontface='bold') +
      scale_color_manual(values = c('black','white'), guide = FALSE) +
      # colours for the colourbar, i.e. the persistence change
      # scale_fill_gradientn(colours = rev(RdBu_short[2:7]), limits=c(2,7.21),
      #                      guide=guide_colourbar(title.position="top",direction="horizontal",ticks.linewidth = 1.5)) + # colourbar
      ggtitle(title_str) + # title     
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
      # add legend labels for CMIP5 and CESM in an empty-position on the figure which I then
      # can cut and paste onto the right to the legend entries with MS Paint
      # avoiding padding of labels with NA
      # geom_label_repel(aes(x=-20,y=-7.5, label=model_names[1]),
      #                  fill='white',color = '#00bb00',size = 7,
      #                  hjust=0.5,point.padding = NA,segment.color='grey') +
      # geom_label_repel(aes(x=-20,y=-9, label=model_names[2]),
      #                fill='white',color = '#bb00bb',size = 7,
      #                hjust=0.5, point.padding = NA,segment.color='grey') +
      # reference label
      # geom_point(aes(x=7,y=0.75,size=0,fill=0), shape = 21) +
      # geom_text(aes(x=7.6,y=0.75, label="reference", hjust=0), 
      #           colour="black", size =6)+
      geom_label_repel(aes(x=-20,y=11.5, label=model_names[2]),
                       fill='white',color = label_colours[5],size = 5,fontface='bold',
                       hjust=0.5,point.padding = NA,segment.color='grey') +
      geom_label_repel(aes(x=10,y=11.5, label=model_names[1]),
                       fill='white',color = label_colours[1],size = 5,fontface='bold',
                       hjust=0.5, point.padding = NA,segment.color='grey') +
        
      theme(legend.key.width = unit(1.2,'cm'))) # set width of colourbar in the legend

  assign(paste("h",s, sep=""), ggplot() +
      # vertical line through the origin of the plot as guidance for the eye
      geom_segment(aes(x=-Inf,y=0,xend=Inf,yend=0),size=1, color='grey') +
      geom_segment(aes(x=0,y=-Inf,xend=0,yend=Inf),size=1, color='grey') +
      # annotate("text",label='-0.6 -75',x=15,y=-76,size=6,colour='black',parse=TRUE,hjust=0) +
      geom_label(data = model_data, aes(x=temperature,y=precipitation, label=type), 
        color=label_colours,fill='white',size=5,fontface='bold') + # shading, text colour and size of labels
           scale_color_manual(values = c('black','white'), guide = FALSE) +
           ggtitle(title_str2) + # title     
           labs(y='Change in precipitation [%]',x='Change in temperature [°C]',
                shape='Change in \n precipitation [%]',
                fill='Change in \n temperature [°C]') + # axis labels
           # set y axis limits and breaks
           scale_y_continuous(breaks=seq(-100, 100, by = label_ticks[3]), limits=plot_limits2[c(1,2)]) + # x-axis range
           # set x-axis limits and breaks
           scale_x_continuous(breaks=seq(-100, 100, by = label_ticks[4]),limits=plot_limits2[c(3,4)]) + # y-axis range
           # theme(axis.text.x = element_text(hjust=+50)) +
         # geom_label_repel(aes(x=5.5,y=12.5, label=model_names[1]),
         #                  fill='white',color = Blues[7],size = 5,fontface='bold',
         #                  hjust=0.5,point.padding = NA,segment.color='grey') +
         # geom_label_repel(aes(x=5.5,y=8.5, label=model_names[2]),
         #                fill='white',color = Reds[7],size = 5,fontface='bold',
         #                hjust=0.5, point.padding = NA,segment.color='grey') +
           theme(axis.line = element_blank()) + # set x- and y-axis (the original ones) transparent
           theme(legend.key.width = unit(1.2,'cm'))) # set width of colourbar in the legend
}  


  dev.new()
  
  figure <- grid.arrange(arrangeGrob(g2,g4,top=textGrob('      Summer                                              Winter',hjust=0.5,gp=gpar(fontsize=20)),ncol=2), 
               arrangeGrob(h2,h4, ncol=2),nrow = 2)

  
  # figure <- ggarrange(g2, g4, h2, h4, ncol=2, nrow=2, legend="bottom", common.legend=TRUE)
  # annotate_figure(figure, 
  #                 top = text_grob("Summer            Winter", rot=0, size=20))

  # export as .png with specific filename
  filename = paste('Summary_figure_season_',s,'_main_',main,'_shift.png', sep="")
  # export as a .pdf image
  path_out <- 'E:/Praktikum MeteoSchweiz/figures/summary_figure/'
  dev.copy(png, paste(path_out, filename, sep = "/"),
           width = 9, height = 9, units = 'in', res = 300)
  dev.off()

rm(mean_freq_CESM, mean_freq_CMIP5, mean_pers_CESM, mean_pers_CMIP5)








