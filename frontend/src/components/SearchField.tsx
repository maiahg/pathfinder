import { StandaloneSearchBox } from "@react-google-maps/api";
import { useRef } from "react";
import { Input } from "@mui/joy";

interface SearchFieldProps {
  id: number;
  input: { placeholder: string; value?: any };
  setAddress: (address: {
    id: number;
    address: string;
    coords: { lat: number; lng: number };
    place_id: string;
  }) => void;
  userLocation: { lat: number; lng: number } | null;
  setInputs: React.Dispatch<React.SetStateAction<any>>;
}

const SearchField = ({
  id,
  input,
  setAddress,
  userLocation,
  setInputs,
}: SearchFieldProps) => {
  const searchInput = useRef<any>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const handlePlacesChanged = () => {
    try {
      const place = searchInput.current.getPlaces()[0];

      if (place) {
        const payload = {
          id,
          address: place.name + ", " + place.formatted_address,
          coords: {
            lat: place.geometry.location.lat(),
            lng: place.geometry.location.lng(),
          },
          place_id: place.place_id,
        };

        setAddress(payload);
      }
    } catch (error) {
      console.log(error);
    }
  };

  const handleLoad = (ref: any) => {
    searchInput.current = ref;
    if (userLocation && window.google && ref) {
      const bounds = new window.google.maps.LatLngBounds(
        new window.google.maps.LatLng(
          userLocation.lat - 0.5,
          userLocation.lng - 0.5
        ),
        new window.google.maps.LatLng(
          userLocation.lat + 0.5,
          userLocation.lng + 0.5
        )
      );
      ref.setBounds(bounds);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newText = e.target.value;
    setInputs((prev: any[]) =>
      prev.map((inp) =>
        inp.id === id
          ? {
              ...inp,
              value: inp.value
                ? { ...inp.value, address: newText }
                : {
                    address: newText,
                    coords: { lat: 0, lng: 0 },
                    place_id: "",
                  },
            }
          : inp
      )
    );
  };

  return (
    <StandaloneSearchBox
      onLoad={handleLoad}
      onPlacesChanged={handlePlacesChanged}
    >
      <div>
        <Input
          sx={{ flex: 1, width: "300px", fontSize: "sm" }}
          placeholder={input.placeholder}
          value={input.value?.address || ""}
          onChange={handleChange}
          slotProps={{
            input: { ref: inputRef },
          }}
        />
      </div>
    </StandaloneSearchBox>
  );
};

export default SearchField;
