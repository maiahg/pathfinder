import { addUnsafeAreasLayer, UpdateRouteLayer } from "./utils";
import { PATH } from "./config";

export async function getDirections(
    map: mapboxgl.Map,
    origin: [number, number],
    destinations: [number, number][],
    profile: string,
  ) {
    try {
      const res = await fetch(`${PATH}/get-direction`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          origin,
          destinations,
          profile,
        }),
      });
  
      if (!res.ok) throw new Error("Failed to fetch route");
  
      const data = await res.json();
      const geojson = data.geometry;
      const details = data.details;
      const summary = data.summary;
  
      // Add or update route layer
      UpdateRouteLayer(origin, destinations, map, geojson, profile, false);
  
      // Notify listeners about the updated route
      try {
        const event = new CustomEvent("route:update", {
          detail: { details, summary },
        });
        window.dispatchEvent(event);
      } catch (e) {}
  
      // return the details and summary
      return { details, summary };
    } catch (err) {
      console.error("Error fetching route:", err);
    }
  }
  
  export async function getSafeDirections(
  map: mapboxgl.Map,
  origin: [number, number],
  destinations: [number, number][],
  profile: string,
) {
  try {
    console.log("getSafeDirections", origin, destinations, profile);
    const res = await fetch(`${PATH}/get-safe-direction`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        origin,
        destinations,
        profile,
      }),
    });

    if (!res.ok) {
      const errorData = await res.json().catch(() => ({}));
      const errorMessage = errorData.detail || "Failed to fetch safe route";
      
      // Notify listeners about the error
      try {
        const event = new CustomEvent("route:error", {
          detail: { error: errorMessage },
        });
        window.dispatchEvent(event);
      } catch (e) {}
      
      return { error: errorMessage };
    }

    const data = await res.json();
    const geojson = data.geometry;
    const details = data.details;
    const summary = data.summary;

    UpdateRouteLayer(origin, destinations, map, geojson, profile, true);

    // Notify listeners about the updated route
    try {
      const event = new CustomEvent("route:update", {
        detail: { details, summary },
      });
      window.dispatchEvent(event);
    } catch (e) {}

    return { details, summary };
  } catch (err) {
    console.error("Error fetching route:", err);
    const errorMessage = "Network error occurred while fetching route";
    
    // Notify listeners about the error
    try {
      const event = new CustomEvent("route:error", {
        detail: { error: errorMessage },
      });
      window.dispatchEvent(event);
    } catch (e) {}
    
    return { error: errorMessage };
  }
}

  export async function getUnsafeAreas(map: mapboxgl.Map) {
    try {
      const res = await fetch(`${PATH}/get-unsafe-areas`);
      const data = await res.json();
      addUnsafeAreasLayer(map, data);
      return data;
    } catch (err) {
      console.error("Error fetching unsafe areas:", err);
    }
  }