import './App.css'
import MapContainer from './components/MapContainer'
import { MAPBOX_ACCESS_TOKEN, GOOGLE_MAPS_API_KEY } from './libs/config'

function App() {
  return <MapContainer mapboxAccessToken={MAPBOX_ACCESS_TOKEN} googleMapsApiKey={GOOGLE_MAPS_API_KEY} />
}

export default App
