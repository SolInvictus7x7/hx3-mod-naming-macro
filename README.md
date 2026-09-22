# Sol's Utils: Universal Naming Scheme

A non-invasive automation mod for Helixteus 3 (HX3) that introduces systematic, customizable, and automated renaming for celestial entities across clusters, galaxies, star systems, and planets.

---

## 1. Overview

As an empire expands across the universe in Helixteus 3, hundreds of star systems and thousands of planets are generated with default procedural designations (such as "System 42" or "Planet 0"). Renaming every discovered system and planet manually through the default interface is tedious and time-consuming.

Sol's Utils provides a centralized Universal Naming Scheme interface that automates this process. Players can define structured naming patterns, choose between Arabic and Roman numerals, specify abbreviations, append parent galaxy or star names, and apply selective filtering for conquered and previously customized territories.

---

## 2. Installation

Simply copy the .zip file into your HX3 mod folder. You can open the folder from the 'mods' tab in game.

---

## 3. How the Mod Works

### UI Architecture and Vanilla Module Reuse

The user interface integrates into the game at runtime by utilizing standard Godot lifecycle hooks (`phase_1` and `phase_2`) and native Helixteus 3 UI components:

* **Theme Consistency:** The interface dynamically applies `res://Resources/default_theme.tres`, ensuring all fonts, borders, button states, and styling match the vanilla client.
* **HUD Integration:** The mod observes the scene tree and injects an access button directly into the native `$HUD/Buttons` container using vanilla HUD assets (`res://Graphics/Buttons/HUDButton.png`, `HUDButtonOver.png`, and `Annotate.png`).
* **Panel Management:** The panel inherits native window behaviors:
  * Manages focus exclusivity via `game.active_panel` and smoothly fades out any conflicting vanilla menus using `game.fade_out_panel()`.
  * Integrates with the native background shader (`$Blur/BlurRect`) to blur gameplay elements behind the active window.
  * Blocks galaxy/universe map dragging while hovering over the panel via `game.block_scroll = true`.
  * Embeds the official close button widget (`res://Scenes/CloseButton.tscn`).
* **Toast Feedback:** Macro completion and status alerts are surfaced through the native toast notification system via `game.popup()`.
* **Sidebar Synchronization:** Updates bookmarks immediately via `HUD.refresh_bookmarks()`, reflecting renamed entities without requiring a save reload.

### Macro Execution Logic and Performance

Processing an entire universe consisting of dozens of clusters, hundreds of galaxies, and thousands of systems requires defensive design to prevent performance drops, memory spikes, or data loss:

1. **Direct-Key File Addressing (O(1) Disk Operations):**
   * Helixteus 3 stores universe objects in partitioned save files indexed by integer ID (`user://<save>/Univ<id>/[Clusters|Galaxies|Systems]/<id>.hx3`).
   * The macro accesses target entity files directly without performing full linear scans across unvisited universe regions.
2. **Non-Blocking Frame Yields:**
   * During batch processing, the macro cooperatively yields execution to the main engine loop (`await tree.process_frame`) every 25 iterations. This maintains engine responsiveness, keeps audio and animations smooth, and prevents operating system "Application Not Responding" freezes.
3. **Safe File I/O and Staging:**
   * Disk writes are staged through an isolated temporary file (`.sols_tmp`). Once written and validated, the data is committed to both the active file (`.hx3`) and the vanilla backup copy (`.hx3~`), after which the temporary file is deleted. This protects save data integrity against unexpected interruptions.
4. **Concurrency Safety (Timer Suspension):**
   * While the macro yields across frames, vanilla background timers—specifically `$MMTimer` (which handles automated mining machine simulations) and `$Autosave`—are temporarily paused.
   * Because automated mining yields are calculated dynamically from system timestamps (`curr_time - collect_date`), pausing `$MMTimer` for the duration of the macro incurs zero resource loss, while completely eliminating concurrent file write collisions and file locking errors on disk.
5. **Deduplication and Sequence Tracking:**
   * Assigned names are indexed into an in-memory hash set to guarantee that duplicate names are never assigned.
   * Monotonic index counters are preserved across game sessions in `sols_utils_naming_registry.json`.
   * Roman numeral formatting accurately maps integer indices from 1 up to 3999 (`I` through `MMMCMXCIX`), with automatic fallback to Arabic numbers beyond that range.
6. **Selective Entity Filtering:**
   * Entities can be filtered based on conquest status (`conquered`) and prior custom names, ensuring that unconquered territories or previously customized systems remain untouched unless explicitly enabled in the configuration.
