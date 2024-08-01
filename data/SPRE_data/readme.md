## Data


The input data folder contains the raw CRA T3010 files and 211 Ontario data for 2021. These are raw data files without processing and cleaning. 

The SPRE_2021_wgs84 geojson is the cleaned up SPRE locations, where empty addresses were removed, saved in the WGS84 projection system.

The "2021_SPRE_DATA_Jul23" csv file contains all relevant matches of SPRE locations (a match between CRA and 211 data), without removing empty addresses from the dataset

## Jupyter Notebooks

"CRA T3010 Data Cleaning" includes codes that clean and transform the CRA T3010 form data

"211-CRA Fuzzy Matching" includes codes and algorithms that fuzzy match data between CRA and 211 Ontario datasets. Further manual steps were done to check the validity of the matches, where rows were further removed after confirming that they were not correct matches. The final dataset for SPRE location is "2021_SPRE_DATA_Jul23.csv"