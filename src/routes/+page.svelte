<script>

import { onMount } from "svelte";
import maplibregl from "maplibre-gl";
import "../assets/styles.css";
import cartoBasemap from "../assets/carto-basemap.json";
import spre from "../assets/2021_clean.geo.json";
import admin from "../assets/admin_boundaries.geo.json"; 



onMount(() => {

	let map = new maplibregl.Map({
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
                            'Own', '#0072CE',
                            'Rent', '#DA291C',
                            '#54585A'
                        ],
                        "circle-radius" : 2,
                        "circle-stroke-color": "#54585A",
                        "circle-stroke-width": 0.5
                    }

        })

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
</div>



<div id="map">
	
    <!-- Content for the right panel -->
    <!-- You can add text, images, or other elements here -->
</div>

</div>