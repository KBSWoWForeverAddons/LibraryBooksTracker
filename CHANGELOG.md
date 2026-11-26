# Changelog

## [v1.0.1] - 2026-11-26

### Changed
- **Recommended Next** tab now includes missing **Level 60 Books** (tagged `[Lv60]`) alongside standard books so all missing books appear in one unified list.

### Fixed
- Fixed World Map pin positions shifting away from their true coordinates when zoomed out (`pin:SetScale(1 / scale)` replaced with size scaling).

## [v1.0.0] - 2026-11-23

### Added
- Initial release of **Library Books Tracker** for WoW Forever (`16001`).
- Live tracking for **Turned In**, **In Bags / In Bank**, and **Missing** Library Books.
- Tier reward progress tracking for **Tier 1 (10)**, **Tier 2 (20)**, and **Tier 3 (25)** turn-ins, plus the **8 Level 60 Books**.
- Level-aware route ordering (`Safe`, `Manageable`, `Risky`, `Dangerous`, `Enemy Capital`) to prioritize missing books by character level.
- World Map and Minimap pins for Library Books, Turn-in NPCs, and the **Cozy Sleeping Bag** quest chain, with clickable zone navigation.
- Draggable minimap button with summary tooltip and `/lbt`, `/books`, `/lb` slash commands.
