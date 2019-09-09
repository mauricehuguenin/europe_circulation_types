# europe_circulation_types
Scripts used for my MeteoSwiss/ETH Zurich project *Assessing Changes in the Frequency and Persistence of Atmospheric Circulation Types Over Central Europe*

# Filename explanation
The star (*) symbol represents either of the two model data sets, i.e. CESM or CMIP5
- extract_patterns*.m are the MATLAB files I used to pull out all the circulation type maps shown in the Supporting Information Fig. S9-S20
- leap_day*.py are the scripts I used to insert leap days every 4th year for those models that do not have leap days. I basically inserted a day with a 'NAN' circulation type randomly within that year which as a leap day. This was necessary in order to align the dates and the cost output files
- merging_cmip5.py and preprocessing_cesm.py are basically the same scripts but for the two model data sets and show the preprocessing of the raw output files in order for use in cost733class. See also the documentation in the Supporting Information, Section 2
- preprocessing_*_maps.py are the scripts used to prepare the raw model data sets for the circulation type maps in MATLAB
 

# To Do before submission:
- Create and document each script separately in this readme.
- Upload and annotate the matlab file I used to create my circulation type maps
- Link to article and supporting information
- More info on this readme -> Keeping in mind that another practicum student, Msc student might continue in this field
- Upload figures as well as in learning_python repository. This way people see which script creates what (check if allowed when I submit)
