# Vesktop scripts

A collection of scripts to tweak [Vesktop](https://github.com/Vencord/Vesktop), an alternative client of Discord which fixes many issues with Discord on Linux.

## Disblock custom
This is a theme heavily based on the excellent [DisblockOrigin by TheSunCat](https://codeberg.org/AllPurposeMat/Disblock-Origin) with additional tweaks to hide anything nitro-related, hide some Vesktop promotions and correct some aberrations made in the new (03/2025) Discord desktop UI.  
In particular, it hides the top bar and aligns the profile panel with the send message bar.  
  
If you're using Vesktop, put this file in `~/.config/vesktop/themes` (or equivalent if you're not using Linux, although you really should).

## Vesktop customizer
Lastest version tested : `Vesktop 1.5.6`

This script aims to automate the customization of Vesktop's desktop icon, loading animation GIF and system tray icon (as the time of writing, this feature has not yet been integrated into the main release). It will basically repackage the `app.asar` file used by Vesktop and delete existing icons to replace them.

This script can be automated using flags.

### Requirements

The command `asar` must be available on your system.

### Usage

Working directory must be the same directory as the script and have the "assets" subdirectory which should contains the following :

- The loading GIF must be named `animation.gif`. Note that Vesktop support transparent GIFs. For best results, use a square GIF.
- The system tray icon must be named `icon.png`. For best results, use a square image.
- All desktop icons must be PNG and be placed in a subdirectory `icons` (so in *assets/icons*) and must be named according to their resolution. The script will copy them into the system icon folder for Vesktop (usually /usr/share/icons/hicolor) and place each icon in the **subdirectory with the same name**. For example, the icon `assets/icons/64x64.png` will be copied to `/usr/share/icons/hicolor/64x64/apps/vesktop.png`. 

You can then run `./vesktop_customizer.sh`. Use `-h` to get a list of all available options.
