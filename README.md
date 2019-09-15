# europe_circulation_types
Scripts used for my MeteoSwiss/ETH Zurich research assistant project: __Assessing Changes in the Frequency and Persistence of Atmospheric Circulation Types Over Central Europe__

Maurice F. Huguenin, Erich M. Fischer, Sven Kotlarski, Simon C. Scherrer, Cornelia Schwierz and Reto Knutti


# Filename explanation

- __extract_patterns*.m__ are the MATLAB files I used to pull out all the circulation type maps shown in the Supporting Information Fig. S9-S20
- __leap_day*.py__ are the scripts I used to insert leap days every 4th year for those models that do not have leap days. I basically inserted a day with a 'NAN' circulation type randomly within that year which as a leap day. This was necessary in order to align the dates and the cost output files
- __merging_cmip5.py__ and __preprocessing_cesm.py__ are basically the same scripts but for the two model data sets and show the preprocessing of the raw output files in order for use in cost733class. See also the documentation in the Supporting Information, Section 2
- __preprocessing_cesm_maps_data.py__ and __preprocessing_cmip5_maps_data.py are the scripts used to prepare the raw model data sets for the circulation type maps in MATLAB (i.e. extracting Central European region, only selecting specific variables, only selecting 1980-2099 time period, ...)
- Script for Fig. 3 includes the analysis for Fig. S6 as well


More information on the CDO and COST733class commands can also be found in the Technical Appendix of the Supporting Information.