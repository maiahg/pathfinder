import { useState, useEffect } from "react";
import { Stepper, Step, StepLabel, Paper, Tooltip, Box } from "@mui/material";
import { Typography, Stack, Avatar, Button } from "@mui/joy";
import SearchIcon from "@mui/icons-material/Search";
import DriveEtaOutlinedIcon from "@mui/icons-material/DriveEtaOutlined";
import DirectionsWalkIcon from "@mui/icons-material/DirectionsWalk";
import DirectionsBikeIcon from "@mui/icons-material/DirectionsBike";
import AddLocationAltOutlinedIcon from "@mui/icons-material/AddLocationAltOutlined";
import HighlightOffOutlinedIcon from "@mui/icons-material/HighlightOffOutlined";
import GppMaybeOutlinedIcon from "@mui/icons-material/GppMaybeOutlined";
import { styled } from "@mui/material/styles";
import PlaceOutlinedIcon from "@mui/icons-material/PlaceOutlined";
import RadioButtonUncheckedOutlinedIcon from "@mui/icons-material/RadioButtonUncheckedOutlined";
import SearchField from "./SearchField";
import RouteDetails from "./RouteDetails";
import RouteSummary from "./RouteSummary";
import ErrorModal from "./ErrorModal";

interface SearchBarProps {
  userLocation: { lat: number; lng: number } | null;
  onSearch: (
    origin: [number, number],
    destinations: [number, number][],
    profile: string,
    safeMode: boolean
  ) => Promise<{
    details: {
      instruction: string;
      duration: number;
      distance: number;
    }[];
    summary: {
      path_summary: string;
      duration: number;
      distance: number;
    };
    error?: string;
  }>;
}

interface AddressData {
  id: number;
  address: string;
  coords: {
    lat: number;
    lng: number;
  };
  place_id: string;
}

interface Input {
  id: number;
  placeholder: string;
  value: AddressData | null;
}

function SearchBar({ userLocation, onSearch }: SearchBarProps) {
  const [nextId, setNextId] = useState(3);

  const [address, setAddress] = useState<AddressData | null>(null);
  const [inputs, setInputs] = useState<Input[]>([
    { id: 1, placeholder: "Choose starting point", value: null },
    { id: 2, placeholder: "Choose destination", value: null },
  ]);
  const [travelMode, setTravelMode] = useState<string>("driving");
  const [safeMode, setSafeMode] = useState<boolean>(false);
  const [showDetails, setShowDetails] = useState<boolean>(false);

  const [details, setDetails] = useState<
    {
      instruction: string;
      duration: number;
      distance: number;
    }[]
  >([]);
  const [summary, setSummary] = useState<{
    path_summary: string;
    duration: number;
    distance: number;
  }>({ path_summary: "", duration: 0, distance: 0 });
  
  // Track if we have an active route to avoid unnecessary searches
  const [hasActiveRoute, setHasActiveRoute] = useState<boolean>(false);
  
  // Track error state
  const [error, setError] = useState<string | null>(null);
  const handleAddDestination = () => {
    const newInput = {
      id: nextId,
      placeholder: "Choose destination",
      value: null,
    };
    setInputs((prev) => [...prev, newInput]);
    setNextId((id) => id + 1);
    // Clear route when adding destination
    setHasActiveRoute(false);
    setDetails([]);
    setSummary({ path_summary: "", duration: 0, distance: 0 });
    setError(null);
  };

  const handleDelete = (id: number) => {
    setInputs((prevInputs) => {
      const updated = prevInputs.filter((input) => input.id !== id);

      // If we removed the first input, rename the new first one to "Choose starting point"
      if (updated.length > 0) {
        updated[0] = { ...updated[0], placeholder: "Choose starting point" };

        // Make sure the rest are "Choose destination"
        for (let i = 1; i < updated.length; i++) {
          updated[i] = { ...updated[i], placeholder: "Choose destination" };
        }
      }

      return updated;
    });
    // Clear route when removing destination
    setHasActiveRoute(false);
    setDetails([]);
    setSummary({ path_summary: "", duration: 0, distance: 0 });
    setError(null);
  };

  const handleChangeTravelMode = (mode: string) => {
    setTravelMode(mode);
    handleSearch(mode, safeMode);
  };

  const handleSearch = async (mode?: string, safeModeParam?: boolean) => {
    const origin = inputs[0].value;
    const destinations = inputs
      .slice(1)
      .map((input) => input.value)
      .filter(
        (destination): destination is AddressData => destination !== null
      );

    if (origin && destinations.length > 0) {
      const result = await onSearch(
        [origin.coords.lng, origin.coords.lat],
        destinations.map((destination) => [
          destination.coords.lng,
          destination.coords.lat,
        ]),
        mode || travelMode,
        safeModeParam !== undefined ? safeModeParam : safeMode
      );
      
      if (result.error) {
        setError(result.error);
        setDetails([]);
        setSummary({ path_summary: "", duration: 0, distance: 0 });
      } else {
        setError(null);
        setDetails(result.details);
        setSummary(result.summary);
      }
      setHasActiveRoute(true);
    }
  };

  const QontoStepIconRoot = styled("div")<{
    ownerState?: { active?: boolean };
  }>(() => ({
    display: "flex",
    width: 22,
    alignItems: "center",
    "& .QontoStepIcon-completedIcon": {
      color: "red",
      fontSize: 18,
      transform: "translateX(-25%)",
    },
    "& .QontoStepIcon-circle": {
      color: "gray",
      fontSize: 12,
      transform: "translateX(-10%)",
    },
  }));

  useEffect(() => {
    if (address?.id && address?.address) {
      setInputs((prevInputs) =>
        prevInputs.map((input) =>
          input.id === address.id ? { ...input, value: address } : input
        )
      );
      // Clear route when address changes
      setHasActiveRoute(false);
      setDetails([]);
      setSummary({ path_summary: "", duration: 0, distance: 0 });
      setError(null);
    }
  }, [address]);

  // Update UI when route changes from marker drags (getRoute dispatches route:update)
  useEffect(() => {
    const onRouteUpdate = (e: Event) => {
      const { details, summary } = (e as CustomEvent).detail || {};
      if (details && summary) {
        setDetails(details);
        setSummary(summary);
        setError(null);
        setHasActiveRoute(true);
      }
    };
    
    const onRouteError = (e: Event) => {
      const { error } = (e as CustomEvent).detail || {};
      if (error) {
        setError(error);
        setDetails([]);
        setSummary({ path_summary: "", duration: 0, distance: 0 });
        setHasActiveRoute(true);
      }
    };
    
    window.addEventListener("route:update", onRouteUpdate as EventListener);
    window.addEventListener("route:error", onRouteError as EventListener);
    return () => {
      window.removeEventListener("route:update", onRouteUpdate as EventListener);
      window.removeEventListener("route:error", onRouteError as EventListener);
    };
  }, []);

  function QontoStepIcon(props: {
    active?: boolean;
    completed?: boolean;
    className?: string;
  }) {
    const { active, completed, className } = props;

    return (
      <QontoStepIconRoot ownerState={{ active }} className={className}>
        {!completed ? (
          <PlaceOutlinedIcon className="QontoStepIcon-completedIcon" />
        ) : (
          <RadioButtonUncheckedOutlinedIcon className="QontoStepIcon-circle" />
        )}
      </QontoStepIconRoot>
    );
  }

  return (
    <Paper
      elevation={6}
      sx={{
        width: 400,
        backgroundColor: "white",
        pt: 2,
        pb: 2,
        borderRadius: 5,
        boxShadow: "5px 5px 5px 0 rgba(0, 0, 0, 0.1)",
      }}
    >
      <Box sx={{ pl: 2, pr: 2 }}>
        <Stack
          direction="row"
          alignItems="center"
          justifyContent="center"
          sx={{ mb: 1.5, gap: 2 }}
        >
          <Tooltip title="Driving">
            <Avatar
              size="sm"
              variant="plain"
              onClick={() => {
                handleChangeTravelMode("driving");
              }}
            >
              <Button
                variant={travelMode === "driving" ? "soft" : "plain"}
                color={travelMode === "driving" ? "primary" : "neutral"}
              >
                <DriveEtaOutlinedIcon />
              </Button>
            </Avatar>
          </Tooltip>
          <Tooltip title="Walking">
            <Avatar
              size="sm"
              variant="plain"
              onClick={() => {
                handleChangeTravelMode("walking");
              }}
            >
              <Button
                variant={travelMode === "walking" ? "soft" : "plain"}
                color={travelMode === "walking" ? "primary" : "neutral"}
              >
                <DirectionsWalkIcon />
              </Button>
            </Avatar>
          </Tooltip>
          <Tooltip title="Cycling">
            <Avatar
              size="sm"
              variant="plain"
              onClick={() => {
                handleChangeTravelMode("cycling");
              }}
            >
              <Button
                variant={travelMode === "cycling" ? "soft" : "plain"}
                color={travelMode === "cycling" ? "primary" : "neutral"}
              >
                <DirectionsBikeIcon />
              </Button>
            </Avatar>
          </Tooltip>
          <Tooltip title="Safe Mode">
            <Avatar
              size="sm"
              variant="plain"
              onClick={() => {
                const newSafeMode = !safeMode;
                setSafeMode(newSafeMode);
                // Only trigger search if we have an active route
                if (hasActiveRoute) {
                  handleSearch(undefined, newSafeMode);
                }
              }}
            >
              <Button
                variant={safeMode ? "solid" : "plain"}
                color={safeMode ? "success" : "neutral"}
              >
                <GppMaybeOutlinedIcon />
              </Button>
            </Avatar>
          </Tooltip>
        </Stack>
        <Stepper activeStep={inputs.length - 1} orientation="vertical">
          {inputs.map((input) => (
            <Step key={input.id}>
              <Stack direction="row" alignItems="center" sx={{ ml: 1, mb: -1 }}>
                <StepLabel
                  slots={{ stepIcon: QontoStepIcon }}
                  sx={{ width: 25 }}
                ></StepLabel>
                <SearchField
                  id={input.id}
                  input={input}
                  setAddress={setAddress}
                  userLocation={userLocation}
                  setInputs={setInputs}
                />
                {inputs.length > 2 && (
                  <Tooltip title="Remove this destination">
                    <HighlightOffOutlinedIcon
                      sx={{
                        ml: 1,
                        color: "gray",
                        cursor: "pointer",
                      }}
                      onClick={() => handleDelete(input.id)}
                    />
                  </Tooltip>
                )}
              </Stack>
            </Step>
          ))}
        </Stepper>
        <Stack
          direction="row"
          alignItems="center"
          sx={{ ml: "auto", mt: 1, ":hover": { cursor: "pointer" } }}
          onClick={handleAddDestination}
        >
          <Tooltip title="Add destination">
            <AddLocationAltOutlinedIcon
              onClick={handleAddDestination}
              sx={{ mt: 1.5, cursor: "pointer" }}
            />
          </Tooltip>
          <Typography
            level="body-md"
            sx={{
              ml: 2.5,
              mt: 2,
              color: "gray",
              fontWeight: "semibold",
              fontSize: "sm",
              ":hover": { color: "black" },
            }}
          >
            Add a destination
          </Typography>
        </Stack>
        <Stack
          direction="row"
          alignItems="center"
          sx={{ ml: "auto", mt: 1, ":hover": { cursor: "pointer" } }}
          onClick={() => handleSearch(travelMode, safeMode)}
        >
          <Tooltip title="Search route">
            <SearchIcon sx={{ cursor: "pointer" }} />
          </Tooltip>
          <Typography
            level="body-md"
            sx={{
              ml: 2.5,
              mt: 1,
              mb: 1,
              color: "gray",
              fontWeight: "semibold",
              fontSize: "sm",
              ":hover": { color: "black" },
            }}
          >
            Search
          </Typography>
        </Stack>
      </Box>

      {(summary.path_summary !== "" || details.length > 0) && (
        <Box sx={{ mt: 2 }}>
          {!showDetails && (
            <RouteSummary
              summary={summary}
              travelMode={travelMode}
              safeMode={safeMode}
              showDetails={showDetails}
              setShowDetails={setShowDetails}
            />
          )}
          {showDetails && (
            <RouteDetails
              details={details}
              setShowDetails={setShowDetails}
              safeMode={safeMode}
            />
          )}
        </Box>
      )}
      {error && (
        <ErrorModal safeMode={safeMode} />
      )}
    </Paper>
  );
}

export default SearchBar;
