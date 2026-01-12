<script>
    import { onMount } from "svelte";
    import maplibregl from "maplibre-gl";
    import * as pmtiles from "pmtiles";
    import Select from "svelte-select";
    import "../../assets/styles.css";

    // Map config imports
    import baseMap from "$lib/assets/map_config/basemap.json";
    import topMap from "$lib/assets/map_config/topmap.json"

    // Map regions imports
    import adminUpperTier from "$lib/assets/regions/admin-upper-tier.geo.json"; 
    import adminLowerTier from "$lib/assets/regions/admin-lower-tier.geo.json"; 
    import adminLowerTierCentroids from "$lib/assets/regions/admin-lower-tier-centroids.geo.json"; 
    import nonResMask from "$lib/assets/regions/non-residential-mask.geo.json";

    // Data and site/line locations
    import equity from "$lib/assets/data/ct-data-all.geo.json";

    import spre from "$lib/assets/locations/simplified_matches_4326.geo.json";  // this geo.json has been edited manually oct 7 2024 to include the case study locations. original data is in the /data top folder 
    import tenancy from "$lib/assets/locations/leased_points.geo.json"
    
    import library from "$lib/assets/locations/library.geo.json";
    import rec from "$lib/assets/locations/rec.geo.json";
    import housing from "$lib/assets/locations/shelters_and_housing.geo.json";
    import transitStops from "$lib/assets/locations/transitStops-toronto.geo.json";
    import transitLines from "$lib/assets/locations/transitLines-toronto.geo.json";
    import transitStopsFuture from "$lib/assets/locations/transitStops-toronto-future.geo.json";
    import transitLinesFuture from "$lib/assets/locations/transitLines-toronto-future.geo.json";
    
    // Image Imports
    import triangle_library from "$lib/img/triangle_library_2.svg";
    import triangle_housing from "$lib/img/triangle_housing.svg";
    import triangle_rec from "$lib/img/triangle_rec_2.svg";
    import square_tenancy from "$lib/img/square_tenancy.svg";
    
    // Constants
    const DEFAULT_MAP = "Equity Index"
    const COLOURS = ["#f7ecc3", "#f2cd8d", "#eeb05b", "#e78052", "#e15449"];
    const STREET_BASE_COLOUR = "#cbcbd4";
    const SPRE_COLOURS = [ "#793B91","#338ED8", "#A3A3A3"]
    const BOUNDS = [
        [-81.5, 43.0], // [west, south]
        [-77.5, 45.5],  // [east, north]
    ];
    const BLOCKS_URL = "/essential-spaces/map/blocks-data-2021.pmtiles.gz";
    const NOMINATIM_URL = "https://nominatim.openstreetmap.org/search?format=jsonv2&q=";

    // State variables
    let map = null;
    let mapSelected = DEFAULT_MAP;
    let query = "";
    let results;
    let onTransit = true;
    let onTransitFuture = false;
    let onLibrary = false;
    let onHousing = false;
    let onRec = false;
    let onTenancy = true;
    let spreSelection = ["Own", "Rent", "Unknown"];
    
    // Choropleth configuration
    const choropleths = {
        "Equity Index": {
            dataSource: "Equity Index",
            group: "Equity Layers",
            breaks: [0.2985527, 0.37396513, 0.43815575, 0.52905651],
            colours: COLOURS,
            text: "The layer combines the nine equity layers as a single metric. Areas in the higher quintiles have a greater need for community services due to the greater socio-economic disadvantages experienced by residents."
        },
        "Street Map": {
            dataSource: "meow",
            group: "Other Layers",
            breaks: [5, 10, 15, 20],
            colours: [STREET_BASE_COLOUR, STREET_BASE_COLOUR, STREET_BASE_COLOUR, STREET_BASE_COLOUR, STREET_BASE_COLOUR],
            text: "Street data from OpenStreetMap",
        },
        "Population Density": {
            dataSource: "PopuDenPerKM",
            group: "Other Layers",
            breaks: [2000, 4000, 8000, 16000],
            colours: COLOURS,
            text: "Block-level population density from the 2021 Canadian census (residents per square kilometre)",
        },
        "% of Low Income Housing (LIM)": {
            dataSource: "LIM%",
            group: "Equity Layers",
            breaks: [5, 15, 25, 35],
            colours: COLOURS,
            text: "Percentage of residents low-income household based on 2021 T1 tax file income data as measured by the Low Income Measure (LIM)",
        },
        "% Short-Term Workers": {
            dataSource: "ShortTerm%",
            group: "Equity Layers",
            breaks: [9, 11, 13, 15],
            colours: COLOURS,
            text: "Percentage of workers who self-reported as an employee with a contract shorter than one year, out of the total number of employees in the 2021 Census",
        },
        "% of Youth Not in Employment, Education or Training": {
            dataSource: "Neet%",
            group: "Equity Layers",
            breaks: [10, 15, 20, 25],
            colours: COLOURS,
            text: "Percentage of youth aged between 18-29 who were unemployed, not in school/training, or not in the labour force, out of the total youth population of the same age range",
        },
        "% of Recent Immigrants": {
            dataSource: "Immigrant%",
            group: "Other Layers",
            breaks: [2.5, 5, 10, 15],
            colours: COLOURS,
            text: "Percentage of population who migrated to Canada between 2016 to 2021 based on the 2021 Census",
        },
        "% of Visible Minority": {
            dataSource: "VM%",
            group: "Other Layers",
            breaks: [20, 40, 60, 80],
            colours: COLOURS,
            text: "Percentage of people who self-identified as visible minority in the 2021 Census, out of the total population",
        },
        "% Single Parent Household": {
            dataSource: "1-ParentFam%",
            group: "Other Layers",
            breaks: [15, 20, 25, 30],
            colours: COLOURS,
            text: "Percentage of households self-reported as a one-parent household in the 2021 Census, out of the total number of households with children",
        },
        "% of Renters in Core Housing Need": {
            dataSource: "%CHN",
            group: "Equity Layers",
            breaks: [10, 20, 30, 40],
            colours: COLOURS,
            text: "Percentage of renters who reported experiencing at least one core housing need (e.g. housing affordability, suitability, and adequacy) in the 2021 Census, out of the total renter population",
        },
        "% of Renters in Unaffordable Housing": {
            dataSource: "%Affordable",
            group: "Equity Layers",
            breaks: [10, 20, 30, 40],
            colours: COLOURS,
            text: "Percentage of renters who spent over 30% of their before-tax household income on rent as reported in the 2021 Census, out of the total renter population",
        },
        "% in Low Income Household (MBM)": {
            dataSource: "MBM%",
            group: "Other Layers",
            breaks: [5, 10, 15, 20],
            colours: COLOURS,
            text: "Percentage of residents in low-income households, based on the 2021 Census data as measured by the Market Basket Measure (MBM)",
        },
        "% of Working Poor": {
            dataSource: "%ofWP",
            group: "Other Layers",
            breaks: [2.5, 5, 10, 15],
            colours: COLOURS,
            text: "Percentage of working adults aged 18-64 (excluding full-time and part-time students) who earned more than $3,000 monthly and lived in low-income households by LIM, out of all working adults of that age range",
        },
        "% Total Income from Government Transfers": {
            dataSource: "%IncomeGT",
            group: "Equity Layers",
            breaks: [5, 10, 15, 20],
            colours: COLOURS,
            text: "The proportion of total household income derived from government programs such as social assistance, Employment Insurance (EI), and Old Age Security (OAS), based on the 2021 Census and T1FF data."
        },
        "Eviction Filing Rate": {
            dataSource: "%Evic",
            group: "Equity Layers",
            breaks: [1, 2.5, 5, 10],
            colours: COLOURS,
            text: "The proportion of renter households that were filed for eviction by their landlord, based on data from the Landlord and Tenant Board (LTB)."
        },
        "% Unemployment Rate": {
            dataSource: "%Unemp",
            group: "Equity Layers",
            breaks: [5, 10, 15, 20],
            colours: COLOURS,
            text: "The percentage of individuals in the labour force who are actively seeking employment but are currently without a job, based on the 2021 Census data."
        },
        "% without Certificate, Diploma, or Degree": {
            dataSource: "%NoEdu",
            group: "Equity Layers",
            breaks: [5, 10, 15, 20],
            colours: COLOURS,
            text: "The percentage of the population aged 15 and older without a certificate, diploma, or degree, based on the 2021 Census data."
        }
    };

    // Derived data
    const items = Object.keys(choropleths).map(key => ({
        value: key,
        label: key,
        ...choropleths[key]
    }));

    const spreOptions = [
        { value: "Own", label: "Owned", colorIndex: 1 },
        { value: "Rent", label: "Leased", colorIndex: 0 },
        { value: "Unknown", label: "Unknown", colorIndex: 2 }
    ];

    // Event handlers
    function layerSelect(e) {
        mapSelected = e.detail.value;
        layerSet(mapSelected);
    }

    function layerSet(layer) {
        if (!map) return;

        const choropleth = choropleths[layer];
        
        if (layer === "Street Map") {
            map.setPaintProperty("equity", "fill-opacity", 0);
            map.setPaintProperty("background", "background-color", STREET_BASE_COLOUR);
            map.setPaintProperty("nonResMask", "fill-opacity", 0);
            map.setPaintProperty("blocks", "fill-opacity", 0);
        } else if (layer === "Population Density") {
            map.setPaintProperty("equity", "fill-opacity", 0);
            map.setPaintProperty("nonResMask", "fill-opacity", 0.95);
            map.setPaintProperty("background", "background-color", "#f5f5f5");
            map.setPaintProperty("blocks", "fill-opacity", 0.9);
        } else {
            const fillColor = [
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
            ];
            
            map.setPaintProperty("equity", "fill-opacity", 0.9);
            map.setPaintProperty("nonResMask", "fill-opacity", 0.95);
            map.setPaintProperty("background", "background-color", "#f5f5f5");
            map.setPaintProperty("blocks", "fill-opacity", 0);
            map.setPaintProperty("equity", "fill-color", fillColor);
            map.setPaintProperty("equity", "fill-outline-color", fillColor);
        }
    }

    // Filter functions
    function filterSPRE() {
        if (!map) return;
        
        const opacity = [
            'match',
            ['get', 'T'],
            'Own', spreSelection.includes("Own") ? 1 : 0,
            'Rent', spreSelection.includes("Rent") ? 1 : 0,
            spreSelection.includes("Unknown") ? 1 : 0,
        ];
        
        map.setPaintProperty('spre', 'circle-opacity', opacity);
        map.setPaintProperty('spre', 'circle-stroke-opacity', opacity);
    }

    function filterTransit() {
        if (!map) return;
        
        if (onTransit) {
            map.setPaintProperty('transitLines', 'line-opacity', 0.95);
            map.setPaintProperty('transitStops', 'circle-opacity', 1);
            map.setPaintProperty('transitStops', 'circle-stroke-opacity', 1);
        } else {
            map.setPaintProperty('transitLines', 'line-opacity', 0);
            map.setPaintProperty('transitStops', 'circle-opacity', 0);
            map.setPaintProperty('transitStops', 'circle-stroke-opacity', 0);
        }
    }

    function filterTransitFuture() {
        if (!map) return;
        
        if (onTransitFuture) {
            map.setPaintProperty('transitLinesFuture', 'line-opacity', 0.95);
            map.setPaintProperty('transitStopsFuture', 'circle-opacity', 1);
            map.setPaintProperty('transitStopsFuture', 'circle-stroke-opacity', 1);
        } else {
            map.setPaintProperty('transitLinesFuture', 'line-opacity', 0);
            map.setPaintProperty('transitStopsFuture', 'circle-opacity', 0);
            map.setPaintProperty('transitStopsFuture', 'circle-stroke-opacity', 0);
        }
    }

    function filterLibrary() {
        if (!map) return;
        map.setPaintProperty('library', 'icon-opacity', onLibrary ? 1 : 0);
    }

    function filterHousing() {
        if (!map) return;
        map.setPaintProperty('housing', 'circle-opacity', onHousing ? 1 : 0);
    }

    function filterRec() {
        if (!map) return;
        map.setPaintProperty('rec', 'icon-opacity', onRec ? 1 : 0);
    }

    function filterTenancy() {
        if (!map) return;
        map.setPaintProperty('tenancy', 'icon-opacity', onTenancy ? 1 : 0);
    }

    // Reactive statements
    $: spreSelection, filterSPRE();
    $: onTransit, filterTransit();
    $: onTransitFuture, filterTransitFuture();
    $: onLibrary, filterLibrary();
    $: onHousing, filterHousing();
    $: onRec, filterRec();
    $: onTenancy, filterTenancy();

    onMount(() => {
        const protocol = new pmtiles.Protocol();
        maplibregl.addProtocol("pmtiles", protocol.tile);

        map = new maplibregl.Map({
            container: "map",
            style: baseMap, //'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json',
            center: [-79.46, 43.78], // starting position
            zoom: 10, // starting zoom;
            minZoom: 8, //furthest you can zoom out
            maxZoom: 14.5, //furthest you can zoom in
            bearing: -17,
            projection: "globe",
            scrollZoom: true,
            maxPitch: 0,
            attributionControl: false
        });

        map.setMaxBounds(BOUNDS);
        // map.touchZoomRotate.disableRotation();
        // map.dragRotate.disable();
        map.addControl(new maplibregl.NavigationControl());
        map.addControl(new maplibregl.ScaleControl(), "bottom-right");

        map.on('load', () => {
            // Add equity source and layer
            map.addSource('equity', { type: 'geojson', data: equity });
            map.addLayer({
                id: "equity",
                type: "fill",
                source: "equity",
                paint: {
                    "fill-opacity": 0.9,
                    "fill-color": "#fff",
                    "fill-outline-color": "#fff"
                }
            });

            // Add blocks source and layer
            map.addSource("blocks", {
                type: "vector",
                url: "pmtiles://" + BLOCKS_URL,
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
                            COLOURS[0],
                            2000,
                            COLOURS[1],
                            4000,
                            COLOURS[2],
                            8000,
                            COLOURS[3],
                            16000,
                            COLOURS[4],
                        ],
                        "#cbcbcb",
                    ]
                }
            });

            // Add non-residential mask
            map.addSource("nonResMask", { type: "geojson", data: nonResMask });
            map.addLayer({
                "id": "nonResMask",
                "type": "fill",
                "source": "nonResMask",
                "paint": {
                    "fill-color": "#F7F7F7",
                    "fill-outline-color": "#F7F7F7",
                    "fill-opacity": 0.95
                }
            });

            // Set initial layer
            layerSet(mapSelected);
            
            // Add top map layers
            topMap.forEach(e => {
                map.addLayer(e);
            });

            // Add future transit layers
            map.addSource('transitLinesFuture', { type: 'geojson', data: transitLinesFuture });
            map.addLayer({
                'id':'transitLinesFuture',
                'type':'line',
                'source':'transitLinesFuture',
                'paint': {
                    'line-color': '#3d3846',
                    'line-opacity': 0,
                    'line-width': 1.5,
                    'line-dasharray': [1.5, 1.5] 
                }
            });

            map.addSource('transitStopsFuture', { type: 'geojson', data: transitStopsFuture });
            map.addLayer({
                'id':'transitStopsFuture',
                'type':'circle',
                'source':'transitStopsFuture',
                'paint': {
                    'circle-stroke-color': '#3d3846',
                    'circle-color': "#fff",
                    'circle-radius': ['interpolate', ['linear'], ['zoom'], 8, 1, 14, 4],
                    "circle-stroke-width": 1,
                    "circle-opacity": 0,
                    "circle-stroke-opacity": 0
                }
            });

            // Add current transit layers
            map.addSource('transitLines', { type: 'geojson', data: transitLines });
            map.addLayer({
                'id':'transitLines',
                'type':'line',
                'source':'transitLines',
                'paint': {
                    'line-color': '#3d3846',
                    'line-opacity': 0.95,
                    'line-width': 1.5,
                    'line-dasharray': [6, 1.5] 
                }
            });

            map.addSource('transitStops', { type: 'geojson', data: transitStops });
            map.addLayer({
                'id':'transitStops',
                'type':'circle',
                'source':'transitStops',
                'paint': {
                    'circle-stroke-color': '#3d3846',
                    'circle-color': "#fff",
                    'circle-radius': ['interpolate', ['linear'], ['zoom'], 8, 1, 14, 4],
                    "circle-stroke-width": 1,
                    "circle-opacity": 1,
                    "circle-stroke-opacity": 1
                }
            });

            // Add admin boundaries
            map.addSource('adminLowerTier', { type: 'geojson', data: adminLowerTier });
            map.addLayer({
                'id':'adminLowerTier',
                'type':'line',
                'source':'adminLowerTier',
                'paint': {
                    'line-color': '#a09f9f',
                    'line-opacity': 0.75,
                    'line-width': 1
                }
            });

            map.addSource('adminLowerTierCentroids', { type: 'geojson', data: adminLowerTierCentroids });
            map.addLayer({
                'id': 'adminLowerTierCentroids',
                'type': 'symbol',
                'source': 'adminLowerTierCentroids',
                'layout': {
                    'text-field': "{J_CSDNAME}", 
                    'text-font': ["TradeGothic LT Bold"],
                    'text-ignore-placement': true,
                    'text-allow-overlap': true,
                    'text-size': ['interpolate', ['linear'], ['zoom'], 8, 12, 14, 22],
                    'text-anchor': 'center' 
                },
                'paint': {
                    'text-color': '#4d4d4d',
                    'text-halo-color': '#ffffff',
                    'text-halo-width': 1,
                    'text-opacity': ['interpolate', ['linear'], ['zoom'], 8, 0, 10, 1]
                }
            });

            map.addSource('adminUpperTier', { type: 'geojson', data: adminUpperTier });
            map.addLayer({
                'id':'adminUpperTierCase',
                'type':'line',
                'source':'adminUpperTier',
                'paint': {
                    'line-color': '#4d4d4d',
                    'line-opacity': 0.05,
                    'line-width': 8
                }
            });
            map.addLayer({
                'id':'adminUpperTier',
                'type':'line',
                'source':'adminUpperTier',
                'paint': {
                    'line-color': '#4d4d4d',
                    'line-opacity': 0.8,
                    'line-width': 1.5
                }
            });
            
            // Add library layer
            map.addSource('library', { type: 'geojson', data: library });
            const libImage = new Image();
            libImage.src = triangle_library;
            libImage.onload = function() {
                map.addImage('triangle_library', libImage);
                map.addLayer({
                    'id': 'library',
                    'type': 'symbol',
                    'source': 'library',
                    'layout': {
                        "icon-image": "triangle_library",
                        "icon-size": ["interpolate", ["linear"], ["zoom"], 0.05, 0.01, 25, 1.3],
                        "icon-allow-overlap": true 
                    },
                    'paint': {
                        "icon-color":"#FF0000",
                        "icon-opacity":0
                    }
                });
            };

            // Add housing layer
            map.addSource('housing', { type: 'geojson', data: housing });
            const housingImage = new Image();
            housingImage.src = triangle_housing;
            housingImage.onload = function() {
                map.addImage('triangle_housing', housingImage);
                map.addLayer({
                    'id': 'housing',
                    'type': 'circle',
                    'source': 'housing',
                    'paint': {
                        "circle-color":"#000",
                        "circle-radius": ["interpolate", ["linear"], ["zoom"], 8, 1, 12, 3.5],
                        "circle-opacity": 0
                    }
                });
            };

            // Add recreation layer
            map.addSource('rec', { type: 'geojson', data: rec });
            const recImage = new Image();
            recImage.src = triangle_rec;
            recImage.onload = function() {
                map.addImage('triangle_rec', recImage);
                map.addLayer({
                    'id': 'rec',
                    'type': 'symbol',
                    'source': 'rec',
                    'layout': {
                        "icon-image": "triangle_rec",
                        "icon-size": ["interpolate", ["linear"], ["zoom"], 0.05, 0.01, 25, 1.3],
                        "icon-allow-overlap": true 
                    },
                    'paint': {
                        "icon-color":"#FF0000",
                        "icon-opacity":0
                    }
                });
            };

            // Add tenancy layer
            map.addSource('tenancy', { type: 'geojson', data: tenancy });
            const tenancyImage = new Image();
            tenancyImage.src = square_tenancy;
            tenancyImage.onload = function() {
                map.addImage('square_tenancy', tenancyImage);
                map.addLayer({
                    'id': 'tenancy',
                    'type': 'symbol',
                    'source': 'tenancy',
                    'layout': {
                        "icon-image": "square_tenancy",
                        "icon-size": ["interpolate", ["linear"], ["zoom"], 8, 0.4, 10, 0.6, 12, 1.2],
                        "icon-allow-overlap": true 
                    },
                    'paint': {
                        "icon-opacity": 1
                    }
                });
            };

            // Add SPRE layer
            map.addSource('spre', { type: 'geojson', data: spre });
            map.addLayer({
                'id': 'spre',
                'type': 'circle',
                'source': 'spre',
                'paint': {
                    "circle-color": ['match', ['get', 'T'], 'Own', SPRE_COLOURS[1], 'Rent', SPRE_COLOURS[0], SPRE_COLOURS[2]],
                    "circle-radius": ["interpolate", ["linear"], ["zoom"], 8,2.5, 10,3.5, 12,7],
                    "circle-stroke-color": ['match', ['get', 'T'], 'Own', '#fff', 'Rent', '#fff', '#fff'],
                    "circle-opacity": ['match', ['get', 'T'], 'Own', 1, 'Rent', 1, 1],
                    "circle-stroke-opacity": ['match', ['get', 'T'], 'Own', 1, 'Rent', 1, 1],
                    "circle-stroke-width": 1
                }
            });
            
            // Add SPRE tooltips
            map.on('click', 'spre', (e) => {
                const coordinates = e.features[0].geometry.coordinates.slice();
                const description = e.features[0].properties["N"];
                const tenure = " (Tenure: " + e.features[0].properties["T"] + ")";

                while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
                    coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
                }

                const popup = new maplibregl.Popup({closeOnClick: true, closeButton: false})
                    .setLngLat(coordinates)
                    .setHTML(description + tenure)
                    .addTo(map);

                const popupContent = popup._content;
                if (popupContent) {
                    popupContent.style.padding = '6px 12px 6px 6px';
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
        });
    })

    // Address search
    const getResults = async () => {
        let inputQuery = query.endsWith("Canada") || query.endsWith("CA") || query.endsWith("Can") 
            ? query 
            : query + ", Canada";

        results = await fetch(NOMINATIM_URL + inputQuery).then((res) => res.json());

        if (map.getSource("address")) {
            map.removeLayer("address");
            map.removeSource("address");
        }

        if (results.length > 0) {
            const gtaResults = results.filter(result => 
                (parseFloat(result.lon) > -80.168 && parseFloat(result.lon) < -79.0935) && 
                (parseFloat(result.lat) < 44.338 && parseFloat(result.lat) > 43.471)
            );

            if (gtaResults.length > 0) {
                const { lat, lon } = gtaResults[0];

                map.flyTo({
                    center: [lon, lat],
                    zoom: 14.5,
                    bearing: -17,
                    speed: 2,
                    curve: 1,
                    easing(t) { return t; },
                    essential: true,
                });

                map.addSource("address", {
                    type: "geojson",
                    data: { type: "Point", coordinates: [lon, lat] }
                });
                map.addLayer({
                    id: "address",
                    type: "circle",
                    source: "address",
                    paint: {
                        "circle-radius": 12,
                        "circle-color": "white",
                        "circle-opacity": 0.85,
                        "circle-stroke-color": "black",
                        "circle-stroke-width": 4
                    }
                });

            } else {
                alert("Sorry, no address results for " + query + " in the GTA. Please double check your input and include a municipality name");
            }
        } else {
            alert("Sorry, no address results for " + query + " in the GTA. Please double check your input and include a municipality name");
        }
    }
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
        
        <p>
            This map has been updated since the 2024 Essential Spaces publication to provide a more comprehensive list of locations. While the overall trends remain consistent, a new publication with full details will be released in the near future.
        </p>

        <div class="line"></div>

        <h3>Select Agency Spaces By Tenure</h3>

        <div id="checkbox" class="check-box">
            {#each spreOptions as option}
                <label class="label-format">
                    <input 
                        type="checkbox" 
                        class="check-box-item" 
                        bind:group={spreSelection} 
                        value={option.value} 
                    /> 
                    {option.label}
                    <svg class="check-box-svg">
                        <circle 
                            cx="6" 
                            cy="10.5" 
                            r="5" 
                            fill="{SPRE_COLOURS[option.colorIndex]}" 
                            stroke="#fff" 
                            stroke-width="1"
                        />
                    </svg>
                </label>
            {/each}
        </div>

        <h3>Show tenancy spaces</h3>
        
        <div id="checkbox" class="check-box">
            <label class="label-format">
                <input type="checkbox" class="check-box-item" bind:checked={onTenancy}/> 
                Tenancy Spaces
                    <svg class="check-box-svg">
                        <rect 
                            x="2" 
                            y="6.5" 
                            width="8" 
                            height="8" 
                            fill="black" 
                            stroke="#fff" 
                            stroke-width="1"
                        />
                    </svg>
            </label>   
        </div>

        <h3>Select Base Map Layer</h3>

        <div id="select-wrapper">
            <Select
                id="select"
                items={items}
                groupBy={(items) => items.group}
                value={DEFAULT_MAP}
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
            <!-- Rectangles -->
            {#each { length: 5 } as _, i}
                <rect
                    class="box"
                    width="74"
                    height="20"
                    x={18 + i * 76}
                    y="0"
                    style="fill:{choropleths[mapSelected].colours[i]};"
                />
            {/each}

            <!-- Labels -->
            {#if mapSelected == "Equity Index"}
                {#each [
                    { x: 20, text: "1st Quintile" },
                    { x: 120, text: "2nd" },
                    { x: 200, text: "3rd" },
                    { x: 275, text: "4th" },
                    { x: 350, text: "5th" }
                ] as label, i}
                    <text 
                        class={i >= 3 ? "legend-label-dark" : "legend-label"} 
                        x={label.x} 
                        y="15"
                    >
                        {label.text}
                    </text>
                {/each}
            {:else if mapSelected != "Street Map"}
                {#each [80, 160, 235, 305] as x, i}
                    <text class="legend-label" x={x} y="35">
                        {i === 0 ? `<${choropleths[mapSelected].breaks[0]}` : 
                        i === 3 ? `>${choropleths[mapSelected].breaks[3]}` : 
                        choropleths[mapSelected].breaks[i]}
                    </text>
                {/each}
            {/if}
        </svg>

        <p class="des">
            {choropleths[mapSelected].text}
        </p>
        
        <h3>Select Other Reference Layers</h3>

        <div id="checkbox" class="check-box">
            <label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onTransit}/> 
                Major Transit Lines (Existing)
                <svg width="30" height="10" xmlns="http://www.w3.org/2000/svg">
                    <line x1="0" y1="6" x2="40" y2="6" stroke="black" stroke-width="2" stroke-dasharray="8, 2" />
                </svg>
            </label>
            <br>
            <label class="label-format"><input type="checkbox" class="check-box-item" bind:checked={onTransitFuture}/> 
                Major Transit Lines (Future)
                <svg width="30" height="10" xmlns="http://www.w3.org/2000/svg">
                    <line x1="0" y1="6" x2="40" y2="6" stroke="black" stroke-width="2" stroke-dasharray="3, 2" />
                </svg>
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

        <p>
            <b>Address Search</b> 
            <svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
                <circle cx="8" cy="8" r="6" fill="white" fill-opacity="0.85" stroke="black" stroke-width="3" />
            </svg>
        </p>

        <input id="address-search" bind:value={query} placeholder="e.g. 100 Queen St West, Toronto" />
        
        <button id="address-button" on:click={getResults} disabled={query.length < 1}>Search</button>

        <div class="line"></div>

        <h4>Data & Methods</h4>

        <p class="notes">
            Data on the location of agency spaces were derived from joining datasets from the <a href="https://open.canada.ca/data/en/dataset/08ae3944-1a9d-483a-a7ae-116bc58199fd" target="_blank">Canadian Revenue Agency</a> and <a href="https://211ontario.ca/211-data/" target="_blank">211</a>, both from 2021. Their respective tenure (own or lease), was sourced from property tax assessment roles in each municipality. The equity index and all other demographic data are derived from the <a href="https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/index.cfm?Lang=E" target="_blank">2021 Census of Population</a>, <a href="https://lemr.ca/about/" target="_blank">LEMR</a>, and the <a href="https://tribunalsontario.ca/ltb/" target="_blank">LTB</a>. <a href="https://www.unitedwaygt.org/wp-content/uploads/2024/10/Essential-Spaces-Full-Report-compressed.pdf" target="_blank">Read our report</a> for details about our data collection and analysis process. All other built environment data (streets, transit, buildings) shown on a the map are from <a href="https://www.openstreetmap.org/" target="_blank">OpenStreetMap</a>. The map and website was built by <a href="https://jamaps.github.io/"  target="_blank">Jeff Allen</a>, <a href="https://www.linkedin.com/in/teresacmlau/" target="_blank">Teresa Lau</a>, and <a href="https://www.linkedin.com/in/aniket-k-8a8b9921b/" target="_blank">Aniket Kali</a> at the <a href="https://schoolofcities.utoronto.ca/" target="_blank">School of Cities, University of Toronto</a> as part of a wider research effort alongside <a href="https://www.unitedwaygt.org/" target="_blank">United Way Greater Toronto</a> and the <a href="https://infrastructureinstitute.ca/" target="_blank">Infrastructure Institute</a>. Data and code for this map are on <a href="https://github.com/schoolofcities/non-profit-real-estate" target="_blank">GitHub</a>.
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

    #address-search {
        width: calc(100% - 50px);
        margin-left: 15px;
        margin-right: 15px;
        margin-bottom: 10px;
    }

    #address-button {
        margin-left: 15px;
        width: 100px;
    }
    
</style>