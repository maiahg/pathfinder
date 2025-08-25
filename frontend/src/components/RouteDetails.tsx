import Typography from "@mui/joy/Typography";
import List from "@mui/joy/List";
import Divider from "@mui/joy/Divider";
import ListItem from "@mui/joy/ListItem";
import ListItemDecorator from "@mui/joy/ListItemDecorator";
import Box from "@mui/joy/Box";
import LocationPinIcon from "@mui/icons-material/LocationPin";
import CircleIcon from "@mui/icons-material/Circle";    
import KeyboardBackspaceIcon from "@mui/icons-material/KeyboardBackspace";
import { formatDistance } from "../libs/utils";
import Tooltip from "@mui/joy/Tooltip";
import Button from "@mui/joy/Button";
import Avatar from "@mui/joy/Avatar";

export default function RouteDetails({
  details,
  setShowDetails,
  safeMode,
}: {
  details: {
    instruction: string;
    duration: number;
    distance: number;
  }[];
  setShowDetails: (showDetails: boolean) => void;
  safeMode: boolean;
}) {
  return (
    <>
      <Box
        sx={{
          maxWidth: "100%",
          width: "400px",
          mt: 2,
        }}
      >
        <Box
          sx={{
            px: 1.5,
            py: 1,
            borderBottom: "1px solid",
            borderColor: "divider",
            bgcolor: "background.level1",
            borderTopLeftRadius: "md",
            borderTopRightRadius: "md",
          }}
        >
          <Box sx={{ display: "flex", alignItems: "center" }}>
            <Tooltip title="Back to summary" variant="soft" placement="bottom-end">
              <Avatar size="sm" variant="plain">
                <Button
                  variant="soft"
                  color="neutral"
                  sx={{ cursor: "pointer" }}
                >
                  <KeyboardBackspaceIcon
                    sx={{ cursor: "pointer" }}
                    onClick={() => setShowDetails(false)}
                  />
                </Button>
              </Avatar>
            </Tooltip>
            <Typography level="title-md" fontWeight="lg" sx={{ ml: 3.5 }}>
              Route Details
            </Typography>
          </Box>
        </Box>
        <Box sx={{ maxHeight: 400, overflowY: "auto" }}>
          <List sx={{ p: 0 }}>
            {details.map((step, index) => (
              <Box key={index}>
                <ListItem sx={{ alignItems: "center", pl: 2.5, py: 1.5 }}>
                  <ListItemDecorator sx={{ mr: 0.5 }}>
                    {index === details.length - 1 ? <LocationPinIcon sx={{ color: "red" }}/> : <CircleIcon sx={{ color: "gray", fontSize: 10 }} />}
                  </ListItemDecorator>
                  <Box sx={{ flexGrow: 1 }}>
                    <Typography fontSize="md" fontWeight="md">
                      {step.instruction}
                    </Typography>
                    {index !== details.length - 1 && (
                      <Typography fontSize="sm" fontWeight="sm">
                        {formatDistance(step.distance, safeMode)}
                      </Typography>
                    )}
                  </Box>
                </ListItem>
                {index !== details.length - 1 && (
                  <Divider inset="none" sx={{ m: 0 }} />
                )}
              </Box>
            ))}
          </List>
        </Box>
      </Box>
    </>
  );
}
