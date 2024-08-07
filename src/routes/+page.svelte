<script>

import { onMount } from "svelte";
import maplibregl from "maplibre-gl";
// import * as pmtiles from "pmtiles";


import "../assets/styles.css";
import baseMap from "../assets/basemap.json";
import topMap from "../assets/topmap.json"
import spre from "../assets/SPRE_2021_wgs84.geo.json";
import admin from "../assets/admin_boundaries.geo.json"; 
import adminUpperTier from "../assets/admin-upper-tier.geo.json"; 
import adminLowerTier from "../assets/admin-lower-tier.geo.json"; 
import nonResMask from "../assets/non-residential-mask.geo.json";
import Select from "svelte-select";
import equity from "../assets/equitylayers.geo.json";
import library from "../assets/library.geo.json";
import rec from "../assets/rec.geo.json";
import housing from "../assets/shelters_and_housing.geo.json";
import triangle_library from "../assets/triangle_library.svg";
import triangle_housing from "../assets/triangle_housing.svg";
import triangle_rec from "../assets/triangle_rec.svg";


//Changing the map layer

const defaultMap = "Equity Index"
let mapSelected = defaultMap

// let colours = ["#fff5f0", "#fcbba1", "#fb6a4a", "#cb181d", "#810010"]

// let colours = ["#FCEDE6", "#F9DCCD", "#EE9769", "#E97537", "#E97537"]

// let colours = ["#F4EFF7", "#EADFEF", "#D5C0DF", "#AB81BF", "#AB81BF"]

// let colours = ["#FBE9E8", "#F8D4D2", "#EB8B84", "#E15449", "#E15449"]

// let colours = ["#F8D4D2", "#F0A9A4", "#E97F77", "#E15449","#E15449"]

let colours = ["#f7ecc3", "#f2cd8d", "#eeb05b", "#e78052", "#e15449"]

let spreColours = [ "#793B91","#338ED8", "#A3A3A3"]



const choropleths = {
	"Equity Index" :{
		dataSource: "Equity Index",
		group: "Equity Layer",
		breaks: [0.32, 0.40, 0.47, 0.57],
		colours: colours,
		text: "The index summarizes all equity indicators in this sub-list with an equal weight. Areas in the higher quintiles may present a stronger need for community services due to the socio-economic disadvantages that residents might be experiencing.",
	},
	// "Population Density":{
	// 	dataSource: "PopuDenPerKM",
	// 	breaks: [1000, 5000, 7500, 10000], 
	// 	colours: colours,
	// 	text: "1 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
	// },
	"% Short-Term Workers":{
		dataSource: "ShortTerm%",
		group: "Equity Layer",
		breaks: [9, 11, 13, 15],
		colours: colours,
		text: "Percentage of workers who self-reported as an employee with a contract shorter than one year, out of the total number of employees in the 2021 Census",
	},
	"% of Youth Not in Employment, Education or Training":{
		dataSource: "Neet%", 
		group: "Equity Layer",
		breaks:[10, 15, 20, 25],
		colours: colours,
		text: "Percentage of youth aged between 18-29 who were unemployed, not in school/training, or not in the labour force, out of the total youth population of the same age range",
	},
	"% of Recent Immigrants":{
		dataSource: "Immigrant%",
		group: "Other Layer",
		breaks: [5, 10, 15, 20],
		colours: colours,
		text: "Percentage of immigrants who migrated to Canada between 2016 to 2021 based on the 2021 Census, out of the total population",
	},
	"% of Visible Minority":{
		dataSource: "VM%", 
		group: "Other Layer",
		breaks: [5, 25, 50, 75],
		colours: colours,
		text: "Percentage of people who self-identified as visible minority in the 2021 Census, out of the total population",
	},
	"% of Single Parent Family":{
		dataSource: "1-ParentFam%",
		group: "Other Layer", 
		breaks: [15, 20, 30, 40],
		colours: colours,
		text: "Percentage of households self-reported as a one-parent household in the 2021 Census, out of the total number of household",
	},
	"% of Renter in Core Housing Need":{
		dataSource: "%CHN", 
		group: "Equity Layer",
		breaks: [10, 20, 30, 40], 
		colours: colours,
		text: "Percentage of renters who reported experiencing at least one core housing need (e.g. housing affordability, suitability, and adequacy) in the 2021 Census, out of the total renter population",
	},
	"% of Renter in Unaffordable Housing":{
		dataSource: "%Affordable", 
		group: "Equity Layer",
		breaks: [5, 20, 30, 40],
		colours: colours,
		text: "Percentage of renters who spent over 30% of their before-tax household income on rent as reported in the 2021 Census, out of the total renter population",
	},
	
	"% in Low Income Household (MBM)":{
		dataSource: "MBM%",
		group: "Equity Layer",
		breaks:[5, 10, 15, 20],
		colours: colours,
		text: "Percentage of residents in low-income households, based on the 2021 Census data as measured by the Market Basket Measure (MBM)",
	},

	"% of Low Income Housing by LIM":{
		dataSource: "LIM%", 
		group: "Equity Layer",
		breaks: [5, 15, 25, 35], 
		colours: colours,
		text: "Percentage of low-income household based on 2021 T1 tax file income data as measured by the Low Income Measure (LIM), out of all households",
	},

	"% of Working Poor":{
		dataSource: "%ofWP",
		group: "Equity Layer",
		breaks: [5, 10, 15, 20],
		colours: colours,
		text: "Percentage of working adults aged 18-64 (excluding full-time and part-time students) who earned more than $3,000 monthly and lived in low-income households by LIM, out of all working adults of that age range",
	},
};
const items = Object.keys(choropleths).map(key => {
    return {
        value: key,
		label: key,
        ...choropleths[key]
    };
});
console.log(items);

// console.log(choropleths["population-density"].colours[0]);

let map = null;

function layerSelect(e) {
	console.log(layerSelect);
	mapSelected = e.detail.value;
	layerSet(mapSelected);
}

function layerSet(layer) {
	console.log(layer)
	let choropleth = choropleths[layer]
	map.setPaintProperty("equity", "fill-color", [
		"case",
		["!=", ["get", choropleth.dataSource], null],
		[
			"step",
			["get", choropleth.dataSource],
			choropleth.colours[0],
			choropleth.breaks[0],
			choropleth.colours[1],
			choropleth.breaks[1],
			choropleth.colours[2],
			choropleth.breaks[2],
			choropleth.colours[3],
			choropleth.breaks[3],
			choropleth.colours[4],
		],
		"#cbcbcb",
	])
	map.setPaintProperty("equity", "fill-outline-color", [
		"case",
		["!=", ["get", choropleth.dataSource], null],
		[
			"step",
			["get", choropleth.dataSource],
			choropleth.colours[0],
			choropleth.breaks[0],
			choropleth.colours[1],
			choropleth.breaks[1],
			choropleth.colours[2],
			choropleth.breaks[2],
			choropleth.colours[3],
			choropleth.breaks[3],
			choropleth.colours[4],
		],
		"#cbcbcb",
	])
}

let bounds = [
  [-81.5, 43.0], // [west, south]
  [-77.5, 45.5],  // [east, north]
];


let spreSelection = ["Own", "Rent", "Unknown"]; 

$:spreSelection, filterSPRE()

function filterSPRE() {
		console.log (spreSelection)

		let opacity =[
					'match',
					['get', 'Tenure'],
					'Own', spreSelection.includes("Own")?1:0,
					'Rent', spreSelection.includes("Rent")?1:0,
					spreSelection.includes("Unknown")?1:0,
				]

		console.log (opacity)
		
		if (map) {
			map.setPaintProperty('spre', 'circle-opacity', opacity);
			map.setPaintProperty('spre', 'circle-stroke-opacity', opacity);
		}
	}   

let onLibrary = false;

$: onLibrary, filterlibrary()

function filterlibrary() {
	if (map) {
		if (onLibrary) {
			map.setPaintProperty('library', 'icon-opacity', 1);
		} else {
			map.setPaintProperty('library', 'icon-opacity', 0);
		}
	}
}

let onHousing = false;

$: onHousing, filterhousing()

function filterhousing() {
	if (map) {
		if (onHousing) {
			map.setPaintProperty('housing', 'icon-opacity', 1);
		} else {
			map.setPaintProperty('housing', 'icon-opacity', 0);
		}
	}
}

let onRec = false;

$:  onRec, filterRec()

function filterRec() {
	if (map) {
		if (onRec) {
			map.setPaintProperty('rec', 'icon-opacity', 1);
		} else {
			map.setPaintProperty('rec', 'icon-opacity', 0);
		}
	}
}

onMount(() => {

	// let protocol = new pmtiles.Protocol();
	// maplibregl.addProtocol("pmtiles", protocol.tile);

	map = new maplibregl.Map({
		container: "map",
		style: baseMap, //'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
		center: [-79.46, 43.78], // starting position
		zoom: 10, // starting zoom;
		minZoom: 8, //furthest you can zoom out
		maxZoom: 14, //furthest you can zoom in
		bearing: -17,
		projection: "globe",
		scrollZoom: true,
		attributionControl: false
	});

	map.setMaxBounds(bounds);

	map.touchZoomRotate.disableRotation();

	map.addControl(new maplibregl.NavigationControl());
	map.addControl(new maplibregl.ScaleControl(), "bottom-right");

	map.on('load', () => {

		map.addSource('equity', {
			type: 'geojson',
			data: equity
		})

		map.addLayer(
			{
				id: "equity",
				type: "fill",
				source: "equity",
				paint: {
					"fill-opacity": 0.9,
					"fill-color": "#fff",
					"fill-outline-color": "#fff"
				},
			}
		);

		layerSet(mapSelected);

		map.addSource("nonResMask", {
			type: "geojson",
			data: nonResMask
		});

		map.addLayer({
			"id": "nonResMask",
			"type": "fill",
			"source": "nonResMask",
			"paint": {
				"fill-color": "#F7F7F7",
				"fill-outline-color": "#F7F7F7",
				"fill-opacity": 0.95
			},
		})
		
		topMap.forEach(e => {
			map.addLayer(e);
		});

		map.addSource(
			'adminLowerTier', {
				type: 'geojson', 
				data: adminLowerTier
			}
		)

		map.addLayer({
			'id':'adminLowerTier',
			'type':'line',
			'source':'adminLowerTier',
			'paint': {
				'line-color': '#a09f9f',
				'line-opacity': 0.75,
				'line-width': 1
			}
		})

		map.addSource(
			'adminUpperTier', {
				type: 'geojson', 
				data: adminUpperTier
			}
		)

		map.addLayer({
			'id':'adminUpperTier',
			'type':'line',
			'source':'adminUpperTier',
			'paint': {
				'line-color': '#a09f9f',
				'line-opacity': 1,
				'line-width': 1.5
			}
		})

	

		
		map.addSource('library', {
			type: 'geojson',
			data: library
		})

		//triangle symbol for library

		let libImage = new Image();
		libImage.src = triangle_library; 
		libImage.onload = function (){
			
			map.addImage('triangle_library', libImage);

			map.addLayer({
				'id': 'library',
				'type': 'symbol',
				'source': 'library',
				'layout': {
						"icon-image": "triangle_library",
						"icon-size": [
								"interpolate", ["linear"], ["zoom"],
								0.05,
								0.01,
								25,
								1.3
						],
						"icon-allow-overlap": true 
				},
				'paint': {
					"icon-color":"#FF0000",
					"icon-opacity":0
				}
			});

		}

		map.addSource('housing', {
			type: 'geojson',
			data: housing
		})

	//triangle symbol for housing

		let housingImage = new Image();
		housingImage.src = triangle_housing; 
		housingImage.onload = function (){
			
			map.addImage('triangle_housing', housingImage);

			map.addLayer({
				'id': 'housing',
				'type': 'symbol',
				'source': 'housing',
				'layout': {
						"icon-image": "triangle_housing",
						"icon-size": [
								"interpolate", ["linear"], ["zoom"],
								0.05,
								0.01,
								25,
								1.3
						],
						"icon-allow-overlap": true 
				},
				'paint': {
					"icon-color":"#FF0000",
					"icon-opacity":0
				}
			});

		}

		map.addSource('rec', {
			type: 'geojson',
			data: rec
		})

		//triangle symbol for rec centre
		let recImage = new Image();
		recImage.src = triangle_rec; 
		recImage.onload = function (){
			
			map.addImage('triangle_rec', recImage);

			map.addLayer({
				'id': 'rec',
				'type': 'symbol',
				'source': 'rec',
				'layout': {
						"icon-image": "triangle_rec",
						"icon-size": [
								"interpolate", ["linear"], ["zoom"],
								0.05,
								0.01,
								25,
								1.3
						],
						"icon-allow-overlap": true 
				},
				'paint': {
					"icon-color":"#FF0000",
					"icon-opacity":0
				}
			});

		}

		map.addSource('spre', {
					type: 'geojson',
					data: spre
				})

		map.addLayer({
			'id': 'spre',
					'type': 'circle',
					'source': 'spre',
					'paint': {
						"circle-color": [
							'match',
							['get', 'Tenure'],
							'Own', spreColours[1], 
							'Rent', spreColours[0], 
							spreColours[2] 
						],
						"circle-radius" : [
							"interpolate", ["linear"], ["zoom"],
							8,1.5,
							12,6
						],
						"circle-stroke-color": [
							'match',
							['get', 'Tenure'],
							'Own', '#fff', 
							'Rent', '#fff', 
							'#fff' //grey
						],
						"circle-opacity": [
							'match',
							['get', 'Tenure'],
							'Own', 1, 
							'Rent', 1, 
							1 //grey
						],
						"circle-stroke-opacity": [
							'match',
							['get', 'Tenure'],
							'Own', 1, 
							'Rent', 1, 
							1 
						],
						"circle-stroke-width": 0.7
					}
		})

	})
	// Add tool tips for SPRE
	map.on('click', 'spre', (e) => {
		const coordinates = e.features[0].geometry.coordinates.slice();
		const description = e.features[0].properties["211 Parent Agency Name"];
		const tenure = " (Tenure: " + e.features[0].properties["Tenure"] + ")";

		while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
			coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
		}

		const htmlContent =  description + tenure

		const popup = new maplibregl.Popup({closeOnClick: true, closeButton: false})
			.setLngLat(coordinates)
			.setHTML(htmlContent)
			.addTo(map);

		const popupContent = popup._content;
		if (popupContent) {
			popupContent.style.padding = '6px 12px 6px 6px'
			popupContent.style.backgroundColor = '#ffffff';
			popupContent.style.boxShadow = '0 0 10px rgba(0, 0, 0, 0.2)';
			popupContent.style.opacity = 0.95;
			}
	});

	map.on('mouseenter', 'spre', () => {
			map.getCanvas().style.cursor = 'pointer';
		});

	map.on('mouseleave', 'spre', () => {
		map.getCanvas().style.cursor = '';
	});

	// Add tool tips for Library
	map.on('click', 'library', (e) => {
		const coordinates = e.features[0].geometry.coordinates.slice();
		const description = e.features[0].properties["Branch Name"];
		const type = " (Library)"

		while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
			coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
		}

		const htmlContent =  description + type

		const popup = new maplibregl.Popup({closeOnClick: true, closeButton: false})
			.setLngLat(coordinates)
			.setHTML(htmlContent)
			.addTo(map);

		const popupContent = popup._content;
		if (popupContent) {
			popupContent.style.padding = '6px 12px 6px 6px'
			popupContent.style.backgroundColor = '#ffffff';
			popupContent.style.boxShadow = '0 0 10px rgba(0, 0, 0, 0.2)';
			popupContent.style.opacity = 0.95;
			}
	});

	map.on('mouseenter', 'library', () => {
			map.getCanvas().style.cursor = 'pointer';
		});

	map.on('mouseleave', 'library', () => {
		map.getCanvas().style.cursor = '';
	});

	// Add tool tips for RecCentre
	map.on('click', 'rec', (e) => {
		const coordinates = e.features[0].geometry.coordinates.slice();
		const description = e.features[0].properties["Name"];
		const type = " (Community Centre)"

		while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
			coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
		}

		const htmlContent =  description + type

		const popup = new maplibregl.Popup({closeOnClick: true, closeButton: false})
			.setLngLat(coordinates)
			.setHTML(htmlContent)
			.addTo(map);

		const popupContent = popup._content;
		if (popupContent) {
			popupContent.style.padding = '6px 12px 6px 6px'
			popupContent.style.backgroundColor = '#ffffff';
			popupContent.style.boxShadow = '0 0 10px rgba(0, 0, 0, 0.2)';
			popupContent.style.opacity = 0.95;
			}
	});

	map.on('mouseenter', 'rec', () => {
			map.getCanvas().style.cursor = 'pointer';
		});

	map.on('mouseleave', 'rec', () => {
		map.getCanvas().style.cursor = '';
	});

	// Add tool tips for Community Housing and Shelters
	map.on('click', 'housing', (e) => {
		const coordinates = e.features[0].geometry.coordinates.slice();
		const description = e.features[0].properties["Name"];
		const type = " (Type: " + e.features[0].properties["Type"] + ")";

		while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
			coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
		}

		const htmlContent =  description + type

		const popup = new maplibregl.Popup({closeOnClick: true, closeButton: false})
			.setLngLat(coordinates)
			.setHTML(htmlContent)
			.addTo(map);

		const popupContent = popup._content;
		if (popupContent) {
			popupContent.style.padding = '6px 12px 6px 6px'
			popupContent.style.backgroundColor = '#ffffff';
			popupContent.style.boxShadow = '0 0 10px rgba(0, 0, 0, 0.2)';
			popupContent.style.opacity = 0.95;
			}
	});

	map.on('mouseenter', 'housing', () => {
			map.getCanvas().style.cursor = 'pointer';
		});

	map.on('mouseleave', 'housing', () => {
		map.getCanvas().style.cursor = '';
	});
})

</script>

<div id="container">

<div id="panel">
	<h1>Community Real Estate</h1>
	<!-- Content for the left panel -->
	<!-- You can add text, images, or other elements here -->
	<p>This map examines the real estate landscape of the Greater Toronto Area's (GTA) community services sector as of 2021. The map allows us to analyze the distribution of owned and leased Community Real Estate (CRE) offering services in Peel, Toronto and York Region and their proximity to equity-seeking groups, providing insight into risks and opportunities for preserving and developing CRE within the community services sector. 
	</p>

	<h3>Select CRE Locations By Tenure</h3>

	<div id="checkbox" class="check-box">
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Own"} /> Own <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="{spreColours[1]}" stroke="#fff" stroke-width="1"/></svg></label>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Rent"} /> Rent <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="{spreColours[0]}" stroke="#fff" stroke-width="1"/></label>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Unknown"} /> Unknown <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="{spreColours[2]}" stroke="#fff" stroke-width="1"/></label>
	</div>

	<h3>Select Base Map Layer</h3>

	<div id="select-wrapper">
		<Select
			id="select"
			items={items}
			groupBy={(items) => items.group}
			value={defaultMap}
			clearable={false}
			showChevron={true}
			listAutoWidth={false}
			listOffset = 10
			on:input={layerSelect}
			--margin = 16px
			--width=387.52px
			--background="white"
			--selected-item-color= var(--brandBlack)
			--height=22px
			--item-color=var(--brandBlack)
			--border-radius=0px
			--border="1px solid var(--brandGray)"
			--border-focused='1px solid #A50F00'
			--list-border-radius="0px"
			--font-size="14.45px"
			--max-height="30px"
			--item-is-active-color="#FFFFFF"
			--item-is-active-bg="#DA291C"
			--chevron-color="#DA291C"
			--item-hover-bg="#F8D4D2"
		/>
	</div>

	<svg width='400' height='{mapSelected == "Equity Index" ? 24 : 40}'>
		<rect
		class = "box"
		width="74"
		height="20"
		x="18"
		y="0"
		style="fill:{colours[0]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="94"
		y="0"
		style="fill:{colours[1]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="170"
		y="0"
		style="fill:{colours[2]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="246"
		y="0"
		style="fill:{colours[3]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="322"
		y="0"
		style="fill:{colours[4]};"
		/>

		{#if mapSelected == "Equity Index"}
		
		<text class="legend-label"  x="20" y="15">1st Quintile</text>
		<text class="legend-label"  x="120" y="15">2nd</text>
		<text class="legend-label"  x="200" y="15">3rd</text>
		<text class= "legend-label-dark"  x="275" y="15">4th</text>
		<text class= "legend-label-dark"  x="350" y="15">5th</text>

		{:else}

		<text class="legend-label"  x="80" y="35">&lt;{choropleths[mapSelected].breaks[0]}</text>
		<text class="legend-label"  x="160" y="35">{choropleths[mapSelected].breaks[1]}</text>
		<text class="legend-label"  x="235" y="35">{choropleths[mapSelected].breaks[2]}</text>
		<text class="legend-label"  x="305" y="35">&gt{choropleths[mapSelected].breaks[3]}</text>

		{/if}

	</svg>

	<p class="des">
	{choropleths[mapSelected].text}
	</p>
	
	<h3>Add Other Resources</h3>

	<div id="checkbox" class="check-box">
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onLibrary}/> Library <svg height="16" width="16" class="check-box-svg"><polygon points="8,2 2,16 15,16" fill="#7BF253" stroke= "#E3E3E3" stroke-width="1" /></label>
			
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onRec}/> Recreation & Community Centre <svg height="16" width="16" class="check-box-svg"><polygon points="8,2 2,16 15,16" fill="#EAB4FF" stroke= "#E3E3E3" stroke-width="1" /></label>

		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onHousing}/> Community Housing & Shelter <svg height="16" width="16" class="check-box-svg"><polygon points="8,2 2,16 15,16" fill="#A1D9FF" stroke= "#E3E3E3" stroke-width="1" /></label>
			
	</div>

</div>

<div id="map">
	
	<!-- Content for the right panel -->
	<!-- You can add text, images, or other elements here -->
</div>

</div>

<style>
	.check-box {
		margin-left: 16px;
		margin-right: 16px;
		width: 387px
	}

	.label-format {
		padding-right: 4px;
	}

	.check-box-item{ 
		accent-color: #DA291C;
		transform: scale(1.25);
	}

	.check-box-svg {
		width: 16px;
		height: 16px; 
		margin-top : 4px;
	}

	.des {
		margin-top: 4px;
		margin-left: 20px;
		margin-right: 20px;
		font-size: 14px;
		line-height: 18px;
	}

	.box {
		stroke-width: 0.5px;
		stroke: rgb(206, 206, 206);
	}

	.legend-label {
			font-size: 14px;
			fill:var(--brandBlack);
			font-weight: 400;
			text-anchor: "middle";
		}

	.legend-label-dark {
		font-size: 14px;
		fill:var(--brandWhite);
		font-weight: 400;
		text-anchor: "middle";
	}

	#legend {
		background-color: white;
	}
</style>