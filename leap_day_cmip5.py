# Purpose: Script for inserting leap days in cost733class output when using the CESM12-LE
#          model as models only has a 365 day calender (not Gregorian calender)
#          (1) split data into blocks of 365 days
#          (2) add in each 4th block, i.e. leap year, a random leap day line with 'nan'
#          (3) put the blocks together again to create one file again
#          (4) delete the building blocks to clean up
#          (5) manually combine date vector and all ensemble model output with console command:
#              paste date.dat z500_extended_* >cost_CESM12-LE_historical_1960-2099.nc

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#                                                                                               #
# Project:  Practicum MeteoSwiss/ETH Zurich                                                     #
#           Frequency and Persistence of Central European Circulation Types                     #
# My Name:  Maurice Huguenin-Virchaux                                                           #
# My Email: hmaurice@student.ethz.ch                                                            #
# Date:     19.12.2018, 15:12 CET                                                               #
#                                                                                               #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

# preamble
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
from cdo import *
cdo = Cdo()
import os
from datetime import datetime
# cdo.debug = True
import string # used to loop through the alphabet
from random import randint # package for random numbers
from subprocess import Popen, PIPE # newer and better version of os
import fnmatch # package to recognize file names in directory
import re # package to extract a part of the filename
from glob import glob # for filename changes
import sys # to use the sys.exit() command to stop execution

# filepaths
path_cost = '/net/h2o/climphys/hmaurice/Practicum_meteoswiss_datasets/'
 
#model = ['CanESM2', 'GFDL-ESM2M', 'IPSL-CM5A-MR', 'NorESM1-M']
model = ['BNU-ESM', 'CanESM2', 'FGOALS-g2', 'GFDL-CM3', 'GFDL-ESM2G', 'GFDL-ESM2M',
         'IPSL-CM5A-LR', 'IPSL-CM5A-MR', 'IPSL-CM5B-LR', 'NorESM1-M']
# filenames of cost733class output
filenames = [i for i in os.listdir(path_cost) if i.endswith('.dat')]

for f in filenames:
    # (1) check if subset of files contain any of the models with no leap days
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if any(ext in f for ext in model):
        print(f)
        
    # split files into blocks of 365 with three suffixes and label output files numerically
    # rather than alphabetically, i.e. x000, x001, x002, x003, x004
    # python loops end after indent back to previous level, no 'end' as in matlab

    starttime = datetime.now()


    splitLen = 365         # 365 lines per file -> somehow I have to insert 366 here as the 
                           # files are too short with 365
                           # -> I think this may be due to python starting at integer 0
    outputBase = 'x' # x.1.dat, x.2.dat, etc.

    # here I extract only the number part of the filenames, i.e. 27, 28, 29, 30, etc.
    # and then look which ones are divisible by 4, i.e. are leap years
    # this is shorthand and not friendly with memory
    # on very large files (Sean Cavanagh), but it works.

    # (2) split files
    input = open(path_cost + f, 'r').read().split('\n')
    at = 0
    for lines in range(0, len(input), splitLen):
        # First, get the list slice
        outputData = input[lines:lines+splitLen] 

        # Now open the output file, join the new slice with newlines
        # and write it out. Then close the file.
        output = open(path_cost + outputBase + str(at) + '.dat', 'w')
        output.write('\n'.join(outputData))
        output.close()

        # Increment the counter
        at += 1

        # cancel execution of file here with this command on the next line

        # now taking every 4th file block starting from the first one
        filenames2 = [i for i in os.listdir(path_cost) if i.startswith('x')]

        # add linebreak at the end of the document
    for f2 in filenames2:
        os.system("echo >> " + path_cost + f2)

        # list all 365 blocks without the x and its file extension .dat
    for f2 in filenames2:
        # find if filename string can be divided by 4, i.e. is a leap year
        res = re.findall("x(\d+).dat", f2) # res = only the number part of the filenames
        if not res: continue 
        #    print res[0]

        # find if filename string can be divided by 4, i.e. is a leap year
        if (int(res[0]) % 4 == 0) or (int(res[0]) == 0): # modulo function in python
            print(res[0] + ' -> yes, is divisible by 4') # print statement if it's true
            # this works, yes!
            N = randint(1,365) # generate a random integer between 1 and 365 days
                           # I then insert the leap day (in reality the 29. of February)
                           # at a random position in the model year
                           # print 'random number: ', N        # print the random number

            d = open(path_cost + f2, "r") # open file in read mode
            contents = d.readlines()
            d.close
        
            contents.insert(N, 'nan \n') # write content which will be inserted
            # -> at line 'N' we insert 'nan' with a 
            # linebreak so it creates a new entry
            # and my file is extended to 366 lines
        
            d  = open(path_cost + f2, "w") # open file in write mode
            contents = "".join(contents) # join content into file
            d.write(contents)            
            d.close()                    # close file

    # now I concatenate all files again and write them into a bigger one which is then
    # subsequently combined with the date.dat file and the other ensembles to give the
    # final cost733class output

    os.system("rm -r " + path_cost + "x140.dat") # remove that one file at the end 
                                                 # which has only empty lines in it
                                                 # so I have 139 years of data, some with 
                                                 # 365 days, some with 366 days
                                            
    # now concatenate all small files together to restore the big file
    # concatenate numerically so I have x0.dat/x1.dat/x2.dat/...
    #                                   and not x0.dat/x100.dat/x101.dat/..
    os.system("cat " + path_cost + "x{0..139}.dat "  + " >" + path_cost + 
              f.replace('small','extended')) # concatenate small files

    os.system("rm -r " + path_cost + "x{0..139}.dat") # remove all small files to clean up
#    os.system("rm -r " + path_cost + f) # remove redundant files with the suffix 'small'
    os.system("rm -r " + path_cost + f.replace('small', 'cost'))

# end of loop over all files

sys.exit() # end script
