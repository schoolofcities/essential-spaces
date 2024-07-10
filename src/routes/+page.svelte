<script>

import { onMount } from "svelte";
import maplibregl, { Color } from "maplibre-gl";
import "../assets/styles.css";
import cartoBasemap from "../assets/carto-basemap.json";
import spre from "../assets/2021_clean.geo.json";
import admin from "../assets/admin_boundaries.geo.json"; 
import Select from "svelte-select";
import equity from "../assets/equitylayers.geo.json";

//Changing the map layer

let mapSelected = "Population Density"

let colours = ["#fff5f0", "#fcbba1", "#fb6a4a", "#cb181d", "#67000d"]

const choropleths = {
    "Population Density":{
        dataSource: "PopuDenPerKM",
        breaks: [1000, 5000, 7500, 10000], 
        colours: colours,
    },
    "% of Short-Term Workers":{
        dataSource: "ShortTerm%",
        breaks: [5, 10, 15, 20],
        colours: colours,
    },
    "% of Youth Not in Employment, Education or Training":{
        dataSource: "Neet%", 
        breaks:[5, 10, 15, 20],
        colours: colours,
    },
    "% of Recent Immigrants":{
        dataSource: "Immigrant%",
        breaks: [5, 10, 15, 20],
        colours: colours,
    },
    "% of Visible Minority":{
        dataSource: "VM%", 
        breaks: [5, 25, 50, 75],
        colours: colours,
    },
    "% of Single Parent Family":{
        dataSource: "1-ParentFam%", 
        breaks: [15, 20, 30, 40],
        colours: colours,
    },
    "% of Renter in Core Housing Need":{
        dataSource: "%CHN", 
        breaks: [10, 20, 30, 40], 
        colours: colours,
    },
    "% of Renter in Unaffordable Housing":{
        dataSource: "%Affordable", 
        breaks: [5, 20, 30, 40],
        colours: colours,
    },
    "% of Working Poor":{
        dataSource: "%ofWP",
        breaks: [5, 10, 15, 20],
        colours: colours,
    },
    "% of Low Income Housing by LIM":{
        dataSource: "LIM%", 
        breaks: [5, 15, 25, 35], 
        colours: colours,
    },
    "% of Low Income Housing by MBM":{
        dataSource: "MBM%",
        breaks:[5, 10, 15, 20],
        colours: colours,
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

onMount(() => {

	map = new maplibregl.Map({
        container: "map",
        style: cartoBasemap, //'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
        center: [-79.0, 44.1], // starting position
        zoom: 9, // starting zoom;
        minZoom: 8, //furthest you can zoom out
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
                            'Own', '#FFFF00',
                            'Rent', '#FF0090',
                            '#D3D4D7'
                        ],
                        "circle-radius" : 2,
                        "circle-stroke-color": "#FFFFFF",
                        "circle-stroke-width": 0.5
                    }

        })

    })
})

</script>


<div id="container">

<div id="panel">
	<h1>Non-Profit Real Estate</h1>
	<h2>Toronto, Peel, York</h2>
    <!-- Content for the left panel -->
    <!-- You can add text, images, or other elements here -->
	<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed non risus. Suspendisse lectus tortor, dignissim sit amet, adipiscing nec, ultricies sed, dolor. Cras elementum ultrices diam. Maecenas ligula massa, varius a, semper congue, euismod non, mi. Proin porttitor, orci nec nonummy molestie, enim est eleifend mi, non fermentum diam nisl sit amet erat. Duis semper. Duis arcu massa, scelerisque vitae, consequat in, pretium a, enim. Pellentesque congue. Ut in risus volutpat libero pharetra tempor. 
	</p>

    <h3>Select Equity Map Layer</h3>

    <div id="select-wrapper">
        <Select
            id="select"
            items={Object.keys(choropleths)}
            value={"Population Density"}
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
            --list-border-radius="0px"
            --font-size="14.45px"
            --max-height="30px"
            --item-is-active-color="#0D534D"
            --item-is-active-bg="#6FC7EA"
        />
    </div>

    <svg width='418' height='50'>
        <rect
        class = "box"
        width="60"
        height="20"
        x="72"
        y="0"
        style="fill:{colours[0]};"
        />

        <rect
        class = "box"
        width="60"
        height="20"
        x="136"
        y="0"
        style="fill:{colours[1]};"
        />

        <rect
        class = "box"
        width="60"
        height="20"
        x="200"
        y="0"
        style="fill:{colours[2]};"
        />

        <rect
        class = "box"
        width="60"
        height="20"
        x="264"
        y="0"
        style="fill:{colours[3]};"
        />

        <rect
        class = "box"
        width="60"
        height="20"
        x="328"
        y="0"
        style="fill:{colours[4]};"
        />

        <text class="legend-label"  x="115" y="35">&lt;{choropleths[mapSelected].breaks[0]}</text>
        <text class="legend-label"  x="190" y="35">{choropleths[mapSelected].breaks[1]}</text>
        <text class="legend-label"  x="250" y="35">{choropleths[mapSelected].breaks[2]}</text>
        <text class="legend-label"  x="310" y="35">&gt{choropleths[mapSelected].breaks[3]}</text>

    </svg>

    <div>
       
    </div>
</div>

<div id="map">
	
    <!-- Content for the right panel -->
    <!-- You can add text, images, or other elements here -->
</div>

</div>

<style>
    .box {
        stroke-width: 0.5px;
        stroke: rgb(206, 206, 206);
    }

    .legend-label {
            font-size: 14px;
            fill:var(--brandDarkBlue);
            font-weight: 400;
            text-anchor: "middle";
        }

    #legend {
        background-color: white;
    }
</style>