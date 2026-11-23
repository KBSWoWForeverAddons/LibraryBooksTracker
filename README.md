# Library Books Tracker

A standalone **WoW Forever (`16001`)** addon that tracks your **Library Books** progression in-game—showing what you've turned in, what's sitting in your bags or bank, and which books to grab next based on your current character level.

## Features

- **Minimap Button & Tracker Window**
  - Draggable minimap button with an at-a-glance tooltip (turned-in count, bag/bank count, Tier 1/2/3 status, and top 3 easiest missing books).
  - Left-click the minimap button (or use `/lbt`, `/books`, `/lb`) to open the tracker frame.
- **Active Book State Tracking**
  - **Turned In:** Checked live via `C_QuestLog.IsQuestFlaggedCompleted`.
  - **In Bags / In Bank:** Scans your bags live and caches banked books when you open your bank.
  - **Missing:** Everything you still need to acquire.
- **Tier Reward Progress (10 / 20 / 25 Books)**
  - Tracks progress toward **Tier 1 (10)**, **Tier 2 (20)**, and **Tier 3 (25)** turn-in milestones at **Garion Wendell** (Alliance) / **Owen Thadd** (Horde), plus the **8 Level 60 Books** at **Jennea Cannon** / **Oran Snakewrithe**.
  - Tags missing books in the **Recommended Next** tab with `[Tier 1]`, `[Tier 2]`, or `[Tier 3]` so you know exactly which books reach each reward.
- **Level-Aware Route Ordering**
  - Ranks missing books from **least dangerous to hardest** (`Safe`, `Manageable`, `Risky`, `Dangerous`, `Enemy Capital`) relative to your character's current level.
  - Excludes removed SoD-only books (*The Liminal and the Arcane* and *A Luddite's Guide*) and faction-locked books unavailable to your faction (*Ataeric* for Alliance).
- **World Map & Minimap Pins**
  - Displays pins for Library Books, Turn-in NPCs, and the **Cozy Sleeping Bag** quest chain.
  - Clicking any row or `Map` button in the tracker opens the World Map directly to that zone.
  - Toggleable options for Map Pins, Sleeping Bag Pins, Completed Pins, and hiding turned-in books in the list.

## Slash Commands

- `/lbt`, `/books`, `/lb` — Toggle the Library Books Tracker window.
- `/lbt reset` — Reset the minimap button position.

## Installation

1. Download or clone into `World of Warcraft\_forever_\Interface\AddOns\Library Books Tracker`.
2. Disable the original `Library Books` addon if installed to avoid duplicate map pins.
3. Log in or `/reload`.
