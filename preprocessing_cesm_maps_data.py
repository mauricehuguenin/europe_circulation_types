# Purpose: Prepare all CESM data for spatial maps creation in Matlab with
# script 'extract_patterns_2.m'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                     Maurice Huguenin-Virchaux                     #
#                      hmaurice@student.ethz.ch                     #
#                        08.02.2019, 14:13 CET                      #
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

# define past and future time periods
past = [1988, 2017]
future = [2070, 2090]

# file paths
path_ensembles='/net/bio/climphys/fischeer/CMIP5/EXTREMES/CESM12-LE/'
path_output='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/patterns/cesm_data_for_spatial_maps/'


# declare how many ensemble members should be used in the script
a = list(range(0,84)) # create index from 0 -> 84 while the last entry is not part of the array
filenames1 = []
filenames2 = []
filenames3 = []

for i in a:
    filenames1.append(i)
    filenames1[i] = 'z500_psl_CESM12-LE_historical_r' + str(a[i]) + 'i1p1_1940-2099.nc'
    filenames2.append(i)
    filenames2[i] = 'pr_mm_CESM12-LE_historical_r' + str(a[i]) + 'i1p1_1940-2099.nc'
    filenames3.append(i)
    filenames3[i] = 'tas_CESM12-LE_historical_r' + str(a[i]) + 'i1p1_1940-2099.nc'

    print('ensemble member r' + str(a[i]) + 'i1p1')
    
    starttime = datetime.now()

    # prepare past and future geopotential height (Z500) and sea level pressure (SLP) data
    filenames1[i]
    cdo.sellonlatbox(-20,40,30,80, input = '-selyear,1988/2017 ' + 
                  path_ensembles + filenames1[i], output = path_output + 
                  filenames1[i].replace('1940-2099','1988-2017'), 
                  force = False) # force = False -> skip those files which are already done
    cdo.sellonlatbox(-20,40,30,80, input = '-selyear,2070/2099 ' + 
                  path_ensembles + filenames1[i], output = path_output + 
                  filenames1[i].replace('1940-2099','2070-2099'), 
                  force = False) 

    # prepare past and future precipitation (pr) data
    filenames2[i]
    cdo.sellonlatbox(-20,40,30,80, input = '-selyear,1988/2017 ' + 
                     path_ensembles + filenames2[i], output = path_output + 
                     filenames2[i].replace('1940-2099','1988-2017'), 
                     force = False) # force = False -> skip those files which are already done
    cdo.sellonlatbox(-20,40,30,80, input = '-selyear,2070/2099 ' + 
                     path_ensembles + filenames2[i], output = path_output + 
                     filenames2[i].replace('1940-2099','2070-2099'), 
                     force = False) # force = False -> skip those files which are already done

    # prepare past and future temperature anomaly (tas) data
    filenames3[i]
    cdo.sellonlatbox(-20,40,30,80, input = '-selyear,1988/2017 ' + path_ensembles + filenames3[i], output = path_output + filenames3[i].replace('tas','tas_past'),force=False)
    cdo.yseassub(input = path_output + filenames3[i].replace('tas','tas_past') + ' -yseasavg ' + path_output + filenames3[i].replace('tas','tas_past'), 
                 output = path_output + filenames3[i].replace('1940-2099','1988-2017'))

    cdo.sellonlatbox(-20,40,30,80, input = '-selyear,2070/2099 ' + path_ensembles + filenames3[i], output = path_output + filenames3[i].replace('tas','tas_future'),force=False)
    cdo.yseassub(input = path_output + filenames3[i].replace('tas','tas_future') + ' -yseasavg ' + path_output + filenames3[i].replace('tas','tas_past'),
                 output = path_output + filenames3[i].replace('1940-2099','2070-2099'))

    # merge all past files -> i.e. put pr and tas into z500/slp file
    files = filenames1[i]
    cdo.merge(input = path_output + filenames1[i].replace('1940-2099','1988-2017') + ' ' + 
              path_output + filenames2[i].replace('1940-2099','1988-2017') + ' ' + 
              path_output + filenames3[i].replace('1940-2099','1988-2017'), 
              output = path_output + files[:-12].replace('z500_psl_','z500_psl_pr_tas_') + '1988-2017.nc')

    cdo.merge(input = path_output + filenames1[i].replace('1940-2099','2070-2099') + ' ' + 
              path_output + filenames2[i].replace('1940-2099','2070-2099') + ' ' + 
              path_output + filenames3[i].replace('1940-2099','2070-2099'), 
              output = path_output + files[:-12].replace('z500_psl_','z500_psl_pr_tas_') + '2070-2099.nc')

# Replace all the occurrences of string in list by AA in the main list 
#otherStr = replaceMultiple(mainStr, ['s', 'l', 'a'] , "AA")

    print(datetime.now() - starttime)



#    cdo.sellonlatbox(-20,40,30,80,input = '-yseassub -selyear,2070/2099 ' + path_ensembles + f3 + 
#                     ' -yseasavg -selyear,1988/2017 ' + path_ensembles + f3, 
#                     output = path_output + f3.replace('1940-2099', '2070-2099'))
#    os.system('cdo -selyear,1988/2017 -sellonlatbox,-20,40,30,80 -yseassub ' + 
#              path_ensembles + f3 + ' -selyear,1988/2017 -sellonlatbox,-20,40,30,80 -yseasavg ' + path_ensembles + f3 + ' ' + 
#              path_output + f3.replace('1940-2099', '1988-2017'))
#    os.system('cdo -selyear,2070/2099 -sellonlatbox,-20,40,30,80 -yseassub ' + 
#              path_ensembles + f3 + ' -yseasavg ' + path_ensembles + f3 + ' ' + 
#              path_output + f3.replace('1940-2099', '2070-2099'))




# end of loop

# now merging variables together into one file
#filenames1 = [i for i in os.listdir(path_output) if i.startswith('z500_psl_CESM12-LE_historical_')]
#filenames2 = [i for i in os.listdir(path_output) if i.startswith('pr_mm_CESM12-LE_historical_')]
#filenames3 = [i for i in os.listdir(path_output) if i.startswith('tas_CESM12-LE_historical_')]

#for f1 in filenames1: 
#    print(f1)
#    for f2 in filenames2:
#        print(f2)
#        for f3 in filenames3:
#            cdo.merge(input = path_output + f1 + ' ' + path_output + f2 + ' ' + path_output + f3, output = path_output + f1.replace('z500_psl_', 'z500_psl_pr_tas_'), force = False)
        
# remove redundant files
filenames3 = [i for i in os.listdir(path_output) if i.startswith('pr_mm') or i.startswith('z500_psl_CESM') or i.startswith('tas')]
for f3 in filenames3:
    os.system('rm -r ' + path_output + f3)
























