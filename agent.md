# WeirdUI Agent Context

## Scope

This workspace targets **World of Warcraft: Midnight retail** UI addon development.

This file is a durable research note for future sessions. It is intentionally opinionated about sources of truth and explicit about what is verified versus what still requires live client inspection.

## Identity Guardrail

- It is critical that the user's real name never appears in commit messages, file contents, metadata fields, author lines, or generated project text.
- Anywhere an author or display name is needed, use `Weirdman`.
- Preserve this rule in all future edits, scaffolding, documentation, and commit-writing work.

## Verified Target

- `World of Warcraft: Midnight` released on 2026-03-02.
- `Patch 12.0.1` is the Midnight launch patch.
- Warcraft Wiki marks the retail WoW API index and Widget API pages as current for `Patch 12.0.1` / build `65893`.
- `Gethe/wow-ui-source` `live` was `12.0.5.67088` at time of research, so the `live` branch is a current Midnight-era retail mirror.

## Source Of Truth

Use sources in this order.

1. Blizzard's generated API docs in `Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated`.
2. The in-game `/api` command.
3. The `Gethe/wow-ui-source` `live` branch for current FrameXML and Blizzard addon implementation.
4. Warcraft Wiki retail API pages and `Patch 12.0.1/API changes` for summarized diffs.
5. Warcraft Wiki `Widget API` and `Widget script handlers` pages for widget hierarchy and script coverage.
6. Client-side export from the actual Midnight client with `ExportInterfaceFiles code` and `ExportInterfaceFiles art` from the login or character select console.

## Important Reality Checks

- There is **not** a separate standalone public "Midnight addon API manual" distinct from retail. The correct Midnight docs are the retail `12.x` docs and UI source.
- A "full Blizzard UI replacement" addon is possible only within Blizzard's secure execution limits. This is not a browser-style total DOM replacement.
- The public API docs catalog systems, namespaces, events, structures, script objects, and widget methods. They do **not** provide a complete static list of every named frame instance that can ever exist in the client.
- Many frames are load-on-demand, mode-specific, encounter-specific, or runtime-generated. To understand "every frame available in the game," static docs must be combined with runtime inspection and exported FrameXML.

## Midnight-Era Constraint Model

Midnight retail clearly continues and expands the modern retail security model.

Key verified systems and behaviors:

- `InCombatLockdown()` still matters and must be treated as a hard boundary.
- `C_RestrictedActions` exposes restriction state and blocked action events.
- `ADDON_ACTION_BLOCKED`, `ADDON_ACTION_FORBIDDEN`, `MACRO_ACTION_BLOCKED`, `MACRO_ACTION_FORBIDDEN`, and `ADDON_RESTRICTION_STATE_CHANGED` are core diagnostics.
- `FrameScript` includes secret-value and security APIs such as `canaccessvalue`, `canaccessallvalues`, `secretwrap`, `secretunwrap`, `scrub`, `scrubsecretvalues`, `CreateSecureDelegate`, and `SetTableSecurityOption`.
- Many `SimpleFrame` methods are protected or restriction-aware, including operations around visibility, frame strata/level, moving, sizing, scale, input, and attributes.
- Secret aspects are now a first-class part of the API model. The docs explicitly mark text, alpha, attributes, bar values, cooldown data, hierarchy, shown state, and similar aspects as secret or conditionally secret in many places.

Practical implication:

- WeirdUI should assume that anything combat-relevant, click-secure, or visibility-critical must be wrapped, mirrored, or restyled carefully rather than naively replaced.

## Core Widget Model

Warcraft Wiki's `Widget API` page is explicitly current for `Patch 12.0.1` and remains the best concise map of widget types.

### Base Types

- `FrameScriptObject`
- `Object`
- `ScriptObject`
- `ScriptRegion`
- `Region`

### Texture Types

- `Texture`
- `MaskTexture`
- `Line`

### Font Types

- `Font`
- `FontString`

### Animation Types

- `AnimationGroup`
- `Animation`
- `Alpha`
- `FlipBook`
- `Path`
- `ControlPoint`
- `Rotation`
- `Scale`
- `TextureCoordTranslation`
- `Translation`
- `VertexColor`

### Frame Types

- `Frame`
- `Button`
- `CheckButton`
- `Model`
- `PlayerModel`
- `CinematicModel`
- `DressUpModel`
- `TabardModel`
- `ModelScene`
- `ModelSceneActor`
- `EditBox`
- `MessageFrame`
- `SimpleHTML`
- `GameTooltip`
- `ColorSelect`
- `Cooldown`
- `Minimap`
- `MovieFrame`
- `ScrollFrame`
- `Slider`
- `StatusBar`
- `FogOfWarFrame`
- `UnitPositionFrame`
- `ArchaeologyDigSiteFrame`
- `QuestPOIFrame`
- `ScenarioPOIFrame`

### Intrinsics

- `ItemButton`
- `ScrollingMessageFrame`

## Useful Script Handlers

Relevant script coverage confirmed on the `Widget script handlers` page:

- `OnShow`
- `OnHide`
- `OnEnter`
- `OnLeave`
- `OnMouseDown`
- `OnMouseUp`
- `OnMouseWheel`
- `OnEvent`
- `OnUpdate`
- `OnSizeChanged`
- `OnDragStart`
- `OnDragStop`
- `OnReceiveDrag`
- `OnKeyDown`
- `OnKeyUp`
- `OnChar`
- `OnHyperlinkClick`
- `OnHyperlinkEnter`
- `OnHyperlinkLeave`
- `OnClick`
- `PreClick`
- `PostClick`
- `OnValueChanged`
- `OnMinMaxChanged`
- `OnTooltipCleared`
- `OnTooltipSetDefaultAnchor`
- `OnCooldownDone`

Practical implication:

- WeirdUI can build most presentation and interaction using standard `Frame`, `Texture`, `FontString`, `Button`, `ScrollFrame`, `StatusBar`, `Cooldown`, and animation objects.
- Secure/protected restrictions determine where these can replace Blizzard behavior versus only skin or augment it.

## Retail Systems Most Relevant To WeirdUI

The retail API index explicitly confirms these systems or namespaces as important for UI-overhaul work:

- `FrameScript`
- `GameUI`
- `UI`
- `UIWidgetManager`
- `GenericWidgetDisplay`
- `ActionBar`
- `EditModeManager`
- `NamePlate`
- `NamePlateManager`
- `UnitAuras`
- `Minimap`
- `TooltipInfo`
- `TooltipComparison`
- `UIFrameManager`
- `UISystemVisibilityManager`
- `RestrictedActions`
- `MapUI`
- `MapExplorationInfo`
- `AdventureMap`
- `TaxiMap`
- `ChatInfo`
- `ChatBubbles`
- `Container`
- `SpellBook`
- `ClassTalents`
- `PlayerInfo`
- `PartyInfo`
- `CompactUnitFrames`
- `HousingUI`
- `HousingBasicModeUI`
- `HousingCatalogUI`
- `HousingCleanupModeUI`
- `HousingCustomizeModeUI`
- `HousingDecorUI`
- `HousingExpertModeUI`
- `HousingLayoutUI`
- `HousingNeighborhoodUI`
- `HousingPhotoSharingUI`

## Subsystem Notes

### Action Bars

Verified in `ActionBarFrameDocumentation.lua`:

- `C_ActionBar` is the authoritative API surface for bar slots, cooldowns, charges, range checks, autocast, bar pages, special bars, and registration of UI action buttons.
- The API knows about bonus, override, extra, pet, temp shapeshift, vehicle, and assisted combat action bars.
- Cooldown and charge queries are explicitly marked secret or restricted in multiple places.
- `RegisterActionUIButton` exists for linking a checkbox frame and cooldown frame to an action slot.
- Events include `ACTIONBAR_SLOT_CHANGED`, `ACTIONBAR_UPDATE_COOLDOWN`, `ACTIONBAR_UPDATE_STATE`, `ACTIONBAR_UPDATE_USABLE`, `ACTION_RANGE_CHECK_UPDATE`, `UPDATE_OVERRIDE_ACTIONBAR`, `UPDATE_EXTRA_ACTIONBAR`, and related signals.

Practical implication:

- Action buttons should be treated as secure UI first and visual widgets second.
- Rebuilding action bars is feasible, but click behavior, paging, state propagation, and combat safety must remain aligned with the secure model.

### Edit Mode

Verified in `EditModeManagerDocumentation.lua`:

- `C_EditMode.GetLayouts()` returns layout data.
- `C_EditMode.SaveLayouts()` persists layout data.
- `C_EditMode.SetActiveLayout()` switches layouts.
- Layouts consist of systems, anchors, settings, and default-position flags.
- `EDIT_MODE_LAYOUTS_UPDATED` is the primary event.

Practical implication:

- WeirdUI should decide explicitly whether it integrates with Blizzard Edit Mode, coexists beside it, or partially imports/export Blizzard layout information.

### Nameplates

Verified in `NamePlateDocumentation.lua` and `FrameAPINamePlateDocumentation.lua`:

- `C_NamePlate.GetNamePlateForUnit()` and `C_NamePlate.GetNamePlates()` expose runtime nameplate frames.
- `C_NamePlate.SetNamePlateSize()` exists but is restriction-aware.
- Nameplate frame hit-test geometry has its own guarded API.
- `NamePlateFrame:CanChangeHitTestPoints()` explicitly warns that tainted code is normally blocked in combat except in narrow timing cases.
- `SetStackingBoundsFrame()` exists for stacking behavior.

Practical implication:

- Nameplates are a prime example of "can overhaul, but not recklessly." Expect combat and taint-sensitive edges.

### Unit Auras

Verified in `UnitAuraDocumentation.lua`:

- `C_UnitAuras` is the modern authoritative aura API.
- The API is instance-ID-centric and supports slot-based and bulk queries.
- `UNIT_AURA` now carries `updateInfo` and should be preferred over older blind rescans.
- Aura data can be restricted or secret depending on unit and context.
- Private aura APIs and anchors are exposed.
- `GetUnitAuras`, `GetUnitAuraInstanceIDs`, `GetAuraDataByAuraInstanceID`, `GetUnitAuraBySpellID`, and duration helpers are the key data APIs.

Practical implication:

- Buff/debuff overhauls should be based on `C_UnitAuras` rather than legacy `UnitBuff`/`UnitDebuff` assumptions.

### Tooltips

Verified in `TooltipInfoDocumentation.lua`:

- `C_TooltipInfo` is the preferred data-driven tooltip API.
- It exposes tooltip data for actions, items, units, spells, auras, quests, currencies, mail, sockets, spellbook entries, minimap mouseover, world cursor, and more.
- `TOOLTIP_DATA_UPDATE` is the update event when sparse or cached lookups resolve.

Practical implication:

- WeirdUI should prefer `C_TooltipInfo` and tooltip data processing over scraping rendered tooltip text where possible.

### Minimap

Verified in `MinimapDocumentation.lua`:

- `C_Minimap` controls tracking state, inset info, map view radius, quest blob state, draw-ground-texture behavior, and hybrid minimap decisions.
- `MINIMAP_PING`, `MINIMAP_UPDATE_TRACKING`, and `MINIMAP_UPDATE_ZOOM` are key events.
- The minimap remains an engine-owned system with addon-facing configuration and presentation hooks.

Practical implication:

- A minimap overhaul should focus on frame composition, tracking UX, styling, and attached buttons/widgets rather than expecting total ownership of underlying map behavior.

### Root UI And Visibility

Verified in `UIManagerDocumentation.lua`, `UIFrameManagerDocumentation.lua`, and `UISystemVisibilityManagerDocumentation.lua`:

- `C_UI.GetUIParent()` and `C_UI.GetWorldFrame()` are the root entry points.
- UI scale and notched-display safe-region APIs exist.
- `C_FrameManager.GetFrameVisibilityState()` exists, but its documented enum is very small and is **not** a universal registry of all frames.
- `C_SystemVisibilityManager.IsSystemVisible()` exists, but its documented enum is also very small and is **not** a general-purpose "all UI systems" database.

Practical implication:

- Do not mistake these managers for a complete frame inventory. They are narrow system managers, not a master map of Blizzard UI.

### Compact Unit Frames And Party/Raid UI

Verified in the public docs:

- `CompactUnitFrames` currently exposes very little directly in the generated API docs beyond `COMPACT_UNIT_FRAME_PROFILES_LOADED`.
- This means the real behavior for raid/party frames must be understood by reading Blizzard UI source and inspecting runtime frames.

Practical implication:

- Party and raid overhauls will require heavier FrameXML/source inspection than systems like tooltips or action bars.

## Midnight-Specific Or Newly Important 12.x Areas

The clearest Midnight-era UI surface expansion is **housing**.

Confirmed housing-related systems in the live generated docs include:

- `HousingUI`
- `HouseEditorUI`
- `HouseExteriorUI`
- `HousingBasicModeUI`
- `HousingCatalogUI`
- `HousingCleanupModeUI`
- `HousingCustomizeModeUI`
- `HousingDecorUI`
- `HousingExpertModeUI`
- `HousingLayoutUI`
- `HousingNeighborhoodUI`
- `HousingPhotoSharingUI`

The `Patch 12.0.1/API changes` page also confirms new or notable Midnight launch additions in these areas:

- housing market and layout APIs
- housing photo sharing APIs
- encounter timeline APIs
- encounter warnings APIs
- combat audio alert APIs
- damage meter APIs
- `FontString:ClearText`
- `GameTooltip:ClearPadding`
- new nameplate-related CVars and class-color toggles

Practical implication:

- Housing is the most clearly new Midnight UI domain and will likely deserve a dedicated WeirdUI subsystem if housing UX is in scope.

## What "Every Frame" Actually Means

For future sessions, use this definition:

- The **widget API** gives the complete class hierarchy we can instantiate and manipulate.
- The **generated documentation** gives the authoritative callable API surface.
- The **FrameXML / Blizzard addon source** gives Blizzard's actual implementations and frame names.
- The **live client** gives the currently instantiated runtime frames, including load-on-demand and mode-specific objects.

Therefore, a serious inventory of every available frame requires all four layers.

## Required Runtime Discovery Workflow

When investigating a Blizzard UI area, do this in order.

1. Check the Midnight retail version being targeted.
2. Inspect the relevant file in `Blizzard_APIDocumentationGenerated`.
3. Search the live `wow-ui-source` branch for the implementing Blizzard addon or FrameXML file.
4. In the actual client, use `/api` to inspect the system live.
5. In the actual client, use `/fstack` to identify live frame names and parent chains.
6. Use `/tinspect` or a dev addon to inspect frame tables and mixins at runtime.
7. If necessary, export interface files from the login or character select console.

## High-Value In-Game Commands

- `/api system list`
- `/api ActionBar list`
- `/api UnitAuras search Aura`
- `/api EditModeManager list`
- `/api NamePlate list`
- `/api TooltipInfo list`
- `/api UI search Parent`
- `/fstack`
- `/tinspect SomeFrame`

For code export from the client console at login or character select:

- `ExportInterfaceFiles code`
- `ExportInterfaceFiles art`

## Working Engineering Assumptions For WeirdUI

- Prefer **reskin, reanchor, wrap, and augment** over destructive replacement of protected Blizzard frames.
- Treat action bars, unit frames, nameplates, click targets, and combat visibility as secure systems first.
- Prefer data APIs like `C_TooltipInfo`, `C_UnitAuras`, and `C_ActionBar` over scraping visible text or texture state.
- Expect party/raid/unit-frame work to require more source and runtime inspection than the generated docs alone provide.
- Keep WeirdUI layout state explicit and separate, even if Blizzard Edit Mode interop is supported.
- Assume load-on-demand Blizzard UI exists and build addon modules lazily.

## Verified Research Sources

- Warcraft Wiki: `World of Warcraft API`
- Warcraft Wiki: `Patch 12.0.1/API changes`
- Warcraft Wiki: `Widget API`
- Warcraft Wiki: `Widget script handlers`
- Warcraft Wiki: `APILink`
- Warcraft Wiki: `Viewing Blizzard's interface code`
- Warcraft Wiki: `World of Warcraft: Midnight`
- `Gethe/wow-ui-source` `live`
- `Gethe/wow-ui-source/live/version.txt`
- `Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/*`

## Current Bottom Line

We now have a verified Midnight-retail addon research baseline.

- The correct API target is retail `12.x`, not an imagined separate doc set.
- The most important engineering constraint is the protected / secret / taint / restriction model.
- The most important new Midnight UI domain is housing.
- The most important next step for any specific WeirdUI subsystem is to pair generated docs with live FrameXML source and runtime frame inspection.
