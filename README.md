A complete disassembly of the Amiga music tool Oktalyzer originally programmed by Armin 'TIP' Sander.

This is an ongoing effort to improve it, modify it to use the hardware mixing of the Amiga Vampire cards
and extract an asm replay routine.

To do:

- Integrate the new replay into the tracker.
- Add 'help' gadgets onto the the different screens.
- Remove the constraints of the sample types (remove the samples types).
- Patch the older songs volume effects for double channels:<br>
  oxx will be converted to vxx (as we don't need hw channels volumes backup anymore).<br>
  v00 will always be duplicated, vxx values won't be if there's an effect on the other channel.
- 'OKTASON1' header tag for new Amiga songs (so songs volume columns aren't fixed again).
- 'OKTASON2' header tag for Vampire songs (16 bit samples and maybe more).
- 8/16 bit samples in the vampire version (keep the sample type word in infos).
- Add the possibility to load wave samples (8 bit but also 16 bit for Vampire).
- Add a clear way to set the samples repeat start & length.
- Set new colors for the default config.
- Remove the 15 samples/8 tracks modules loading and check for 1 track to 8 tracks modules signatures (and load them).
- Decode the rest of the source.
- Understand what the effects editor is for.
- Add new patterns effects.
- Change the version number and the bottom picture.

Done:

- Fixed the tracker for AGA and RTG.
- Made a screen refresh frequency independant new replay with improved software mixer.
- Made a replay for the Vampire using only hw channels.
- Fixed the mirror x/mirror y commands inversion in tracker preferences screen.
- Polyphony settings are now randomized when clicking on Left-Right command with right mouse button.
- CLI/WB requester is now correctly positioned on top right coords regardless of the width of the screen.
- Chip/Fast memory display will show 'Plenty!' message if there's a too great amount to be available.
- Added independant volumes support to doubled channels.
- Increased the speed limit to 31.

A work in progress...