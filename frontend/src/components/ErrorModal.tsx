import Typography from "@mui/joy/Typography";
import Box from "@mui/joy/Box";
import List from "@mui/joy/List";
import ListItem from "@mui/joy/ListItem";
import ListItemDecorator from "@mui/joy/ListItemDecorator";
import WarningIcon from '@mui/icons-material/Warning';

export default function ErrorModal({
  safeMode,
}: {
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
          Route Unavailable
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
            <ListItemDecorator sx={{ mr: 0.5, mt: 0.5, ml: 1 }}>
              <Typography color="danger" fontSize="lg">
                <WarningIcon color="error" />
              </Typography>
            </ListItemDecorator>
            <Box sx={{ ml: 1 }}>
              {safeMode ? (
                <Typography fontSize="sm" fontWeight="md">
                  No safe route found
                  <br />
                  Please try again without safe mode.
                </Typography>
              ) : (
                <Typography fontSize="md" fontWeight="md">
                  No route found, please try again later.
                </Typography>
              )}
            </Box>
          </Box>
        </ListItem>
      </List>
    </Box>
  );
}
