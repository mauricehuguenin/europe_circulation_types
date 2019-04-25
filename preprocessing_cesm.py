# Script for preprocessing CESM12-LE data and subsequent use with the 
# cost classification software
# (I)   extract necessary data from original .nc files
# (II)  run cost733class software with these adjusted .nc files
# (III) prepare output for next step before analysis in R

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                     Maurice Huguenin-Virchaux                     #
#                      hmaurice@student.ethz.ch                     #
#                        05.10.2018, 09:05 CET                      #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# preamble
from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
from cdo import *
cdo = Cdo()
import os
from datetime import datetime
import sys
#cdo.debug = True

# variables
method = 'GWT'
classes = '10'
variable = 'Z500'            # Z500 or psl

# file paths
path_ensembles='/net/bio/climphys/fischeer/CMIP5/EXTREMES/CESM12-LE/'
path_grid='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_datasets/'
path_processed='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/process/cesm/'
path_cost='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/cost/cesm/'

# only select 1940-2099 files, the other ones are old
# select all files on /net/bio/.. subfolder which start with 'z500' 
# and end with '.nc', i.e. neglect those which have a strange error
filenames = [i for i in os.listdir(path_ensembles) if i.startswith('z500_psl_CESM12-LE_historical_')
             and i.endswith('1940-2099.nc')]

# ~~~ pre-processing procedure with cdo ~~~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
 
# create for loop (content inside the loop needs to be indented)
for f in filenames:
    print(f)                                          # print filenames out
    starttime = datetime.now()                        # start counting time
    
    # script runs from inside out:
    # (1) select variable name, i.e. Z500
          # cdo selname ifile ofile
    # (2) select years, i.e. 1940 -- 2099
          # cdo selyear ifile ofile
    # (3) select latitude/longitude box over central Europe: 3-20E & 41-52N
          # cdo sellonlatbox ifile ofile
    # (4) invert latitude as the cost733class software program needs 
    #     ascending latitude and ascending longitude, otherwise the
    #     westerlies are classified as easterlies and vice versa
          # cdo invertlat ifile ofile
    # finally, write output in specified folder and replace a part of the filename
    
    cdo.invertlat(input = '-sellonlatbox,2.5,20,40.73,52.10 -selyear,1960/2099 ' +
                  path_ensembles + f, output = path_processed + f.replace('psl', 'processed'), 
                  force = False) # force = False -> skip those files which are already done

    # (5) rewrite netcdf4 into classic format
    # execute string as bash command with os.system()
    os.system("ncks -3 " + path_processed + f.replace('psl', 'processed') + " " + 
              path_processed + f.replace('psl', 'classic'))
    os.system("rm -r " + path_processed + f.replace('psl', 'processed')) # remove redundant file


    # (5) adjust time@unit in classic format (tip from Urs' email on 02/10/2018, 10:06 CET
    os.system("ncap2 -O -s " + '"time=time*24+50*365" ' + '-s ' + "'time@units=" + 
              '"hours since 1900-01-01 00:00:00' + '"' + "' " + path_processed + 
              f.replace('psl', 'classic') + " " + path_processed + f.replace('psl', 'time'))
    os.system("rm -r " + path_processed + f.replace('psl', 'classic')) # again remove redundant file

    # the cost input file now has the suffix 'time'

    print(datetime.now() - starttime)         # print time it takes to execute script for one file
    
# ~~~ running the cost733class software ~~~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

filenames2 = [i for i in os.listdir(path_processed) if 
              i.startswith('z500_time_CESM12-LE_historical_') and i.endswith('1940-2099.nc')]

# create for loop 
for f2 in filenames2:
    print(f2)
    # -dat pth:/../.. -> specify input location
    # var:Z500 -> specify which of the variables it needs to consider
    # -met GWT -ncl 10 -> specify classification method and how many patterns
    # -cla -> I don't know what that is
    # specify output direction and write as a .dat file
    # -dcol 3 -> write time in the first three columns, i.e. YYYY MM DD 
    # -cnt -> I don't know what that means
    os.system("cost733class -dat pth:" + path_processed + f2 + " var:" + variable + " -met " + 
              method + " -ncl " + classes + " -cla " + path_cost + 
              f2[:-3].replace('time', 'cost') + "_" + variable + ".dat" + " -dcol 3 -cnt")


# ~~~ post-processing the .dat files in folder cost ~~~ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# here I extract the output without the date columns, i.e. cut the 4th column
path_cost = '/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/cost/cesm/'
filenames3 = [i for i in os.listdir(path_cost) if i.startswith('z500_cost_')]

for f in filenames3:
    print(f)
    starttime = datetime.now()
    # column1  column2  column3  column4
    # year     month    day      # weather type
    os.system("awk '{print $4}' " + path_cost + f + " >" + path_cost + f.replace('cost', 'small'))

    os.system("rm -r " + path_cost + f) # again remove redundant files    
    # these 'small' files are then used to adjust leap days and combined into one file with date
    # vectors and all ensemble member output
    # hmaurice@h2o:~> paste date.dat z500_small_* >data.dat




