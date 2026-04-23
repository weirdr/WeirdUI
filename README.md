# WeirdUI

WeirdUI is a full-theme UI overhaul addon for `World of Warcraft: Midnight` retail.

Its goal is to replace the visual language of Blizzard's default interface with a cohesive, premium-feeling design system while still respecting the parts of the modern WoW UI that must remain secure, protected, and combat-safe.

## What It Is Trying To Do

- build a shared theme and skinning framework before touching feature modules
- let players customize the addon's look through themes, fonts, colors, borders, spacing, and related style primitives
- progressively overhaul the major Blizzard UI families instead of shipping a disconnected set of one-off skins
- preserve Blizzard-owned secure behavior where replacement is unsafe, and restyle or augment those systems instead
- improve high-value gameplay surfaces such as the Objective Tracker, not just repaint them

## Planned Coverage

WeirdUI is intended to grow into a broad overhaul of the retail UI, including:

- action bars
- unit frames, party frames, and raid frames
- minimap, chat, and tooltips
- alerts, toasts, popups, and other transient messaging
- inventory, collections, character panels, and world-browsing panels
- settings, onboarding, and support surfaces
- Midnight-specific systems such as housing

One of the major product goals is a smarter Objective Tracker that can understand current-zone content, relevant weeklies, tracked quests, and reward quality so it can recommend the best next thing for the player to do.

## Development Approach

- theme-first architecture
- iterative implementation by phase, module, and objective
- validation in-game after each small slice of work
- strong bias toward combat safety, low taint risk, and original implementation rather than copied UI packs

## Status

The project is still early. The roadmap and research are in place, and implementation is expected to begin with the theme framework and shared skin engine that every later module will use.
