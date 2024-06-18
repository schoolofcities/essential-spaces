<script>

import { onMount } from "svelte";
import maplibregl from "maplibre-gl";
import "../assets/styles.css";
import cartoBasemap from "../assets/carto-basemap.json";


onMount(() => {

	map = new maplibregl.Map({
        container: "map",
        style: cartoBasemap, //'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
        center: [-79.0, 44.1], // starting position
        zoom: 8, // starting zoom;
        minZoom: 2,
        maxZoom: 17,
        projection: "globe",
        scrollZoom: true,
        attributionControl: true,
    });

})

</script>




<div id="panel">
	<h2>Non-Profit Real Estate</h2>
	<h3>Toronto, Peel, York</h3>
    <!-- Content for the left panel -->
    <!-- You can add text, images, or other elements here -->
</div>

<div id="map">
	
    <!-- Content for the right panel -->
    <!-- You can add text, images, or other elements here -->
</div>