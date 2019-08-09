# Redmond97
A Win9x inspired theme for GTK3 and GTK2 developed for XFCE4
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/desktop.png)
## About
The Redmond97 project aims to recreate the nostalgic look of the Win9x desktop for the XFCE4 desktop environment. 

## Extras
Included with the main theme package are the GTK themes, the Xfce4WM theme, and a Firefox classic IE3 theme.
Many color schemes from the Windows 98 Plus! pack are also included. A theme generator script is also available 
to compile the Redmond97 theme using custom colors.

## Requirements
#### Main theme
The following packages are recommended for full functionality:
```
firefox, xfce4, xfce4-goodies, xfce4-whiskermenu-plugin (included with xfce4-goodies), gtk-nocsd
```

The theme has been designed for XFCE4 so the XFCE4 desktop environment is highly recommended but not required
for the use of the GTK and Firefox themes. There is no Window Manager theme support for desktop environments
other than XFCE4 at this time. The theme also includes support for the GTK3 version of Whisker Menu if available.

#### Redmond97 Theme Builder
For the theme generator the following packages are also required:
```
imagemagick, bc, sed, grep, tar
```

## Installation
### Main theme
Make a .themes directory in your home directory if one doesn't exist and extract the Redmond97.tar.gz archive into 
the ~/.themes directory.
```
mkdir ~/.themes
tar -xvzf Redmond97.tar.gz -C ~/.themes/
```
The GTK2/3 and Xfce4WM themes will now be installed.
It is also recommended to disable GTK overlay scrollbars (autohiding scrollbars in GTK3). The following command
will disable the overlay scrollbars for the current user:
```
export GTK_OVERLAY_SCROLLING=0
```
You may have to log out and back in for the setting to take effect.

### Xfce4 Panel Configuration
The main theme includes a GTK2 hack for the system tray and orage clock applet to make them appear to be
inside the same inset frame (only applies to GTK2 version of the Xfce4 panel). In order for the frames to display
correctly, you must add the two applets in order: "Notification Area" and then "Orage Clock". Your panel layout should look
like the image below:

![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/applet.png)

Once you have added the applets you will notice that the frames between the two applets don't line up correctly.
To fix this you will need to deselect the option "Show Frame" for the notification area applet.
Right click on the notification tray applet and select "Properties":

![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/properties.png)

Uncheck the option "Show Frame" on the dialog window:

![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/dialog.png)

The frame borders should now look aligned between the notification area and the Orage Clock applets.
(Note that there will be a small gap between the two applets this is currently a bug in the theme.)

#### Firefox theme
You will first need to find your firefox user profile directory. It is usually the one that ends with ".default".
To find the correct directory, open a terminal and go to the hidden Firefox directory. Using grep you can view the directories
ending with ".default".
```
cd ~/.mozilla/firefox
ls | grep default
```
In this exmaple I have two directories: one .default and the other .default-release. 
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/console.png)
If you only have one directory ending with .default that one is the correct profile directory and you can skip
this next step. Otherwise, you can run the following to see which profile is the default.
```
firefox -P
```
You will then see the following window:

![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/firefox.png)

The selected profile is your default profile, in my case it is the default-release profile.

Once you have found the correct profile directory, you will then need to make a directory inside of it called "chrome".
Following my example above you would run the command:
```
mkdir ~/.mozilla/firefox/vugvl4ul.default-release/chrome
```
Now that the chrome directory has been created, you can install the classic IE3 theme by extracting the 
ie3_classic_firefox.tar.gz archive into your chrome folder. Again, using my example above the command would be:
```
tar -xvzf ie3_classic_firefox.tar.gz -C ~/.mozilla/firefox/vugvl4ul.default-release/chrome/
```
The Firefox theme should now be installed and will be activated once you close all Firefox sessions and restart Firefox.
## Known issues
As of right now GTK3 Libre-Office does not display 100% correctly. Some widgets are off in the preferences 
window and the scrollbar buttons don't use the default theme arrows. There has however, been many additions to the theme for LibreOffice compatibility
and I no longer recommend using the GTK2 workaround for this theme.

## TODO
1. Write documentation for the theme builder script
2. Add more features to the theme generator
3. Troubleshoot Libre-Office issues

## Screenshots
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/Screenshot1.png)
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/Screenshot2.png)
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/Screenshot3.png)
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/Screenshot4.png)
![Image Screenshot](https://github.com/matthewmx86/Redmond97/blob/master/Screenshots/Screenshot5.png)
