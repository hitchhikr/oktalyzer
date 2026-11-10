A complete disassembly of the Amiga music tool Oktalyzer originally programmed by Armin 'TIP' Sander.

This is an ongoing effort to improve it, modify it to use the hardware mixing and 16 bit samples<br>
of the Amiga Vampire cards and extract an asm replay routine.

To do:

- Make samples start from 1 instead of 0 and mimic Protracker replay behaviours.
- Increase the number of samples to 71.
- 16 bit samples support in the Vampire version (keep the sample type word in infos).
- RIFF samples loading (8 bit but also 16 bit for Vampire).
- Decode the rest of the source.
- Add new pattern effects.
- Select pattern blocks with the mouse.
- Add scrollbars in files requesters.
- Add scrollbar in pattern view.
- Better handling of line editing when quantization is turned off.
- And maybe more...

Done so far:

- Fixed the tracker for AGA and RTG.
- Made a screen refresh frequency independant new replay with improved software mixer<br>
  (notably with separate volume controls for doubled channels and loopable samples).
- Made a replay for the Vampire using only hw channels.
- Fixed the mirror x/mirror y commands inversion in tracker preferences screen.
- Polyphony settings are now randomized when clicking on 'Left-Right' command with right mouse button.
- CLI/WB requester is now correctly positioned on top right coords regardless of the width of the screen.
- Chip/Fast memory display will show 'Plenty!' message if there's a too great amount of memory available.
- Added independant channels volume support to doubled channels.
- Increased the speed upper limit to 63 (0x3F).
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
- Improved the .mod import.
- DEL key now works.
- Samples repeat start & length can be set from range selected with the mouse.
- Fixed the random crashes.
- Sample editor mouse coordinates were shifted in NTSC mode.
- Right mouse button on 'Mark All' will remove sample marking.
- Added a boost function in sample editor (lifted from ProTracker).
- Added a cross fading function in sample editor (lifted from ProTracker).
- Added a normalization function in sample editor.
- Right mouse button click on a channel status will solo it.
- Added Arp 4 effect (E).
- Current displayed pattern number is now displayed beside channels status (top-right).
- Row numbers are now only displayed once per line.
- Range blocks aren't displayed or can't be selected if sample is empty.
- Right mouse button on sample waveform to remove current block mark.
- Available memory and song metrics are now displayed with 9 digits.
- Patterns rows can now be displayed in either decimal or hexadecimal (default).
- Waveforms were displayed upside down in samples editor.
- Removed the 15 samples/8 tracks modules loading, 4 tracks to 8 tracks modules are now recognized & loaded.
- Removed the (annoying) 'No More Samples !!' message.
- Inverted Ctrl+Up/Down (now up is for next sample/down for previous one).
- Also these two shortcuts are now available in sample editor.
- Likewise, up/down, shift+up/down, alt+up/down mapping have been inverted in sample editor<br>
  to increase (up)/decrease (down) edited sample repeat length.
- Changed the mouse pointer sprite.

A work in progress...