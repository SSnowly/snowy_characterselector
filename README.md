# Snowy Multicharacter

A character selection and creation script for FiveM servers, version 2.0.

## Description

Snowy Multicharacter provides a clean and functional interface for players to select their existing characters or create new ones. It includes features like configurable camera views, animations for selected characters, and support for multiple framework operations.

## Features

- Character selection with preview animations.
- Character creation with gender-specific ped models.
- Support for multiple character slots.
- Configurable interior and camera coordinates.
- Integration with ox_lib for UI and utilities.
- Integration with ox_inventory for starter items.

## Dependencies

The following resources are required for this script to function correctly:

- ox_lib
- oxmysql
- qbx_core (or make your own framework adapters)
- ox_inventory (optional, for starter items and initialization of inventory)
- qbx_spawn (optional, supported as a "spawn" engine)

## Installation

1. Ensure all dependencies are installed and started before this resource.
2. Download the resource and place it in your `resources` directory.
3. Rename the folder to `snowy_characterselector` if it isn't already.
4. Add `ensure snowy_characterselector` to your `server.cfg`.
5. Configure the script in `config.lua` to match your server's needs.

## Configuration

The `config.lua` file allows you to customize:

- Camera positions and rotations for both the selector and creator.
- Interior locations.
- Character animations and coordinates.
- Ped models for character creation.

## License

This project is licensed under the GNU General Public License v3 (GPL-3.0). See the `LICENSE` file for the full license text.
