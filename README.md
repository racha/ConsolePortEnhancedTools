# ConsolePort Enhanced Tools

ConsolePort Enhanced Tools adds controller-friendly rings for common World of
Warcraft 3.3.5a actions.

## Requirements

- World of Warcraft 3.3.5a
- [ConsolePortLK](https://github.com/leoaviana/ConsolePortLK)

## Feed Pet Assistant

Feed Pet Assistant helps hunters quickly find and feed usable pet food from
their bags.

- Scans the player's bags for known pet food.
- Shows only food your current pet can eat.
- Rates food by pet level so you can avoid weak food.
- Opens a controller-friendly food ring.
- Feeds the selected food out of combat.

## Aspect Assistant

Aspect Assistant shows trained hunter aspects in a controller-friendly ring.

- Shows only aspects available in your spellbook.
- Casts the selected aspect when released.
- Marks your active aspect in green.
- Marks an aspect buff provided by another hunter in red.
- Shows who provided the external aspect buff when known.

## Other Rings

- `Trap Ring`: trained hunter traps.
- `Track Ring`: trained tracking spells.
- `Quest Item Ring`: usable quest items from your bags.
- `Consumables Ring`: best food, best drink, and usable consumables.
- `Profession Assistant`: known profession tools.
- `Party Assistant`: party member target selection.
- `Ammo Assistant`: equipped ammo and bag ammo switching.

## Setup

1. Install ConsolePortLK.
2. Copy `ConsolePortEnhancedTools` into `Interface/AddOns`.
3. Enable `ConsolePort Enhanced Tools` on the character select addon screen.
4. Bind the tools you want from the `ConsolePort Enhancement` section.

## Usage

Hold an assistant binding to open its ring. Move with the normal movement keys
or controller stick to select an item, spell, or target. Release the binding to
use the selected ring item.

You can also use:

- `/cpet feed`
- `/cpet aspect`
- `/cpet trap`
- `/cpet track`
- `/cpet quest`
- `/cpet consumables`
- `/cpet profession`
- `/cpet party`
- `/cpet ammo`
- `/cpe feed`
- `/cpe aspect`

## Food Ratings

- `Best`: food is within 15 levels of the pet and should give the best happiness gain.
- `Good`: food is 16-25 levels below the pet.
- `Weak`: food is 26-35 levels below the pet.
- `Too low`: food is more than 35 levels below the pet and is not recommended.

## Versioning

Releases use date-based versioning in `YYYY.MM.DD` format.
