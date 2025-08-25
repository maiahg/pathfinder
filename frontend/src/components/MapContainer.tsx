import { useRef, useEffect, useState } from 'react'
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'
import SearchBar from './SearchBar'
import { LoadScript } from '@react-google-maps/api'
import { getDirections, getSafeDirections, getUnsafeAreas } from '../libs/services'

const DEFAULT_CENTER: [number, number] = [-79.3832, 43.6532]
const INITIAL_ZOOM = 12.5

interface MapContainerProps {
  mapboxAccessToken: string,
  googleMapsApiKey: string
}

function MapContainer({ mapboxAccessToken, googleMapsApiKey }: MapContainerProps) {
  const mapRef = useRef<mapboxgl.Map | null>(null)
  const mapContainerRef = useRef<HTMLDivElement | null>(null)

  const [center, setCenter] = useState<[number, number]>(DEFAULT_CENTER)

  const setUpMap = (center: [number, number]) => {
    mapRef.current = new mapboxgl.Map({
      container: mapContainerRef.current!,
      center: center,
      zoom: INITIAL_ZOOM
    })

    mapRef.current?.addControl(new mapboxgl.NavigationControl(), 'bottom-right')

    mapRef.current?.addControl(new mapboxgl.GeolocateControl({
      positionOptions: {
          enableHighAccuracy: true
      },
      trackUserLocation: true,
      showUserHeading: true
  }), 'bottom-right');

    getUnsafeAreas(mapRef.current)

    return mapRef.current
  }

  const handleSearch = async (origin: [number, number], destinations: [number, number][], profile: string, safeMode: boolean) => {
    if (mapRef.current) {
      const result = safeMode ? await getSafeDirections(mapRef.current, origin, destinations, profile) : await getDirections(mapRef.current, origin, destinations, profile)
      if (result) {
        // Ensure we always return the expected structure
        if ('error' in result) {
          return {
            details: [],
            summary: { path_summary: "", duration: 0, distance: 0 },
            error: result.error
          }
        }
        return {
          details: result.details || [],
          summary: result.summary || { path_summary: "", duration: 0, distance: 0 }
        }
      }
    }
    return {
      details: [],
      summary: { path_summary: "", duration: 0, distance: 0 }
    }
  }

  useEffect(() => {
    const initMap = () => {
      if (!mapContainerRef.current) {
        requestAnimationFrame(initMap);
        return;
      }
  
      if (mapRef.current) return;
  
      mapboxgl.accessToken = mapboxAccessToken;
  
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const { longitude, latitude } = position.coords;
            const newCenter: [number, number] = [longitude, latitude];
            setCenter(newCenter);
  
            mapRef.current = setUpMap(newCenter);
          },
          (error) => {
            console.error("Error getting location:", error);
            mapRef.current = setUpMap(DEFAULT_CENTER);
          }
        );
      } else {
        mapRef.current = setUpMap(DEFAULT_CENTER);
      }
    };
  
    initMap();
  
    return () => {
      mapRef.current?.remove();
    };
  }, []);

  return (
    <>
      <LoadScript googleMapsApiKey={googleMapsApiKey} libraries={["places"]}> 
        <div id="map-container" ref={mapContainerRef} />
        <div className='search-bar'>
          <SearchBar userLocation={center ? { lng: center[0], lat: center[1] } : null} onSearch={handleSearch} />
        </div>
      </LoadScript>
    </>
  )
}

export default MapContainer