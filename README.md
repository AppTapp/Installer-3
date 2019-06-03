# Installer 3

### What is this?

After a decade, we are glad to be able to open source Installer 3.

Installer 3 was the de facto package manager for iPhoneOS 1 developed by Ripdev & Nullriver Software (company). It uses the AppTapp framework for managing packages.

### What is included?

Installer source code, AppTapp Framework source, and Translation strings.

### Building

Installer 3 is known to build on Linux and Mac OS X with the iPhone Dev Toolchain. It's easiest to install the toolchain with http://whitera1n.com/lti.

Once the toolchain is installed you can simply cd into the "Installer" directory and "make".

### Installing


On the iPhone OS 1 device, it is recommended you have the Moden iPhone Unix binkit installed to run these commands over ssh or in a Terminal app.

Automatic testing can be used if you edit the TESTHOST in the MakeFile to your IP. Then cd into the "Installer" directory and "make test"

Manual testing/installation can be done with these instructions:

Copy Installer.app to /Applications/Installer.app.

chown -R root:wheel /Applications/Installer.app

chmod 4755 /Applications/Installer.app/Installer

killall -9 SpringBoard

### Debugging 

A neat trick you can do is run executables on the iPhone or iPod Touch like you can on Mac OS X. Over SSH execute /Applications/Installer.app/Installer (if your root you don't even need to set those pesky permissions). Installer.app will open and you can see all the printfs as it runs. This allows you to see where stuff is working and where stuff is broken when making changes to the source. When you want to exit Installer.app, you need to use the ctrl+c combo on whatever you used to SSH into your test device.

### Credit

Ripdev

Nullriver Software

### Translations

English 

Russian 

Dutch

### Future Development

Installer 3 is being further developed by AppTapp & members of the Legacy Jailbreak community for iPhone OS 1. There are no plans to update Installer 3 past iPhoneOS 1. For iPhoneOS 2, see the upcoming Installer 4 source code. See /r/LegacyJailbreak & https://discord.gg/4qec5AV

### Changelog 

VERSION 3.0 - Dialect 300

- Added package operation queues
- Added InstallApp(bundleName) and UninstallApp(bundleName) -- use instead of CopyPath/RemovePath to work with regular app bundles
- Added LinkPath(fromPath, toPath)
- Added If(FreeSpaceAtPath(path, minBytesFree))
- Added If(IsLink(path)), If(IsFolder(path)), If(IsFile(path))
- Added If(IsExecutable(path)), If(IsWritable(path))
- Added If(MinDialect(dialectNumber))
- Added ~ and @Applications support for paths
- Added free space check when upgrading installer, ensures at least 512kb is available
- Added proper keyboard for adding new sources
- Added status indicator when working
- Automatic refresh time is now 12 hours


VERSION 3.1

- Local install repository (~/Media/Installer).
- Greatly improved sources refresh time.
- Added packages filtering for easy searches.
- Packages list is now separated by first letters for easier navigation.
- Package description field text height is now dynamic.
- Added check and an alert for effective user id == root.
- Added proper platform name detection.
- Featured page is being cached for faster startup and less network usage.
- User-Agent being set to the Installer version and also contains platform name and firmware versions.
- X-Device-UUID custom header added to all request for possible tracking purposes by the repository owners.


VERSION 3.11

- Localization support (.lproj all the way!)
- Sources fetched are no longer cached via NSURLRequest
- Fast respring for 1.1.3+
- Source description cell height is now dynamic as well.
- Single source refresh button in the source info.
- Experimental version comparison algo to prevent update offers when package is present in multiple repositories.
- Search field for the Uninstall section.
- Adding a repository will only refresh it and not all of the sources.
- Fixed an issue with permissions for the folders being created not getting proper permissions.
- The section list table is now properly resized when keyboard appears/disappears.

Version 3.12

- Fixed make clean.
- Redid make zip and make since the permissions and zip -r9 thing doesn't actually work correctly.
- Moved the private library directory to within Installer.app. This is because when Installer is on a dual boot jailbroken device, it may incorrectly read the other partition's library files otherwise.
- Tie1r's (pwnstaller) new homepage replaces the defunct one.
- Builds correctly due to Electimon.
- Dutch Translations added by Sam Guichelaar.
- Tweaked installation failed message to be more informative on possible fixes.
- Added defaut library for Installer.app that includes Pwnstaller, SimplySMP, and AppTapp Unofficial sources.

Version 3.13

- Removed UUID tracking, faster source refreshing.
- Added new permissions check system. If incorrect permissions are set, Installer tells the user how to fix it and then presents an Exit button that quits Installer when tapped. 
- Temp directory auto generates in ~/Library/Installer. This fixes a possible bug where if Installer.app was not on disk0s2 and was on disk0s1, a single package could fill up the entire root partition due to the Library change.

## Downloads
- [Installer v3.0](http://pwnstaller.cc/Installer-3.0.zip)
- [Installer v3.01](http://pwnstaller.cc/Installer-3.01.zip)
- [Installer v3.1](http://pwnstaller.cc/Installer-3.1.zip)
- [Installer v3.11](http://pwnstaller.cc/Installer-3.11.zip)
- [Installer v3.12](http://pwnstaller.cc/Installer-3.12.zip)
- [Installer v3.13](http://pwnstaller.cc/Installer-3.13.zip)

### License

The Installer 3 source code is being released under the MIT license. See the LICENSE file for more information.

