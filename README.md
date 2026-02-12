A complete disassembly of the Amiga music tool Oktalyzer originally programmed by Armin 'TIP' Sander.

This is an ongoing effort to improve it, modify it to use the hardware mixing and 16 bit samples<br>
of the Amiga Vampire cards and extract an asm replay routine.

To do:

- Fix some random crashes.
- 16 bit samples support in the Vampire version (keep the sample type word in infos).
- The possibility to load riff samples (8 bit but also 16 bit for Vampire).
- Add a way to set the samples repeat start & length from range selected with the mouse.
- Remove the 15 samples/8 tracks modules loading and check for 1 track to 8 tracks modules signatures (and load them).
- Decode the rest of the source.
- Add new pattern effects.
- Select pattern blocks with the mouse.
- Using (Shift)TAB key to navigate among the tracks.
- Add scrollbars in files requesters.
- Create an option to display rows numbers in decimal or hexadecimal.
- And maybe more...

Done:

- Fixed the tracker for AGA and RTG.
- Made a screen refresh frequency independant new replay with improved software mixer<br>
  (notably with separate volume controls for doubled channels and loopable samples).
- Made a replay for the Vampire using only hw channels.
- Fixed the mirror x/mirror y commands inversion in tracker preferences screen.
- Polyphony settings are now randomized when clicking on 'Left-Right' command with right mouse button.
- CLI/WB requester is now correctly positioned on top right coords regardless of the width of the screen.
- Chip/Fast memory display will show 'Plenty!' message if there's a too great amount of memory available.
- Added independant channels volume support to doubled channels.
- Increased the speed upper limit to 31 (0x1F).
- Now displays a requester when trying to save over a file that already exists.
- Set a new colorscheme for the default config.
- Integrated the new replay into the tracker.
- 'OKTASNG2' header tag for new Amiga songs (so songs volume fx aren't fixed again).
- 'OKTASNG3' header tag for Vampire songs (16 bit samples and maybe more).
- Older songs with doubled channels are patched upon loading:<br>
  oxx fx are converted to vxx (as we don't need hw channels volumes backup anymore).<br>
  vxx will be duplicated if there's no effect on the other channel.
  Also, the original Oktalyzer didn't set the volume for samples used on doubled channels, fixed.
  4 bit samples are also extended back to 8 bit.
  Still, older modules will sound slightly different.
- Removed the constraints of the sample types.
- Changed the version number and the bottom picture.

A work in progress...