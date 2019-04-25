# Purpose: Pre-processing daily CMIP5 GCM 500 hPa geopotential height data and classification
#          of Central European circulation types with the cost733class software 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                                               #
# Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
#           Frequency and Persistence of Central European Circulation Types                     #
# My Name:  Maurice Huguenin-Virchaux                                                           #
# My Email: hmaurice@student.ethz.ch                                                            #
# Date:     11.12.2018, 16:16 CET                                                               #
#                                                                                               #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# preamble
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
from cdo import *
cdo = Cdo()
import os
from datetime import datetime
import sys
#cdo.debug = True

variable = 'zg'
method = 'GWT'
classes = '10'

# file paths
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
path_hist='/net/atmos/data/cmip5/historical/day/' # input file path 1
path_rcp='/net/atmos/data/cmip5/rcp85/day/'       # input file path 2
# file path for processed files
path_processed='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/cost/cmip5/'
# file path for cost output files
path_cost='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/cost/cmip5/'

# array with model names and realisations <- first for the CH2018 models only

## CH2018 model list
#a = ['EC-EARTH', 'HadGEM2-ES', 'MPI-ESM-LR', 'MIROC5', 'CanESM2', 'IPSL-CM5A-MR', 
#     'NorESM1-M', 'GFDL-ESM2M']; b = ['r1i1p1', 'r2i1p1', 'r3i1p1', 'r12i1p1']

## small model list for testing
a = ['GFDL-ESM2M']; 
b = ['r1i1p1']

## all CMIP5 model list
#a = ['ACCESS1-3',       'CanESM2',    
#      'CMCC-CMS',      'GFDL-CM3',     'HadGEM2-AO',    'IPSL-CM5A-MR', 
#      'MIROC-ESM-CHEM',  'MRI-CGCM3',   'bcc-csm1-1',    'CCSM4',      'CNRM-CM5',  
#      'GFDL-ESM2G',  'HadGEM2-CC', 'IPSL-CM5B-LR',  'MPI-ESM-LR',      'MRI-ESM1', 
#      'bcc-csm1-1-m',  'CMCC-CESM',   'EC-EARTH',  'GFDL-ESM2M',  'HadGEM2-ES',  
#      'MIROC5',        'MPI-ESM-MR',      'NorESM1-M']
#b = ['r1i1p1', 'r2i1p1', 'r3i1p1', 'r4i1p1', 'r12i1p1']


# example filename: zg_day_GFDL-ESM2M_historical_r1i1p1_20010101-20051231.nc
for model in a:                 # loop over all models
    for realisation in b:       # loop over all realisations
        # combine array elements
        s = path_hist + variable + '/' + model + '/' + realisation + '/'
        t = path_rcp + variable + '/' + model + '/' + realisation + '/'
        output_name = 'zg_day_' + model + '_historical_rcp85_' + realisation + '.nc'

        # (1) check if data exists
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # print 'No data' for model realisations that do not exist
        if os.path.isdir(s) == False and os.path.isdir(t) == False or \
           os.path.isdir(s) == True and os.path.isdir(t) == False:
            print('No data for: ' + model + '/' + realisation)
            continue
        
        starttime = datetime.now() # start stopwatch

        # (2) merge all historical and rcp85 files
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # now use cdo merge for that file path
        cdo.mergetime(input = s + 'zg_day_*', output = path_processed + 'zg_day_' + model + 
                      '_' + realisation + '_historical.nc', force = False)
        cdo.mergetime(input = t + 'zg_day_*', output = path_processed + 'zg_day_' + model +
                      '_' + realisation + '_rcp85.nc', force = False)

        # (3) merge newly created hist + rcp85 file into one large file
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        filenames = [i for i in os.listdir(path_processed) if 
                     i.startswith('zg_day_' + model + '_' + realisation)]
        print(filenames) # print filenames in console
        cdo.mergetime(input = ' '.join(filenames), output = path_processed + output_name, 
                      force = False)
        print('Merging hist + rcp85 data done:')
        print(datetime.now() - starttime) # print time after one iteration

        # (4) subsetting data to reduce size
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        cdo.invertlat(input = '-setlevel,0 -sellevel,50000 -selname,zg -selyear,1960/2099 \
        -sellonlatbox,2.5,20,40.73,52.10 ' + path_processed + output_name, 
                      output = output_name[:-3] + '_process.nc', force = False)
        print('Subsetting data done:')
        print(datetime.now() - starttime) # print time after one iteration

        # (5) adjusting time dimension
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        output_name = output_name[:-3] + '_process.nc'
        os.system("ncap2 -O -s " + '"time=time*24+50*365" ' + '-s ' + "'time@units=" + 
                  '"hours since 1900-01-01 00:00:00' + '"' + "' " + path_processed + 
                  output_name + ' ' + path_processed + output_name.replace('process', 'time')) 
                  # cannot use force = False here as system() does not take keyword arguments

        # (6) convert to classic format
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        output_name = output_name.replace('process', 'time')
        os.system('ncks -O --fl_fmt=classic ' + path_processed + output_name + ' ' + 
                  path_processed + output_name.replace('time', 'classic'))

        # (7) removing bnds = 2 dimension from the vertical zg dimension
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        output_name = output_name.replace('time', 'classic')
        os.system('ncwa -a bnds ' + path_processed + output_name + ' ' + path_processed + 
                  output_name.replace('classic', 'no_bnds')) 

        
        # (8) running cost software and creating output .dat file
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        output_name = output_name.replace('classic', 'no_bnds')
        os.system("cost733class -dat pth:" + path_processed + output_name + " var:" + 
                  variable + " -met " + method + " -ncl " + classes + " -cla " + 
                  path_processed + output_name[:-3].replace('no_bnds', 'cost') + 
                  ".dat" + " -dcol 3  -cnt")


        # (9) removing redundant files
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        os.system('rm -r ' + path_processed + 'zg_day_' + model + '_' + realisation + '_*')
        redundant_names = 'zg_day_' + model + '_historical_rcp85_' + realisation  
        os.system('rm -r ' + path_processed + redundant_names + '_classic.nc')
        os.system('rm -r ' + path_processed + redundant_names + '_no_bnds.nc')
        os.system('rm -r ' + path_processed + redundant_names + '_process.nc')
        os.system('rm -r ' + path_processed + redundant_names + '_time.nc')
        
        print(datetime.now() - starttime) # print time after one iteration
        
        # (10) post-processing cost output file
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#        output_name = output_name[:-3].replace('no_bnds', 'cost') + '.dat'
#        print(output_name)
#        os.system("awk '{print $4}' " + path_processed + output_name + ' >' + 
#                  path_processed + output_name.replace('cost', 'small'))
#        os.system('rm -r ' + path_processed + output_name) # again remove redundant file 
        # these 'small' files are then used to adjust leap days and combinedd into one file
        # with date vector (i.e. YYYY MM DD) and all other CMIP5 ensemble member output
        # to combine these files I just use: hmaurice@h2o:~> paste date.dat zg_day_* >data.dat

   # end of loop over realisations
# end of loop over models

sys.exit() # exit script

# (XY) notes here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


