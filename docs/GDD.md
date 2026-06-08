# Riftforge — GDD

## Pillars

1. **Readable 3D RTS combat** — strong team colors, silhouettes, HP bars, and clear command feedback.
2. **Hero-led fantasy skirmish** — a named champion anchors each army, but the game remains about squads and bases.
3. **Harvest-build-fight loop** — gather Aether/Crystal, train units, destroy the enemy hall.
4. **Original IP** — no Warcraft units, names, logos, or story elements.

## Factions

### Ironward Covenant
A runesmith order defending rift-scarred borderlands.

- Hero: Rift Marshal
- Worker: Aether Mason
- Soldier: Shieldbearer
- Buildings: Ironward Keep, Runesmith Forge, Aether Spire

### Thornborne Compact
A wildwood alliance reclaiming land consumed by unstable magic.

- Hero: Grove Matriarch
- Soldier: Briar Warden
- Buildings: Thornborne Elder Hall, Briar War Lodge, Root Spire

## Resources

- **Aether:** primary magical fuel from blue blooms
- **Moon Crystal:** advanced magical mineral from purple crystal clusters

## Controls

- WASD: pan camera
- Mouse wheel: zoom
- Left click: select
- Drag left mouse: box select
- Right click ground: move
- Right click enemy: attack
- Right click resource with worker: harvest
- Q on building: train Shieldbearer
- E on hall: summon Rift Marshal

## Vertical Slice Success Criteria

- Screenshot shows 3D terrain, bases, units, resources, HUD, and readable fantasy RTS composition.
- Import/capture run succeeds in headless Godot/Xvfb.
- Core loop is playable enough: select units, order movement, attack, harvest, train.
