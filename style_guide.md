# Style Guide

## File Structure

- All UI structure data (css, images, markup) should go to the `interface` folder

- `scripts` are divided into

  - `ui_controllers` responsible for setting up the UI, and handling UI events (one for each "View" or game state)
  - `game_controllers` responsible for game logic  (one for each "View" or game state)
  - `graphics` helpers for drawing non-standard components  (one for each "View" or game state)
  - `utils` miscellaneous helpers

## Naming

libRocket and the Freespace API have conflicting (and sometimes self-contradictory) naming conventions, so there's no way to keep all of the code within the mod consistent. But for the sake of sanity of anyone wondering which convention they should use, the code of the mod itself should follow these guidilines:

- Use `snake_case` for local variables (including local functions) and function parameters, and file names
- Use `camelCase` for functions and methods
- Use `PascalCase` for modules, class names, member variables, and global variables
- Use `UPPER_SNAKE_CASE` for constants and enums