import Typography from "@mui/joy/Typography";
import Box from "@mui/joy/Box";
import { formatDistance, formatDuration } from "../libs/utils";
import List from "@mui/joy/List";
import ListItem from "@mui/joy/ListItem";
import ListItemDecorator from "@mui/joy/ListItemDecorator";
import DriveEtaOutlinedIcon from "@mui/icons-material/DriveEtaOutlined";
import DirectionsWalkIcon from "@mui/icons-material/DirectionsWalk";
import DirectionsBikeIcon from "@mui/icons-material/DirectionsBike";
import Button from "@mui/joy/Button";

export default function RouteSummary({
  summary,
  travelMode,
  showDetails,
  setShowDetails,
  safeMode,
}: {
  summary: {
    duration: number;
    distance: number;
    path_summary: string;
  };
  travelMode: string;
  showDetails: boolean;
  setShowDetails: (showDetails: boolean) => void;
  safeMode: boolean;
}) {
  return (
    <Box
      sx={{
        maxWidth: "100%",
        width: "400px",
        mt: 2,
      }}
    >
      <Box
        sx={{
          px: 2.5,
          py: 1,
          borderBottom: "1px solid",
          borderColor: "divider",
          bgcolor: "background.level1",
          borderTopLeftRadius: "md",
          borderTopRightRadius: "md",
        }}
      >
        <Typography level="title-md" fontWeight="lg" sx={{ ml: 1 }}>
          Route Summary
        </Typography>
      </Box>

      <List sx={{ p: 0 }}>
        <ListItem
          sx={{
            alignItems: "flex-start",
            pl: 2.5,
            py: 1.5,
            flexDirection: "column",
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center", width: "100%" }}>
            <ListItemDecorator sx={{ mr: 0.5, mt: 0.5 }}>
              {travelMode === "driving" && <DriveEtaOutlinedIcon />}
              {travelMode === "walking" && <DirectionsWalkIcon />}
              {travelMode === "cycling" && <DirectionsBikeIcon />}
            </ListItemDecorator>
            <Box>
              <Typography fontSize="md" fontWeight="md">
                via {summary.path_summary}
              </Typography>
              <Typography fontSize="sm" fontWeight="sm">
                {formatDuration(summary.duration)},{" "}
                {formatDistance(summary.distance, safeMode)}
              </Typography>
            </Box>
          </Box>
          <Button
            variant="plain"
            color="primary"
            sx={{ cursor: "pointer", ml: 3.5 }}
            onClick={() => setShowDetails(!showDetails)}
          >
            <Typography
              fontSize="sm"
              fontWeight="md"
              color="primary"
              sx={{ cursor: "pointer", textDecoration: "underline" }}
            >
              Details
            </Typography>
          </Button>
        </ListItem>
      </List>
    </Box>
  );
}
