# ConsolePort Enhanced Tools

ConsolePort Enhanced Tools adds extra controller-friendly tools for hunters
playing World of Warcraft 3.3.5a with ConsolePortLK.

## Requirements

- World of Warcraft 3.3.5a
- ConsolePortLK

## Feed Pet Assistant

Feed Pet Assistant helps hunters quickly find and feed usable pet food from
their bags.

- Scans the player's bags for known pet food.
- Shows only food your current pet can eat.
- Rates food by pet level so you can avoid weak food.
- Opens a controller-friendly food ring.
- Feeds the selected food out of combat.

## Setup

1. Install ConsolePortLK.
2. Copy `ConsolePortEnhancedTools` into `Interface/AddOns`.
3. Enable `ConsolePort Enhanced Tools` on the character select addon screen.
4. Bind `Feed Pet Assistant` from the `Pet Management` section.

## Usage

Press the Feed Pet Assistant binding to open the food ring. Move with the normal
movement keys or controller stick to select food, then press the same binding
again to feed it.

You can also use:

- `/cpet feed`
- `/cpe feed`

## Food Ratings

- `Best`: food is within 15 levels of the pet and should give the best happiness gain.
- `Good`: food is 16-25 levels below the pet.
- `Weak`: food is 26-35 levels below the pet.
- `Too low`: food is more than 35 levels below the pet and is not recommended.

## Versioning

Releases use date-based versioning in `YYYY.MM.DD` format.
