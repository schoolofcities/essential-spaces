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

let mapLayers = [
    "Population Density", 
    "% of Short-Term Workers",
    "% of Youth Not in Employment, Education or Training",
    "% of Recent Immirgants",
    "% of Visible Minority",
    "% of Single Parent Family", 
    "% of Renter in Core Housing Need",
    "% of Renter in Unaffordable Housing", 
    "% of Working Poor",
    "% of Low Income Housing by LIM",
    "% of Low Income Housing by MBM",
]; 

let mapSelected = "Population Density"

let colours = ["#F9E4E2", "#FBB7B1", "#E3685F", "#DA291C", "#A50F00"]

const choropleths = {
    "population-density":{
        name: "Population Density",
        breaks: [1000, 5000, 7500, 10000], 
        colours: colours,
    },
    "short-term-work":{
        name: "% of Short-Term Workers",
        breaks: [5, 10, 15, 20],
        colours: colours,
    },
    "NEET":{
        name: "% of Youth Not in Employment, Education or Training", 
        breaks:[5, 10, 15, 20],
        colours: colours,
    },
    "immigrants":{
        name: "% of Recent Immirgants", 
        breaks: [5, 10, 15, 20],
        colours: colours,
    },
    "visible-minority":{
        name:"% of Visible Minority", 
        breaks: [5, 25, 50, 75],
        colours: colours,
    },
    "single-parent-family":{
        name: "% of Single Parent Family", 
        breaks: [15, 20, 30, 40],
        colours: colours,
    },
    "core-housing-need":{
        name: "% of Renter in Core Housing Need", 
        breaks: [10, 20, 30, 40], 
        colours: colours,
    },
    "unaffordable housing":{
        name: "% of Renter in Unaffordable Housing", 
        break: [5, 20, 30, 40],
        colours: colours,
    },
    "working poor":{
        name: "% of Working Poor", 
        breaks: [5, 10, 15, 20],
        colours: colours,
    },
    "LIM":{
        name: "% of Low Income Housing by LIM", 
        breaks: [5, 15, 25, 35], 
        colours: colours,
    },
    "MBM":{
        name: "% of Low Income Housing by MBM",
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

function layerSet (layer) {
    console.log(layer);
    if (layer === "Population Density") {
        try{
            map.removeLayer("equity");
            map.removeSource("equity");
        } catch {}
        // map.SetPaintProperty()
        map.addLayer(
                {
                    id: "equity",
                    type: "fill",
                    source: {
                        type: "geojson",
                        data: equity,
                    },
                    paint: {
                        "fill-outline-color": "white",
                        "fill-opacity": 0.881,
                        "fill-color": [
                            "case",
                            ["!=", ["get", "PopuDenPerKM"], null],
                            [
                                "step",
                                ["get", "PopuDenPerKM"],
                                choropleths["population-density"].colours[0],
                                choropleths["population-density"].breaks[0],
                                choropleths["population-density"].colours[1],
                                choropleths["population-density"].breaks[1],
                                choropleths["population-density"].colours[2],
                                choropleths["population-density"].breaks[2],
                                choropleths["population-density"].colours[3],
                            ],
                            "#cbcbcb",
                        ],
                    },
                },
                "admin"
            );
    }
}



onMount(() => {

	map = new maplibregl.Map({
        container: "map",
        style: cartoBasemap, //'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
        center: [-79.0, 44.1], // starting position
        zoom: 9, // starting zoom;
        minZoom: 8,
        maxZoom: 17,
        projection: "globe",
        scrollZoom: true,
        attributionControl: true,
    });

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
                            'Own', '#B2FFFF',
                            'Rent', '#FFFF00',
                            '#54585A'
                        ],
                        "circle-radius" : 2,
                        "circle-stroke-color": "#54585A",
                        "circle-stroke-width": 0.5
                    }

        })

        layerSet(mapSelected);

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
            items={mapLayers}
            value={"Population Density"}
            clearable={false}
            showChevron={true}
            on:input={layerSelect}
            --background="white"
            --selected-item-color="#6D247A"
            --height="22px"
            --item-color="#6D247A"
            --border-radius="0"
            --border="1px"
            --list-border-radius="0px"
            --font-size="14.45px"
            --max-height="30px"
            --item-is-active-color="#0D534D"
            --item-is-active-bg="#6FC7EA"
        />
    </div>
</div>



<div id="map">
	
    <!-- Content for the right panel -->
    <!-- You can add text, images, or other elements here -->
</div>

</div>