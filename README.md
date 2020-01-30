# europe_circulation_types
Scripts used for the project: __Assessing Changes in the Frequency and Persistence of Atmospheric Circulation Types Over Central Europe__

Maurice F. Huguenin(1,2,3), Erich M. Fischer(1), Sven Kotlarski(2), Simon C. Scherrer(2), Cornelia Schwierz(2) and Reto Knutti(1)


1 Institute for Atmospheric and Climate Science, ETH Zurich, 8092 Zurich, Switzerland
 
2 Federal Office of Meteorology and Climatology, MeteoSwiss, 8058 Zurich, Switzerland

3 Climate Change Research Centre and ARC Centre of Excellence for Climate Extremes, University of New South Wales, New South Wales 2052, Australia 

# Analysis Scripts

- (extract_patterns_cesm_with_differences.m](extract_patterns_cesm_with_differences.m) and [extract_patterns_cmip5_with_differences.m](extract_patterns_cmip5_with_differences.m) are the MATLAB files I used to pull out all the circulation type maps shown in the Supporting Information Fig. S9-S20 including the differences in the maps for the past and future time periods
- [leap_day_cesm.py](leap_day_cesm.py) and [leap_day_cmip5.py](leap_day_cmip5.py) are the scripts I used to insert leap days every 4th year for those models that do not have leap days. I basically inserted a day with a 'NAN' circulation type randomly within that year which as a leap day. This was necessary in order to align the dates and the cost output files
- [merging_cmip5.py](merging_cmip5.py) and [preprocessing_cesm.py](preprocessing_cesm.py) are basically the same scripts but for the two model data sets and show the preprocessing of the raw output files in order for use in cost733class. See also the documentation in the Supporting Information, Section 2
- [preprocessing_cesm_maps_data.py](preprocessing_cesm_maps_data.py) and [preprocessing_cmip5_maps_data.py](preprocessing_cmip5_maps_data.py) are the scripts used to prepare the raw model data sets for the circulation type maps in MATLAB (i.e. extracting Central European region, only selecting specific variables, only selecting 1980-2099 time period, ...)

# List of Figures
__Fig. 1__: Calculating the persistence measure as the regression fit of the consecutive circulation type period distribution with the script [Fig1_persistence_measure_circulation_type.R](Fig1_persistence_measure_circulation_type.R)

__Fig. 2__: Calculating the seasonal frequency of circulation types and their projected change for the future time period 2070-2099 in [Fig2_frequency_circulation_type_and_future_change.R](Fig2_frequency_circulation_type_and_future_change.R)

__Fig. 3__: Persistence change visualized with the summary figure script [Fig4_summary_change_persistence_frequency_temperature_precipitation.R](Fig4_summary_change_persistence_frequency_temperature_precipitation.R) and using the data saved in [data/workspace_persistence_for_summary_figure_CESM_CMIP5.RData](data/workspace_persistence_for_summary_figure_CESM_CMIP5.RData)

__Fig. 4__: Summary figure created with [Fig4_summary_change_persistence_frequency_temperature_precipitation.R](Fig4_summary_change_persistence_frequency_temperature_precipitation.R)

 
- Script for Figs. S3-7 includes the analysis of past time series and trends for the four main circulation types

# Data folder

- [data/WTC_MCH_19570901-20180831.dat](data/WTC_MCH_19570901-20180831.dat) is the COST733class output file from the ERA-40/-Interim reanalysis product obtained from MeteoSwiss. The column 'wkwtg1d0' represents output obtained from the GWL method using geopotential height at 500 hPa and 10 circulation types (i.e. the data we used in this study)

- [data/cost_CESM12-LE_historical_rcp85_1960-2099_Z500.dat](data/cost_CESM12-LE_historical_rcp85_1960-2099_Z500.dat) is the COST733class classification output for the CESM data using geopotential height fields at 500 hPa

- [data/cost_CMIP5_historical_rcp85_1960-2099_Z500.dat](data/cost_CMIP5_historical_rcp85_1960-2099_Z500.dat) is the COST733class classification output for the CMIP5 data using geopotential height fields at 500 hPa

- [data/cost_CESM12-LE_historical_rcp85_1960-2099_PSL.dat](data/cost_CESM12-LE_historical_rcp85_1960-2099_PSL.dat) is the COST733class classification output for the CESM data using sea level pressure fields

- [data/cost_CMIP5_historical_rcp85_1960-2099_PSL.dat](data/cost_CMIP5_historical_rcp85_1960-2099_PSL.dat) is the COST733class classification output for the CMIP5 data using sea level pressure fields 

- [data/cost_CMIP5_historical_rcp85_1960-2099_uas.dat](data/cost_CMIP5_historical_rcp85_1960-2099_uas.dat) is the COST733class classification output for the CMIP5 data using eastward near-surface wind as input

- [data/date.dat](data/date.dat) and [data/date_no_leap_days.dat](data/date_no_leap_days.dat) contain the first three columns with YYYY | MM | DD data for a period with leap days and without leap days

COST733class classification output is given the following way:

```
| YYYY | MM | DD | ens. member 1 | ens. member 2 | ens. member 3 | ... |
| 1960 | 01 | 01 |       1       |       2       |       4       | ... |
| 1960 | 01 | 02 |       1       |       1       |       3       | ... |
| .... | .. | .. |      ...      |      ...      |      ...      | ... |
| 2099 | 12 | 31 |       1       |       4       |       3       | ... |

```
where `1` is the westerly circulation type, `2`, north-westerly, `NaN` is a leap day, ...  

More information on the CDO and COST733class commands can also be found in the Technical Appendix of the Supporting Information.