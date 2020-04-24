# HIDE Plugins
This directory is a host for HIDE plugins, that provide utilization of specific library features. This readme is to explain specific features of each plugin, because I'm not doing it newbie-friendly.

# Atlasser
Designed specifically to map-out hand-made texture atlases. Produces .atl files which are simple JSON files.
* Plugin state: Minimal Viable Product

### Controls
| Hotkey | Description
| --- | ---
| <kbd>Shift</kbd> + Select area | Create rectangle
| Right click on sprites | Show list of all sprites under cursor (for when they overlap)
| <kbd>Ctrl</kbd> + Drag sprite | Clone the sprite and put to same animation group.
| <kbd>Delete</kbd> | Delete selected sprite
| <kbd>Shift</kbd> when dragging | Restrict movement. Depending on angle locks to horizontal, vertical or diagonals.
| <kbd>Ctrl+Z</kbd> / <kbd>Ctrl+Y</kbd> | Undo/redo is supported
| Drag unmapped area | Move viewport
| Mouse wheel | Zoom