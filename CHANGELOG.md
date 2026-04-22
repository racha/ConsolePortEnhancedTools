# Changelog

## 2026.04.22

- Added shared `RingHelper` for controller ring modules.
- Added `Feed Pet Assistant` hunter module.
- Added `Aspect Assistant` hunter module for trained aspects.
- Added `Trap Ring` hunter module for trained traps.
- Added `Track Ring` module for trained tracking spells.
- Added `Quest Item Ring` for usable quest items in bags.
- Added `Consumables Ring` with best food, best drink, and usable consumables.
- Added `Profession Assistant` for known profession tools.
- Added `Party Assistant` for party member target selection.
- Added `Ammo Assistant` for equipped ammo display and bag ammo switching.
- Added ConsolePort binding and icon support for all assistant rings.
- Added bag scanning for known pet food.
- Added pet diet filtering using `GetPetFoodTypes()`.
- Added pet food quality rating based on pet level and food item level.
- Added active aspect state: self buffs use green, external aspect buffs use red.
- Aspect Assistant shows the external buff provider when the caster is known.
- Feed Pet Assistant and Aspect Assistant now open with no selected ring item until moved.
- Direction key release now resets selection to the idle middle state when no direction is held.
- Ring item borders are smaller, with stronger colored state indicators and lighter hover markers.
- Reworked ring visuals to use lower glow, thinner borders, and minimal hover markers.
- Reworked ring item visuals to use round masked icons, gray empty slots, solid color borders, and low-opacity hover glow.
- Added custom round socket, icon clip, thin rim, and connector textures for assistant rings.
- Fixed Feed Pet Assistant feeding through secure macro buttons to avoid blocked-action errors.
- Fixed Consumables Ring and Quest Item Ring to use secure item actions instead of bag-slot macros.
- Replaced the eight-slot glow background so empty food slots are not shown as fake buttons.
- Reworked Feed Pet Assistant to hold-open, directional-select, and feed-on-release.
- Migrated existing ConsolePort Feed Pet Assistant bindings back to a secure direct click.
- Release feeding now secure-clicks the selected food button instead of running its own macro.
- Direction keys now pass explicit ring directions for selection.
- Direction selectors now use secure click buttons.
- The fallback keyboard binding no longer clicks the secure feed button.
- Empty ring slots can now be selected and close the assistant without feeding.
- Added a Feed Pet Assistant icon for ConsolePortBar bound actions.
- Added raw meat and seafood cooking ingredients to the pet food database.
- Moved the Feed Pet Assistant binding under `ConsolePort Enhancement`.
