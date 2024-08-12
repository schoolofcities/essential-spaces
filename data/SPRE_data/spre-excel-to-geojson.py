import pandas as pd
import geopandas as gpd
from shapely.geometry import Point

file_name = "2021_SPRE_DATA_Aug8.xlsx"
sheet_name = "Primary-2021-Clean"

df = pd.read_excel(file_name, sheet_name=sheet_name)

df = df.dropna(subset=['211_Address1'])
df['211_Address2'] = df['211_Address2'].fillna('')

df["N"] = df["211 Parent Agency Name"]
df["A"] = df["211_Address1"].astype(str) + " " + df["211_Address2"].astype(str)
df['A'] = df['A'].str.rstrip()
df["C"] = df["CRA Category"]
df["S"] = df["CRA Subcategory"]
df["T"] = df["Tenure"]

df = df[["N","A","C","S","T","Latitude","Longitude"]]

df = df.drop_duplicates()

geometry = [Point(xy) for xy in zip(df['Longitude'], df['Latitude'])]
gdf = gpd.GeoDataFrame(df, geometry=geometry)
gdf = gdf.drop(columns=['Latitude', 'Longitude'])
gdf.set_crs(epsg=4326, inplace=True)

print(gdf)

gdf.to_file('SPRE_2021_wgs84.geo.json', driver='GeoJSON', precision=5)