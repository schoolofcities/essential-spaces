<script>

import { onMount } from "svelte";
import maplibregl, { Color } from "maplibre-gl";
import "../assets/styles.css";
import cartoBasemap from "../assets/carto-basemap.json";
import spre from "../assets/2021_clean.geo.json";
import admin from "../assets/admin_boundaries.geo.json"; 
import Select from "svelte-select";
import equity from "../assets/equitylayers.geo.json";
import library from "../assets/library.geo.json";
import rec from "../assets/rec.geo.json";

//Changing the map layer

const defaultMap = "Equity Index"
let mapSelected = defaultMap

let colours = ["#fff5f0", "#fcbba1", "#fb6a4a", "#cb181d", "#810010"]

const choropleths = {
    "Equity Index" :{
        dataSource: "Equity Index",
        breaks: [0.32, 0.40, 0.47, 0.57],
        colours: colours,
        text: "0 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },

    "Population Density":{
        dataSource: "PopuDenPerKM",
        breaks: [1000, 5000, 7500, 10000], 
        colours: colours,
        text: "1 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Short-Term Workers":{
        dataSource: "ShortTerm%",
        breaks: [5, 10, 15, 20],
        colours: colours,
        text: "2 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Youth Not in Employment, Education or Training":{
        dataSource: "Neet%", 
        breaks:[5, 10, 15, 20],
        colours: colours,
        text: "3 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Recent Immigrants":{
        dataSource: "Immigrant%",
        breaks: [5, 10, 15, 20],
        colours: colours,
        text: "4 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Visible Minority":{
        dataSource: "VM%", 
        breaks: [5, 25, 50, 75],
        colours: colours,
        text: "5- Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Single Parent Family":{
        dataSource: "1-ParentFam%", 
        breaks: [15, 20, 30, 40],
        colours: colours,
        text: "6- Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Renter in Core Housing Need":{
        dataSource: "%CHN", 
        breaks: [10, 20, 30, 40], 
        colours: colours,
        text: "7 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Renter in Unaffordable Housing":{
        dataSource: "%Affordable", 
        breaks: [5, 20, 30, 40],
        colours: colours,
        text: "8 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Working Poor":{
        dataSource: "%ofWP",
        breaks: [5, 10, 15, 20],
        colours: colours,
        text: "9 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Low Income Housing by LIM":{
        dataSource: "LIM%", 
        breaks: [5, 15, 25, 35], 
        colours: colours,
        text: "10 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
    "% of Low Income Housing by MBM":{
        dataSource: "MBM%",
        breaks:[5, 10, 15, 20],
        colours: colours,
        text: "11 - Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus nec iaculis mauris. Vivamus efficitur nunc ut sem luctus, at feugiat nisi fermentum. Integer varius est sit amet turpis.",
    },
};

// console.log(choropleths["population-density"].colours[0]);

let map = null;

function layerSelect(e) {
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
}

let bounds = [
  [-81.181572, 43.2550233], // [west, south]
  [-78.348139, 45.194804],  // [east, north]
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
            map.setPaintProperty('library', 'circle-opacity', 1);
        } else {
            map.setPaintProperty('library', 'circle-opacity', 0);
        }
    }
}

let onRec = false;

$:  onRec, filterRec()

function filterRec() {
    if (map) {
        if (onRec) {
            map.setPaintProperty('rec', 'circle-opacity', 1);
        } else {
            map.setPaintProperty('rec', 'circle-opacity', 0);
        }
    }
}

onMount(() => {

	map = new maplibregl.Map({
        container: "map",
        style: cartoBasemap, //'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
        center: [-79.0, 44.1], // starting position
        zoom: 9, // starting zoom;
        minZoom: 8.5, //furthest you can zoom out
        maxZoom: 12, //furthest you can zoom in
        projection: "globe",
        scrollZoom: true,
        attributionControl: true,
    });

    map.setMaxBounds(bounds);

    map.touchZoomRotate.disableRotation();

    map.on('load', () => {

        map.addSource(
            'admin', {
                type: 'geojson', 
                data: admin
            }
        )

        map.addLayer({
            'id':'admin',
            'type':'line',
            'source':'admin',
            'paint': {
                // boundary color is orange
                'line-color': '#E35205',
			    'line-opacity':[
                    'match', ['get', 'CSDUID'],
                    '0', 0.8,
                    0.4
                ],
                'line-width':[
                    'match', ['get', 'CSDUID'],
                    '0', 0.7,
                    0.3
                ],
            }

        })

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
                    "fill-outline-color": "white",
                    "fill-opacity": 0.881,
                    "fill-color": "#cbcbcb",
                },
            },
            "admin"
        );

        layerSet(mapSelected);

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
                            'Own', '#FFFF00', //neon yellow
                            'Rent', '#02D8E9', // neon blue
                            '#D3D4D7' //grey
                        ],
                        "circle-radius" : [
                            "interpolate", ["linear"], ["zoom"],
                            8,1.5,
                            12,5
                        ],
                        "circle-stroke-color": [
                            'match',
                            ['get', 'Tenure'],
                            'Own', '#CF9033', //neon yellow
                            'Rent', '#99007A', // purple pink
                            '#A9A9A9' //grey
                        ],
                        "circle-opacity": [
                            'match',
                            ['get', 'Tenure'],
                            'Own', 1, //neon yellow
                            'Rent', 1, // purple pink
                            1 //grey
                        ],
                        "circle-stroke-opacity": [
                            'match',
                            ['get', 'Tenure'],
                            'Own', 1, //neon yellow
                            'Rent', 1, // purple pink
                            1 //grey
                        ],
                        "circle-stroke-width": 0.5
                    }

        })

        map.addSource('library', {
            type: 'geojson',
            data: library
        })

        map.addLayer({
            'id': 'library',
            'type': 'circle',
            'source': 'library',
            'paint': {
                "circle-color":"#FF0000",
                "circle-radius" : [
                            "interpolate", ["linear"], ["zoom"],
                            8,1.5,
                            12,5
                        ],
                "circle-opacity":0
            }
        })

        map.addSource('rec', {
            type: 'geojson',
            data: rec
        })

        map.addLayer({
            'id': 'rec',
            'type': 'circle',
            'source': 'rec',
            'paint': {
                "circle-color":"#00FF00",
                "circle-radius" : [
                            "interpolate", ["linear"], ["zoom"],
                            8,1.5,
                            12,5
                        ],
                "circle-opacity":0
            }
        })

    })
})

</script>


<div id="container">

<div id="panel">
	<h1>Social Purpose Real Estate:</h1>
	<h2>In Toronto, Peel, & York</h2>
    <!-- Content for the left panel -->
    <!-- You can add text, images, or other elements here -->
	<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi. Proin porttitor, orci nec nonummy molestie, enim est eleifend mi, non fermentum diam nisl sit amet erat. Duis semper. 
	</p>

    <h3>Add SPRE Locations</h3>

    <div id="checkbox" class="check-box">
        <label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Own"} /> Own <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="#FFFF00" stroke="#4d4d4d" stroke-width="1"/></svg></label>
        <label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Rent"} /> Rent <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="#78e3fe" stroke="#4d4d4d" stroke-width="1"/></label>
        <label class="label-format"><input type="checkbox" class="check-box-item" bind:group={spreSelection} value={"Unknown"} /> Unknown <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="#D3D4D7" stroke="#4d4d4d" stroke-width="1"/></label>
    </div>

    <h3>Select Equity Map Layer</h3>

    <div id="select-wrapper">
        <Select
            id="select"
            items={Object.keys(choropleths)}
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
        <label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onLibrary}/> Library <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="#F00000" stroke="#FF0000" stroke-width="1"/></label>
        <label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onRec}/> Recreation & Community Centre <svg class="check-box-svg"><circle cx="6" cy="10.5" r="5" fill="#00FF00" stroke="#00FF00" stroke-width="1"/></label>
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
        height: 16px
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