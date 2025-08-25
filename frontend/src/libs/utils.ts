import { bbox } from "@turf/turf";
import mapboxgl from "mapbox-gl";
import { getDirections, getSafeDirections } from "./services";

export function formatDuration(duration: number) {
  let hr = 0;
  let min = 0;
  if (duration > 3600) {
    hr = Math.floor(duration / 3600);
    min = Number(((duration % 3600) / 60).toFixed(0));
  } else {
    min = Number((duration / 60).toFixed(0));
  }

  if (hr > 0) {
    return `${hr} hr ${min} min`;
  } else {
    return `${min} min`;
  }
}

export function formatDistance(distance: number, safeMode: boolean) {
  if (safeMode) {
    if (distance < 1) {
      distance = distance * 1000;
      return `${Number(distance.toFixed(0))} m`;
    }

    return `${Number(distance.toFixed(2))} km`;
  }

  if (distance > 1000) {
    return `${Number((distance / 1000).toFixed(2))} km`;
  } else {
    return `${Number(distance.toFixed(0))} m`;
  }
}

export function UpdateRouteLayer(origin: [number, number],
  destinations: [number, number][], map: mapboxgl.Map, geojson: GeoJSON.FeatureCollection, profile: string, safeMode: boolean) {
  if (map.getSource("route")) {
    (map.getSource("route") as mapboxgl.GeoJSONSource).setData(geojson);

    if (profile === "walking") {
      map.setPaintProperty("route", "line-dasharray", [1, 2]);
    } else {
      map.setPaintProperty("route", "line-dasharray", undefined);
    }
  } else {
    if (profile == "walking") {
      map.addLayer({
        id: "route",
        type: "line",
        source: { type: "geojson", data: geojson },
        layout: { "line-join": "round", "line-cap": "round" },
        paint: {
          "line-color": "#3887be",
          "line-width": 5,
          "line-opacity": 0.75,
          "line-dasharray": [1, 2],
        },
      });
    } else {
      map.addLayer({
        id: "route",
        type: "line",
        source: { type: "geojson", data: geojson },
        layout: { "line-join": "round", "line-cap": "round" },
        paint: {
          "line-color": "#3887be",
          "line-width": 5,
          "line-opacity": 0.75,
        },
      });
    }
  }

  // Remove existing markers if any
  const existingMarkers = document.querySelectorAll(".mapboxgl-marker");
  existingMarkers.forEach((m) => m.remove());

  // Add origin marker
  const originMarker = new mapboxgl.Marker({
    color: "#4ce05b",
    draggable: true,
  })
    .setLngLat(origin)
    .addTo(map);

  originMarker.on("dragend", () => {
    const lngLat = originMarker.getLngLat();
    safeMode ? getSafeDirections(map, [lngLat.lng, lngLat.lat], destinations, profile) : getDirections(map, [lngLat.lng, lngLat.lat], destinations, profile);
  });

  // Add destination markers
  destinations.forEach((coords, i) => {
    const destinationMarker = new mapboxgl.Marker({
      color: "#f30",
      draggable: true,
    })
      .setLngLat(coords)
      .addTo(map);

    destinationMarker.on("dragend", () => {
      const newCoords = destinationMarker.getLngLat();
      const newDestinations = [...destinations];
      newDestinations[i] = [newCoords.lng, newCoords.lat];
      safeMode ? getSafeDirections(map, origin, newDestinations, profile) : getDirections(map, origin, newDestinations, profile);
    });
  });

  // Fit map to route
  const bounds = bbox(geojson);
  map.fitBounds(bounds as [number, number, number, number], {
    padding: 60,
    duration: 1000,
  });
}

export function addUnsafeAreasLayer(map: mapboxgl.Map, unsafeAreas: GeoJSON.FeatureCollection) {
  if (map.getSource("unsafe-areas")) {
    (map.getSource("unsafe-areas") as mapboxgl.GeoJSONSource).setData(unsafeAreas);
  } else {
    map.addSource("unsafe-areas", {
      type: "geojson",
      data: unsafeAreas,
    });

    map.addLayer({
      id: "unsafe-fill",
      type: "fill",
      source: "unsafe-areas",
      layout: {},
      paint: {
        "fill-color": "#ff0000",
        "fill-opacity": 0.25,
      },
    });
  }
}