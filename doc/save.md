# Save Files

Save files are named `SAVGAMxx.DAT` in the `SSHOCK/DATA/` directory (as well as an additional file, `CURRSAV.DAT`, of unknown purpose -- deleting it doesn't seem to cause any adverse effects). They are standard LG RES files containing the same chunks as `ARCHIVE.DAT`, plus four additional chunks with IDs 0, 590, 591, and 3999, of unknown purpose.

The rest of the chunks serve the same purpose that they do in `ARCHIVE.DAT`; their contents, however, may differ based on the player's actions as level geometry is changed, objects are picked up, moved around, or destroyed, and triggers fire. For details on the format of these chunks, see `map.txt`.

## Chunk 0

4 bytes long (always 0?). Purpose unknown.

## Chunks 590 and 591

These chunks are 21 and 512 bytes long, respectively, and their purpose is not yet known; however, their contents do change when the shields are activated. They may contain plot flags.

## Chunk 3999

4 bytes long. Purpose unknown.

## Chunk 4000, the save name chunk

This chunk contains the null-terminated name of the save file, as displayed on the Save/Load Game screens in game.

## Chunk 4001, the player information chunk

This chunk is 1397 bytes long and contains information about the player -- their name, difficulty settings, physics state, hardware and software, inventory, and so forth. It may also contain global plot flags like "has Beta Grove been jettisoned" or the like; research is ongoing, and it's not yet known whether that information is stored here, in the unknown chunks, or in trigger objects associated with specific levels.

### Data types

A `pos16` is a 16-bit coordinate element; the low (first) byte is the position within the tile, and the high (second) byte is the coordinate of the tile itself in the map grid. It is as yet unclear what counts as a "tile" for Z positions; it could plausibly be "the same distance as the side of a floor tile" (i.e. about 2m) or "the same distance as one 'step' in the level geometry". I suspect the former. In either case, it is definitely measured as distance from the bottom of the level, not distance from the floor.

### Chunk layout

The following fields have been identified in this chunk (all offsets in hex). Fields marked with `?` are likely (based on matching up chunk contents with player inventory) but have not yet been confirmed by editing them and seeing those edits reflected in-game.

#### Game information
    0000    char[16?]   player name, null-terminated
    ...
    0015    uint8       combat difficulty
    0016    uint8       mission difficulty
    0017    uint8       puzzle difficulty
    0018    uint8       c/space difficulty
    ...
    0039    uint8       deck number
    ...
    006e    pos16       "false player X"
    0070    pos16       "false player Y"
                        these correspond to the player's location, but changing
                        them doesn't change where the player is when the game is
                        loaded.
    ...

#### Hardware
    02e9    uint8       infrared?
    02ea    uint8       target info?
    02eb    uint8       sensaround?
    02ec    byte[2]     0?
    02ee    uint8       bioscan?
    02ef    uint8       nav/map unit?
    02f0    uint8       shield?
    02f1    uint8       data reader?
    02f2    uint8       lantern?
    02f3    uint8       view control?
    02f4    uint8       envirosuit?
    02f5    uint8       booster?
    02f6    uint8       jumpjet?
    02f7    uint8       status?

#### Software
    02f8    uint8       drill?
    02f9    byte[3]     0?
    02fc    uint8       pulser?
    02fd    byte[2]     0?
    02ff    uint8       shield?
    0300    byte[2]     0?
    0302    uint8       turbo?
    0303    byte        0?
    0304    uint8       decoy?
    0305    uint8       recall?

#### Dermal Patches
    0329    uint8       STAMUP
    032a    uint8       SIGHT
    032b    uint8       BSERK
    032c    uint8       MEDI
    032d    uint8       REFLEX
    032e    uint8       GENIUS
    032f    uint8       DETOX

#### Explosives
    0330    uint8       FRAG
    0331    uint8       EMP
    0332    uint8       GAS
    0333    uint8       CONC
    0334    uint8       MINE
    0335    uint8       NTRO
    0336    uint8       SHKR

#### Position
    0520    pos16       player X
    0222    byte[2]     ???
    0524    pos16       player Y
    0526    byte[2]     ???
    0528    pos16       player Z

It seems likely that player velocity vectors (which are definitely saved) are stored around here somewhere.

### Data not yet located

Chunk 4001 is also known to store (among other things):
- the player's general inventory, as indexes into an object table (transplanting chunk 4001 into another save file results in those indexes pointing to different things, allowing you to end up with, e.g., map triggers, enemies, and decorations in your inventory)
- access cards acquired
- ammunition
- weapons (and likely per-weapon state like number of shots loaded and power level settings)
- emails, v-mails, notes, and other data
- game settings
- player velocity vectors, bearing and azimuth, stance, and lean
- implant configuration and on/off status

Resolution might be at 0x15a - it's 0 at 320x240 and 3 at 640x480 - and fullscreen
flag at 0x196 - it's 0 in halfscreen and 2 in fullscreen. There's also 0x498, which
is 0 in halfscreen and 1 in fullscreen.
