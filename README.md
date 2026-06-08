# Riftforge

Original Godot 4.4 3D fantasy RTS vertical slice inspired by the readable hero-unit, base-building, and battlefield command feel of classic fantasy RTS games — without using Warcraft names, art, factions, or lore.

## Features

- 3D RTS camera: WASD pan and mouse-wheel zoom
- Mouse selection: click or drag-select Ironward units/buildings
- Right-click commands: move, attack enemies, harvest resource nodes
- Two original factions: **Ironward Covenant** vs **Thornborne Compact**
- Units: hero, warriors, workers, enemy wardens
- Buildings: great hall, barracks/forge, defensive towers
- Resources: blue Aether Blooms and purple Moon Crystals
- Combat loop: melee attacks, HP bars, floating damage numbers, hit sparks
- Production loop: select a building, press `Q` to train warriors or `E` to summon a hero
- HUD: resources, selected-unit panel, objective banner, command hints
- FAL-generated battlefield art integrated as terrain/key art
- Procedural audio: battle drone, command chime, sword hit, harvest shimmer
- Headless screenshot capture artifact for verification

## Run

```bash
/home/ganomix/tools/godot/Godot_v4.4.1-stable_linux.x86_64 --path .
```

## Verify / capture screenshot

```bash
/home/ganomix/tools/godot/Godot_v4.4.1-stable_linux.x86_64 --headless --import --quit-after 60
xvfb-run -a -s "-screen 0 1280x720x24" \
  /home/ganomix/tools/godot/Godot_v4.4.1-stable_linux.x86_64 \
  --path . --quit-after 600 res://artifacts/capture_scene.tscn
```

Latest capture path: `artifacts/screenshot.png`.
