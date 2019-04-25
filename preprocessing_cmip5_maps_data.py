# Purpose: (1) Pre-processing daily CMIP5 GCM 500 hPa geopotential height data and classification
#          of Central European circulation types with the cost733class software 
#          (2) Into the same .nc file I put in temperature anomalies, sea level pressure and 
#              precipitation for later use in spatial map creation
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                                               #
# Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
#           Frequency and Persistence of Central European Circulation Types                     #
# My Name:  Maurice Huguenin-Virchaux                                                           #
# My Email: hmaurice@student.ethz.ch                                                            #
# Date:     18.02.2019, 15:01 CET                                                               #
#                                                                                               #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# preamble
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
from netCDF4 import Dataset
import numpy as np # package for calculations
import matplotlib.pyplot as plt # package for drawing maps
from cdo import * # netcdf operations
cdo = Cdo()
import os # operating system
from datetime import datetime # package for stopping time
import sys
#cdo.debug = True

# file paths
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
path_hist='/net/atmos/data/cmip5/historical/day/' # input file path 1
path_rcp='/net/atmos/data/cmip5/rcp85/day/'       # input file path 2
# file path for processed files
path_output='/net/h2o/climphys/hmaurice/Practicum_meteoswiss_output/patterns/cmip5_data_for_spatial_maps/'

# variables
variable = ['zg','psl','pr','tas'] # geopotential height, pressure at sea level, ...
                                   # precipitation and surface air temperature

## small model list for testing

#a = ['ACCESS1-0']

## all CMIP5 model list
a = ['ACCESS1-0', 'ACCESS1-3', 'BNU-ESM', 'CanESM2', 'CMCC-CM', 'CMCC-CMS',    
     'CNRM-CM5', 'FGOALS-g2', 'GFDL-CM3', 'GFDL-ESM2G', 'GFDL-ESM2M', 
     'IPSL-CM5A-LR', 'IPSL-CM5A-MR', 'IPSL-CM5B-LR', 'MPI-ESM-LR',
     'MRI-CGCM3', 'MRI-ESM1', 'NorESM1-M'] # model list
#b = ['r1i1p1']
b = ['r1i1p1', 'r2i1p1', 'r3i1p1', 'r4i1p1', 'r12i1p1'] # realisations


for model in a:                 # loop over all models
    for realisation in b:       # loop over all realisations
        # combine array elements to build strings for filepaths
        # path for geopotential height data
        c = path_hist + variable[0] + '/' + model + '/' + realisation + '/'
        d = path_rcp + variable[0] + '/' + model + '/' + realisation + '/'
        # path for sea level pressure data
        e = path_hist + variable[1] + '/' + model + '/' + realisation + '/'
        f = path_rcp + variable[1] + '/' + model + '/' + realisation + '/'
        # path for precipitation data
        g = path_hist + variable[2] + '/' + model + '/' + realisation + '/'
        h = path_rcp + variable[2] + '/' + model + '/' + realisation + '/'
        # path for surface air temperature data
        i = path_hist + variable[3] + '/' + model + '/' + realisation + '/'
        k = path_rcp + variable[3] + '/' + model + '/' + realisation + '/'

        output_name = 'zg_psl_pr_tas__' + model + '_historical_rcp85_' + realisation + '.nc'

        # (1) check if data exists
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # print 'No data' for model realisations that do not exist
        # check if historical data does not exist or if rcp85 data does not exist 
        # -> if true, then skip iteration in loop and continue with next realisation or model
        if os.path.isdir(c) == False and os.path.isdir(d) == False or \
           os.path.isdir(c) == True and os.path.isdir(d) == False or \
           os.path.isdir(e) == True and os.path.isdir(f) == False or \
           os.path.isdir(e) == False and os.path.isdir(f) == False or \
           os.path.isdir(g) == True and os.path.isdir(h) == False or \
           os.path.isdir(g) == False and os.path.isdir(h) == False or \
           os.path.isdir(i) == True and os.path.isdir(k) == False or \
           os.path.isdir(i) == False and os.path.isdir(k) == False:
            print('Data missing for: ' + model + '_' + realisation) # print statement
            continue # skip iteration if at least one statement in loop is true

            
        starttime = datetime.now() # start stopwatch

        # (2) merge all historical and rcp85 files
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        # now use cdo merge for that file path
        # zg: geopotential height
        cdo.mergetime(input = c + 'zg_day_*', output = path_output + 'zg_day_historical_' + 
                      model + '_' + realisation + '.nc', force = False)
        cdo.mergetime(input = d + 'zg_day_*', output = path_output + 'zg_day_rcp85_' + 
                      model + '_' + realisation + '.nc', force = False)

        # psl: pressure at sea level
        cdo.mergetime(input = e + 'psl_day_*', output = path_output + 'psl_day_historical_' + 
                      model + '_' + realisation + '.nc', force = False)
        cdo.mergetime(input = f + 'psl_day_*', output = path_output + 'psl_day_rcp85_' + 
                      model + '_' + realisation + '.nc', force = False)

        # pr: precipitation
        cdo.mergetime(input = g + 'pr_day_*', output = path_output + 'pr_day_historical_' + 
                      model + '_' + realisation + '.nc', force = False)
        cdo.mergetime(input = h + 'pr_day_*', output = path_output + 'pr_day_rcp85_' + 
                      model + '_' + realisation + '.nc', force = False)

        # tas: standard reference temperature
        cdo.mergetime(input = i + 'tas_day_*', output = path_output + 'tas_day_historical_' + 
                      model + '_' + realisation + '.nc', force = False)
        cdo.mergetime(input = k + 'tas_day_*', output = path_output + 'tas_day_rcp85_' +
                      model + '_' + realisation + '.nc', force = False)

        # (3) merge newly created hist + rcp85 file into one large file
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        filenames = [i for i in os.listdir(path_output) if 
                     i.startswith('zg_day_historical_' + model) or 
                     i.startswith('zg_day_rcp85_' + model)]
        name = 'zg_day_historical_rcp85_' + model + '_' + realisation + '.nc'

        cdo.mergetime(input = ' '.join(filenames), output = path_output + name, force=False)
        
        # (4) subset data and extract only what I need
        # for zg:        - select past (1988-2017) and future (2070-2099) data
        #                - select 500 hPa level, set that level to 0
        #                - bilinearly remap/interpolate to 1x1 ERA-Interim grid with file grid.nc
        cdo.sellonlatbox(-20,40,30,80, input = 
                         '-remapbil,grid.nc -setlevel,0 -sellevel,50000 -selyear,1988/2017 ' + 
                         path_output + name, output = path_output + 
                         name[:-3].replace('_historical_rcp85_','_') + 
                         '_1988-2017.nc', force = False)
        cdo.sellonlatbox(-20,40,30,80, input = 
                         '-remapbil,grid.nc -setlevel,0 -sellevel,50000 -selyear,2070/2099 ' + 
                         path_output + name, output = path_output + 
                         name[:-3].replace('_historical_rcp85_','_') + 
                         '_2070-2099.nc', force = False)

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        filenames = [i for i in os.listdir(path_output) if 
                     i.startswith('psl_day_historical_' + model) or 
                     i.startswith('psl_day_rcp85_' + model)]
        name = 'psl_day_historical_rcp85_' + model + '_' + realisation + '.nc'

        cdo.mergetime(input = ' '.join(filenames), output = path_output + name, force=False)
        
        # for psl:       - select past (1988-2017) and future (2070-2099) data
        #                - bilinearly remap/interpolate to 1x1 ERA-Interim grid with file grid.nc
        cdo.sellonlatbox(-20,40,30,80, input = '-remapbil,grid.nc -selyear,1988/2017 ' + 
                         path_output + name, output = path_output + 
                         name[:-3].replace('_historical_rcp85_','_') + 
                         '_1988-2017.nc', force=False)
        cdo.sellonlatbox(-20,40,30,80, input = '-remapbil,grid.nc -selyear,2070/2099 ' + 
                         path_output + name, output = path_output + 
                         name[:-3].replace('_historical_rcp85_','_') +
                         '_2070-2099.nc', force=False)

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        filenames = [i for i in os.listdir(path_output) if 
                     i.startswith('pr_day_historical_' + model) or 
                     i.startswith('pr_day_rcp85_' + model)]
        name = 'pr_day_historical_rcp85_' + model + '_' + realisation + '.nc'

        cdo.mergetime(input = ' '.join(filenames), output = path_output + name, force=False)

        # for pr:        - select past (1988-2017) and future (2070-2099) data
        #                - bilinearly remap/interpolate to 1x1 ERA-Interim grid with file grid.nc
        cdo.sellonlatbox(-20,40,30,80, input = '-remapbil,grid.nc -selyear,1988/2017 ' + 
                         path_output + name, 
                         output = path_output + name[:-3].replace('_historical_rcp85_','_') + 
                         '_1988-2017.nc', force=False)
        cdo.sellonlatbox(-20,40,30,80, input = '-remapbil,grid.nc -selyear,2070/2099 ' + 
                         path_output + name, 
                         output = path_output + name[:-3].replace('_historical_rcp85_','_') + 
                         '_2070-2099.nc', force=False)

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        filenames = [i for i in os.listdir(path_output) if 
                     i.startswith('tas_day_historical_' + model) or 
                     i.startswith('tas_day_rcp85_' + model)]
        name = 'tas_day_historical_rcp85_' + model + '_' + realisation + '.nc'

        cdo.mergetime(input = ' '.join(filenames), output = path_output + name, force=False)

        # for tas:       - select past (1988-2017) and future (2070-2099) data
        #                - detrend data
        #                - bilinearly remap/interpolate to 1x1 ERA-Interim grid with file grid.nc
        #                - create temporary file with ending *_past.nc and *_future.nc
        #                - subtract seasonal average of past period from past and future data
        #                  to calculate the anomalies
        cdo.sellonlatbox(-20,40,30,80, input ='-remapbil,grid.nc -selyear,1988/2017 ' + 
                     path_output + name, output = path_output + name[:-3] + 
                     '_past.nc', force=False)
        cdo.yseassub(input = path_output + name[:-3] + '_past.nc' + ' -yseasavg ' + 
                     path_output + name[:-3] + '_past.nc', output = path_output + 
                     name[:-3].replace('_historical_rcp85_','_') + '_1988-2017.nc', force=False)

        cdo.sellonlatbox(-20,40,30,80, input ='-remapbil,grid.nc -selyear,2070/2099 ' + 
                     path_output + name, output = path_output + 
                     name[:-3] + '_future.nc', force=False)
        cdo.yseassub(input = path_output + name[:-3] + '_future.nc' + ' -yseasavg ' + 
                     path_output + name[:-3] + '_past.nc', output = path_output + 
                     name[:-3].replace('_historical_rcp85_','_') + '_2070-2099.nc', force=False)

        # merging together of all four files (zg, psl, pr and tas) unfortunately does not work
        # as geopotential height still has the lev dimension inside the netcdf file
        print('Merging hist + rcp85 data and subsetting done:')
        print(datetime.now() - starttime) # print time after one iteration


        # removing redundant files
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        os.system('rm -r *' + realisation + '.nc') # remove all files except the ones I need
        os.system('rm -r *past.nc')
        os.system('rm -r *future.nc')

        print('All done for: ' + model + '_' + realisation)
        print(datetime.now() - starttime) # print time after one iteration
        

   # end of loop over realisations
# end of loop over models












sys.exit() # exit script


# (XY) notes here
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


