# KenanControls-GMS2
## Inspired from Atesquik controls for PTP by [atesquik](https://github.com/atesquik), it's a bunch of mobile controls for GMS2

## Installation
 - Import YYMPS
 - Add `obj_kenancontrols` to the first room in your game
 - Read documentation

## Documentation
### Adding buttons
```gml
kcon_add_element("element_id_here", new KConElementHere(...params...));
```
### Saving/loading configuration
```gml
kcon_save()
kcon_load()
```
### Getting an element by id
```gml
kcon_get("element_id_here")
```
### Element types
#### KConButton (`_sprite`: Sprite, `_x`: Real, `_y`: Real, `_action`: Function<self>, `_angle`: Real, `_vkey`: KeyboardKey, `_hold`: Boolean)
Additional comments:
 - _hold defines if it will *call `_action` for every frame the key is pressed*, or if it will *only run `_action` on the frame it gets held down*
#### KConAnalog (`_sprite`: Sprite, `_x`: Real, `_y`: Real, `_action`: Function<self>, `_angle`: Real, `_thumb_sprite`: Sprite)