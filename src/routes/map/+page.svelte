<script>

import { onMount } from "svelte";
import maplibregl from "maplibre-gl";
import * as pmtiles from "pmtiles";
import Select from "svelte-select";

import "../../assets/styles.css";

import baseMap from "./assets/basemap.json";
import topMap from "./assets/topmap.json"

// this geo.json has been edited manually oct 7 2024 to include the case study locations
// original data is in the /data top folder 
import spre from "./assets/SPRE_2021_wgs84.geo.json"; 
// New locations added to map
// -- Leonard's Place Peel - 1105 Queen St. E, Brampton, rented
// -- Krasman Centre, 10121 Yonge St., Richmond Hill, rented
// -- Unison Health (Bathurst Finch Hub) - 540 Finch Ave W, Toronto, own
// Ones that we already have listed but need some editing
// -- Inn from the cold - change from own to rent
// -- Miziwe Biik  on Gerrard - change from rent to own
// -- Family Service Toronto is already there with no edits needed!

import adminUpperTier from "./assets/admin-upper-tier.geo.json"; 
import adminLowerTier from "./assets/admin-lower-tier.geo.json"; 
import adminLowerTierCentroids from "./assets/admin-lower-tier-centroids.geo.json"; 
import nonResMask from "./assets/non-residential-mask.geo.json";

import equity from "./assets/ct-data-all.geo.json";
import library from "./assets/library.geo.json";
import rec from "./assets/rec.geo.json";
import housing from "./assets/shelters_and_housing.geo.json";
import transitStops from "./assets/transitStops-toronto.geo.json";
import transitLines from "./assets/transitLines-toronto.geo.json";
import transitStopsFuture from "./assets/transitStops-toronto-future.geo.json";
import transitLinesFuture from "./assets/transitLines-toronto-future.geo.json";

let blocksURL = "/essential-spaces/map/blocks-data-2021.pmtiles";

import triangle_library from "./assets/triangle_library_2.svg";
import triangle_housing from "./assets/triangle_housing.svg";
import triangle_rec from "./assets/triangle_rec_2.svg";


//Changing the map layer

const defaultMap = "Equity Index"
let mapSelected = defaultMap

let colours = ["#f7ecc3", "#f2cd8d", "#eeb05b", "#e78052", "#e15449"];
let streetBaseColour = "#cbcbd4";
let spreColours = [ "#793B91","#338ED8", "#A3A3A3"]



const choropleths = {
	"Equity Index" :{
		dataSource: "Equity Index",
		group: "Equity Layers",
		breaks: [0.3584, 0.4262, 0.4841, 0.5532],
		colours: colours,
		text: "The layer combines the seven equity layers as a single metric. Areas in the higher quintiles have a greater need for community services due to the greater socio-economic disadvantages experienced by residents."
	},
	"Street Map":{
		dataSource: "meow",
		group: "Other Layers",
		breaks: [5, 10, 15, 20],
		colours: [streetBaseColour,streetBaseColour,streetBaseColour,streetBaseColour,streetBaseColour],
		text: "Street data from OpenStreetMap",
	},
	"Population Density":{
		dataSource: "PopuDenPerKM",
		group: "Other Layers",
		breaks: [2000, 4000, 8000, 16000], 
		colours: colours,
		text: "Block-level population density from the 2021 Canadian census  (residents per square kilometre)",
	},
	"% in Low Income Household (MBM)":{
		dataSource: "MBM%",
		group: "Equity Layers",
		breaks:[5, 10, 15, 20],
		colours: colours,
		text: "Percentage of residents in low-income households, based on the 2021 Census data as measured by the Market Basket Measure (MBM)",
	},
	"% of Low Income Housing (LIM)":{
		dataSource: "LIM%", 
		group: "Equity Layers",
		breaks: [5, 15, 25, 35], 
		colours: colours,
		text: "Percentage of residents low-income household based on 2021 T1 tax file income data as measured by the Low Income Measure (LIM)",
	},
	"% of Working Poor":{
		dataSource: "%ofWP",
		group: "Equity Layers",
		breaks: [2.5, 5, 10, 15],
		colours: colours,
		text: "Percentage of working adults aged 18-64 (excluding full-time and part-time students) who earned more than $3,000 monthly and lived in low-income households by LIM, out of all working adults of that age range",
	},
	"% Short-Term Workers":{
		dataSource: "ShortTerm%",
		group: "Equity Layers",
		breaks: [9, 11, 13, 15],
		colours: colours,
		text: "Percentage of workers who self-reported as an employee with a contract shorter than one year, out of the total number of employees in the 2021 Census",
	},
	"% of Youth Not in Employment, Education or Training":{
		dataSource: "Neet%", 
		group: "Equity Layers",
		breaks:[10, 15, 20, 25],
		colours: colours,
		text: "Percentage of youth aged between 18-29 who were unemployed, not in school/training, or not in the labour force, out of the total youth population of the same age range",
	},
	"% of Recent Immigrants":{
		dataSource: "Immigrant%",
		group: "Other Layers",
		breaks: [2.5, 5, 10, 15],
		colours: colours,
		text: "Percentage of population who migrated to Canada between 2016 to 2021 based on the 2021 Census",
	},
	"% of Visible Minority":{
		dataSource: "VM%", 
		group: "Other Layers",
		breaks: [20, 40, 60, 80],
		colours: colours,
		text: "Percentage of people who self-identified as visible minority in the 2021 Census, out of the total population",
	},
	"% Single Parent Household":{
		dataSource: "1-ParentFam%",
		group: "Other Layers", 
		breaks: [15, 20, 25, 30],
		colours: colours,
		text: "Percentage of households self-reported as a one-parent household in the 2021 Census, out of the total number of households with children",
	},
	"% of Renters in Core Housing Need":{
		dataSource: "%CHN", 
		group: "Equity Layers",
		breaks: [10, 20, 30, 40], 
		colours: colours,
		text: "Percentage of renters who reported experiencing at least one core housing need (e.g. housing affordability, suitability, and adequacy) in the 2021 Census, out of the total renter population",
	},
	"% of Renters in Unaffordable Housing":{
		dataSource: "%Affordable", 
		group: "Equity Layers",
		breaks: [10, 20, 30, 40],
		colours: colours,
		text: "Percentage of renters who spent over 30% of their before-tax household income on rent as reported in the 2021 Census, out of the total renter population",
	}
};
const items = Object.keys(choropleths).map(key => {
    return {
        value: key,
		label: key,
        ...choropleths[key]
    };
});


let map = null;

function layerSelect(e) {
	mapSelected = e.detail.value;
	layerSet(mapSelected);
}

function layerSet(layer) {
	if (layer === "Street Map") {
		map.setPaintProperty("equity", "fill-opacity", 0);
		map.setPaintProperty("background", "background-color", streetBaseColour);
		map.setPaintProperty("nonResMask", "fill-opacity", 0);
		map.setPaintProperty("blocks", "fill-opacity", 0);
	} else if (layer === "Population Density") {
		map.setPaintProperty("equity", "fill-opacity", 0);
		map.setPaintProperty("nonResMask", "fill-opacity", 0.95);
		map.setPaintProperty("background", "background-color", "#f5f5f5");
		map.setPaintProperty("blocks", "fill-opacity", 0.9);
	} else {
		let choropleth = choropleths[layer]
		map.setPaintProperty("equity", "fill-opacity", 0.9)
		map.setPaintProperty("nonResMask", "fill-opacity", 0.95);
		map.setPaintProperty("background", "background-color", "#f5f5f5");
		map.setPaintProperty("blocks", "fill-opacity", 0);
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
	
}

let bounds = [
  [-81.5, 43.0], // [west, south]
  [-77.5, 45.5],  // [east, north]
];


let spreSelection = ["Own", "Rent", "Unknown"]; 

$:spreSelection, filterSPRE()

function filterSPRE() {
	let opacity =[
				'match',
				['get', 'T'],
				'Own', spreSelection.includes("Own")?1:0,
				'Rent', spreSelection.includes("Rent")?1:0,
				spreSelection.includes("Unknown")?1:0,
			]	
	if (map) {
		map.setPaintProperty('spre', 'circle-opacity', opacity);
		map.setPaintProperty('spre', 'circle-stroke-opacity', opacity);
	}
}   


let onTransit = true;

$:  onTransit, filterTransit()

function filterTransit() {
	if (map) {
		if (onTransit) {
			map.setPaintProperty('transitLines', 'line-opacity', 0.8);
			map.setPaintProperty('transitStops', 'circle-opacity', 1);
			map.setPaintProperty('transitStops', 'circle-stroke-opacity', 1);
		} else {
			map.setPaintProperty('transitLines', 'line-opacity', 0);
			map.setPaintProperty('transitStops', 'circle-opacity', 0);
			map.setPaintProperty('transitStops', 'circle-stroke-opacity', 0);
		}
	}
}

let onTransitFuture = false;

$:  onTransitFuture, filterTransitFuture()

function filterTransitFuture() {
	if (map) {
		if (onTransitFuture) {
			map.setPaintProperty('transitLinesFuture', 'line-opacity', 0.8);
			map.setPaintProperty('transitStopsFuture', 'circle-opacity', 1);
			map.setPaintProperty('transitStopsFuture', 'circle-stroke-opacity', 1);
		} else {
			map.setPaintProperty('transitLinesFuture', 'line-opacity', 0);
			map.setPaintProperty('transitStopsFuture', 'circle-opacity', 0);
			map.setPaintProperty('transitStopsFuture', 'circle-stroke-opacity', 0);
		}
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
			map.setPaintProperty('housing', 'circle-opacity', 1);
		} else {
			map.setPaintProperty('housing', 'circle-opacity', 0);
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

	let protocol = new pmtiles.Protocol();
	maplibregl.addProtocol("pmtiles", protocol.tile);

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
		maxPitch: 0,
		attributionControl: false
	});

	map.setMaxBounds(bounds);

	// map.touchZoomRotate.disableRotation();
	// map.dragRotate.disable();


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

		map.addSource("blocks", {
			type: "vector",
			url: "pmtiles://" + blocksURL,
		});

		map.addLayer({
			"id": "blocks",
			"type": "fill",
			"source": "blocks",
			"source-layer": "blockdata2021wgs84",
			"paint": {
				"fill-opacity": 0,
				"fill-color": [
					"case",
					["!=", ["get", "popdens"], null],
					[
						"step",
						["get", "popdens"],
						colours[0],
						2000,
						colours[1],
						4000,
						colours[2],
						8000,
						colours[3],
						16000,
						colours[4],
					],
					"#cbcbcb",
				]
			}
		})

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

		layerSet(mapSelected);
		
		topMap.forEach(e => {
			map.addLayer(e);
		});

		map.addSource(
			'transitLinesFuture', {
				type: 'geojson', 
				data: transitLinesFuture
			}
		)
		map.addLayer({
			'id':'transitLinesFuture',
			'type':'line',
			'source':'transitLinesFuture',
			'paint': {
				'line-color': '#3d3846',
				'line-opacity': 0,
				'line-width': 1.5,
				'line-dasharray': [2, 2] 
			}
		})

		map.addSource(
			'transitStopsFuture', {
				type: 'geojson', 
				data: transitStopsFuture
			}
		)
		map.addLayer({
			'id':'transitStopsFuture',
			'type':'circle',
			'source':'transitStopsFuture',
			'paint': {
				'circle-stroke-color': '#3d3846',
				'circle-color': "#fff",
				'circle-radius': [
					'interpolate',
					['linear'],
					['zoom'],
					8, 1,
					14, 4
				],
				"circle-stroke-width": 1,
				"circle-opacity": 0,
				"circle-stroke-opacity": 0
			}
		})

		map.addSource(
			'transitLines', {
				type: 'geojson', 
				data: transitLines
			}
		)
		map.addLayer({
			'id':'transitLines',
			'type':'line',
			'source':'transitLines',
			'paint': {
				'line-color': '#3d3846',
				'line-opacity': 0.8,
				'line-width': 1.5,
				'line-dasharray': [8, 2] 
			}
		})

		map.addSource(
			'transitStops', {
				type: 'geojson', 
				data: transitStops
			}
		)
		map.addLayer({
			'id':'transitStops',
			'type':'circle',
			'source':'transitStops',
			'paint': {
				'circle-stroke-color': '#3d3846',
				'circle-color': "#fff",
				'circle-radius': [
					'interpolate',
					['linear'],
					['zoom'],
					8, 1,
					14, 4
				],
				"circle-stroke-width": 1,
				"circle-opacity": 1,
				"circle-stroke-opacity": 1
			}
		})

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
			'adminLowerTierCentroids', {
				type: 'geojson', 
				data: adminLowerTierCentroids
			}
		)
		map.addLayer({
			'id': 'adminLowerTierCentroids',
			'type': 'symbol',
			'source': 'adminLowerTierCentroids',
			'layout': {
				'text-field': "{J_CSDNAME}", 
				'text-font': [
					"TradeGothic LT Bold"
				],
				'text-ignore-placement': true,
				'text-allow-overlap': true,
				'text-size': [
					'interpolate',
					['linear'],
					['zoom'],
					8, 12,
					14, 22
				], 
				'text-anchor': 'center' 
			},
			'paint': {
				'text-color': '#4d4d4d', 
				'text-halo-color': '#ffffff', 
				'text-halo-width': 1,
				'text-opacity': [
					'interpolate',
					['linear'],
					['zoom'],
					8, 0,
					10, 1
				]
			}
		});

		map.addSource(
			'adminUpperTier', {
				type: 'geojson', 
				data: adminUpperTier
			}
		)
		map.addLayer({
			'id':'adminUpperTierCase',
			'type':'line',
			'source':'adminUpperTier',
			'paint': {
				'line-color': '#4d4d4d',
				'line-opacity': 0.05,
				'line-width': 8
			}
		})
		map.addLayer({
			'id':'adminUpperTier',
			'type':'line',
			'source':'adminUpperTier',
			'paint': {
				'line-color': '#4d4d4d',
				'line-opacity': 0.8,
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

		let housingImage = new Image();
		housingImage.src = triangle_housing; 
		housingImage.onload = function (){
			
			map.addImage('triangle_housing', housingImage);

			map.addLayer({
				'id': 'housing',
				'type': 'circle',
				'source': 'housing',
				'paint': {
					"circle-color":"#000",
					"circle-radius": [
						"interpolate", ["linear"], ["zoom"],
						8, 1,
						12, 3.5
					],
					"circle-opacity": 0
				}
			});

		}

		map.addSource('rec', {
			type: 'geojson',
			data: rec
		})

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
					['get', 'T'],
					'Own', spreColours[1], 
					'Rent', spreColours[0], 
					spreColours[2] 
				],
				"circle-radius" : [
					"interpolate", ["linear"], ["zoom"],
					8,2.5,
					10,3.5,
					12,7
				],
				"circle-stroke-color": [
					'match',
					['get', 'T'],
					'Own', '#fff', 
					'Rent', '#fff', 
					'#fff' 
				],
				"circle-opacity": [
					'match',
					['get', 'T'],
					'Own', 1, 
					'Rent', 1, 
					1 
				],
				"circle-stroke-opacity": [
					'match',
					['get', 'T'],
					'Own', 1, 
					'Rent', 1, 
					1 
				],
				"circle-stroke-width": 1
			}
		})

	})
	// Add tool tips for SPRE
	map.on('click', 'spre', (e) => {
		const coordinates = e.features[0].geometry.coordinates.slice();
		const description = e.features[0].properties["N"];
		const tenure = " (Tenure: " + e.features[0].properties["T"] + ")";

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

})

</script>

<div id="container">

<div id="panel">

	<div id="title">
		
		<h1>Essential Spaces</h1>

		<h2>Real (Estate) Solutions for Community Needs</h2>

	</div>

	<p>
		This map examines the real estate landscape of the Greater Toronto Area's (GTA) community services sector as of 2021. The map allows us to analyze the location of a sample of owned and leased agency spaces offering services in Peel, Toronto and York Region and their proximity to equity-seeking groups, providing insight into risks and opportunities for preserving and developing real estate within the community services sector. 
		<a href="https://www.unitedwaygt.org/wp-content/uploads/2024/10/Essential-Spaces-Full-Report-compressed.pdf" target="_blank">Click here to read our research report</a>.
	</p>

	<div class="line"></div>


	<h3>Select Agency Spaces By Tenure</h3>

	<div id="checkbox" class="check-box">
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Own"} /> Owned <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="{spreColours[1]}" stroke="#fff" stroke-width="1"/></svg></label>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Rent"} /> Leased <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="{spreColours[0]}" stroke="#fff" stroke-width="1"/></label>
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
			listAutoWidth={true}
			searchable={false}
			listOffset = 10
			on:input={layerSelect}
			--margin = 16px
			--width=380px
			--multi-max-width=300px
			--background="white"
			--selected-item-color= var(--brandBlack)
			--height=22px
			--item-color=var(--brandBlack)
			--border-radius=0px
			--border="1px solid var(--brandGray)"
			--border-focused='1px solid #A50F00'
			--list-border-radius="0px"
			--font-size="13.7px"
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
		style="fill:{choropleths[mapSelected].colours[0]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="94"
		y="0"
		style="fill:{choropleths[mapSelected].colours[1]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="170"
		y="0"
		style="fill:{choropleths[mapSelected].colours[2]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="246"
		y="0"
		style="fill:{choropleths[mapSelected].colours[3]};"
		/>

		<rect
		class = "box"
		width="74"
		height="20"
		x="322"
		y="0"
		style="fill:{choropleths[mapSelected].colours[4]};"
		/>

		{#if mapSelected == "Equity Index"}
		
		<text class="legend-label"  x="20" y="15">1st Quintile</text>
		<text class="legend-label"  x="120" y="15">2nd</text>
		<text class="legend-label"  x="200" y="15">3rd</text>
		<text class= "legend-label-dark"  x="275" y="15">4th</text>
		<text class= "legend-label-dark"  x="350" y="15">5th</text>

		{:else if mapSelected == "Street Map"}


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
	
	<h3>Select Other Reference Layers</h3>

	<div id="checkbox" class="check-box">
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onTransit}/> 
			Major Transit Lines (Existing)
			<!-- <img src="{triangle_library}" alt="Library Symbol" width="13" height="13"> -->
		</label>
		<br>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onTransitFuture}/> 
			Major Transit Lines (Future)
			<!-- <img src="{triangle_library}" alt="Library Symbol" width="13" height="13"> -->
		</label>
		<br>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onLibrary}/> 
			Library
			<img src="{triangle_library}" alt="Library Symbol" width="14" height="14">
		</label>
		<br>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onRec}/> 
			Recreation & Community Centre
			<img src="{triangle_rec}" alt="Recreation Symbol" width="14" height="14">
		</label>
		<br>
		<label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onHousing}/>
			Community Housing & Shelter
			<svg width="6px" height="10px" viewBox="0 0 6 6" xmlns="http://www.w3.org/2000/svg">
				<circle cx="3" cy="3" r="2" fill="black" />
			  </svg>
		</label>
			
	</div>


	<div class="line"></div>


	<h4>Data & Methods</h4>

	<p class="notes">
		<!-- Data on the location of agency spaces were derived from joining datasets from the Canadian Revenue Agency and 211, both from 2021. Their respective tenure (own or lease), was sourced from property tax assessment roles in each municipality. The equity index and all other demographic data are derived from the 2021 Census of Population. Read our report for details about our data collection and analysis process. All other built environment data (streets, transit, buildings) shown on a the map are from OpenStreetMap. The map and website was built by Jeff Allen and Teresa Lau at the School of Cities, University of Toronto as part of a wider research effort alongside United Way Greater Toronto and the Infrastructure Institute. Data and code for this map are on GitHub. -->
		Data on the location of agency spaces were derived from joining datasets from the <a href="https://open.canada.ca/data/en/dataset/08ae3944-1a9d-483a-a7ae-116bc58199fd" target="_blank">Canadian Revenue Agency</a> and <a href="https://211ontario.ca/211-data/" target="_blank">211</a>, both from 2021. Their respective tenure (own or lease), was sourced from property tax assessment roles in each municipality. The equity index and all other demographic data are derived from the <a href="https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/index.cfm?Lang=E" target="_blank">2021 Census of Population</a>. <a href="https://www.unitedwaygt.org/wp-content/uploads/2024/10/Essential-Spaces-Full-Report-compressed.pdf" target="_blank">Read our report</a> for details about our data collection and analysis process. All other built environment data (streets, transit, buildings) shown on a the map are from <a href="https://www.openstreetmap.org/" target="_blank">OpenStreetMap</a>. The map and website was built by <a href="https://jamaps.github.io/"  target="_blank">Jeff Allen</a> and <a href="https://www.linkedin.com/in/teresacmlau/" target="_blank">Teresa Lau</a> at the <a href="https://schoolofcities.utoronto.ca/" target="_blank">School of Cities, University of Toronto</a> as part of a wider research effort alongside <a href="https://www.unitedwaygt.org/" target="_blank">United Way Greater Toronto</a> and the <a href="https://infrastructureinstitute.ca/" target="_blank">Infrastructure Institute</a>. Data and code for this map are on <a href="https://github.com/schoolofcities/non-profit-real-estate" target="_blank">GitHub</a>.
	</p>
	
	<div class="line"></div>

	<img src="./map/logos.svg" alt="United Way & University of Toronto Logos" />

	<div class="line"></div>

	<br>
	<br>


</div>


<div id="map"></div>


</div>




<style>

	.check-box {
		margin-left: 16px;
		margin-right: 16px;
		width: 387px
	}

	.label-format {
		padding-right: 4px;
		font-size: 14px;
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

	
</style>