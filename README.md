# ConsolePort Enhanced Tools

ConsolePort Enhanced Tools is a standalone companion addon for ConsolePortLK.
It requires `ConsolePort` and does not modify ConsolePortLK files.

## Current Module

### Feed Pet Assistant

Feed Pet Assistant helps hunters feed their pets from a controller-friendly ring.

- Adds a `Pet Management` section to ConsolePort's custom binding list.
- Adds a `Feed Pet Assistant` binding.
- Scans the player's bags for known pet food.
- Filters food by the active pet's diet from `GetPetFoodTypes()`.
- Rates food by pet level versus food item level.
- Opens a ring with the best available compatible foods.
- Feeds the selected food out of combat.

Press the assigned Feed Pet Assistant binding once to open the ring. Move with
the normal movement keys/stick to select a food, then press the same binding
again, `Space`, `Enter`, or click the food button to feed it.

## Food Ratings

- `Best`: food is within 15 levels of the pet and should give the best happiness gain.
- `Good`: food is 16-25 levels below the pet.
- `Weak`: food is 26-35 levels below the pet.
- `Too low`: food is more than 35 levels below the pet and is not recommended.

## Commands

- `/cpet feed`
- `/cpe feed`

## Project Rules

- Do not edit ConsolePortLK source files.
- Keep all code and assets under `ConsolePortEnhancedTools/`.
- Runtime integration with ConsolePortLK is allowed when it is done from this addon.
- Maintain this README and `CHANGELOG.md` as the addon grows.
