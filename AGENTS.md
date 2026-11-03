# Repository Guidelines

## Project structure and module organization

The active game lives in `godot/`. Open `godot/project.godot` with Godot 4.7.2 Standard. Scenes are in `godot/scenes/`, GDScript in `godot/scripts/`, and game artwork in `godot/assets/`.

`game.gd` handles input, UI, navigation, and API calls; `world.gd` draws the environment; `player.gd` renders and animates characters. `spiel/server.py` serves static files and stores shared state in SQLite. Browser tests live in `spiel/test-*.mjs`. The earlier HTML prototype remains in `spiel/dist/`. Portable Godot tools are under `tools/godot/`.

## Build, test, and development commands

- From the repository root, run `powershell -File .\godot\build-web.ps1` to import assets and export the browser build into `godot/build/`.
- From `spiel/`, run `docker compose up -d --build` to serve the exported game at `http://localhost:8085`. Re-export after Godot changes before rebuilding Docker.
- In the Godot editor, press F5 to run the project. Native previews require the save server at port 8085.
- From `spiel/`, run `npm install` and `npx playwright install chromium` to prepare browser tests, then `node test-godot.mjs` against the running game.
- Run `docker compose stop` from `spiel/` to stop the service.

## Coding style and naming conventions

Follow surrounding code. GDScript uses tabs, typed declarations where practical, and snake_case functions and variables. Python uses four spaces and snake_case. Browser tests use ES modules and filenames such as `test-controls.mjs`. No formatter or lint command is configured. Preserve supplied character artwork and keep rendering changes in the relevant scripts.

## Testing guidelines

Use Playwright with Node's strict assertions. The active Godot suite checks character selection, movement, navigation, room transitions, furniture editing, save/load, and browser errors. It mocks `/api/state` to protect real saves and writes screenshots to `spiel/output/godot-qa/`. Extend it for changed behavior and inspect relevant screenshots. No coverage threshold is configured.

## Commit and pull request guidelines

This checkout has no Git metadata, so existing commit conventions cannot be verified. Use concise imperative subjects, for example `Fix workshop navigation`. Describe behavior changes, validation commands, and related issues in pull requests. Include screenshots for visual changes.

## Shared state and generated files

All visitors share one save without authentication. Back up the `spiel_game-data` Docker volume before persistence changes; `docker compose down -v` deletes it. Keep generated builds, local databases, test output, dependencies, and Godot caches out of commits as specified by `.gitignore`.
