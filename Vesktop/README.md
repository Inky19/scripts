# Vesktop scripts

A collection of scripts to tweak [Vesktop](https://github.com/Vencord/Vesktop), an alternative client of Discord which fixes many issues with Discord on Linux.

## Vesktop customizer
Lastest version tested : `Vesktop 1.5.5`

This script aims to automate the customization of Vesktop's loading animation GIF and system tray icon (as the time of writing, this feature has not yet been integrated into the main release). It will basically repackage the `app.asar` file used by Vesktop.

This script can be automated using flags.

> [!NOTE]
> The program icon itself is not supported as it can easily be changed in your .desktop entry (which is highly dependent on your Linux distribution).


### Requirements

The command `asar` must be available on your system.

### Usage

Working directory and assets location must be the same directory as the script.

- The loading GIF must be named `animation.gif`. Note that Vesktop support transparent GIFs. For best results, use a square GIF.
- The system tray icon must be named `icon.png`. For best results, use a square image.

You can then run `./vesktop_customizer.sh`. Use `-h` to get a list of all available options.