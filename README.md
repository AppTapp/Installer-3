# Installer 3

### What is this?

After a decade, we are glad to be able to open source Installer 3.

Installer 3 was the de facto package manager for iPhoneOS 1 developed by Ripdev & Nullriver Software (company). It uses the AppTapp framework for managing packages.

### What is included?

Installer source code, AppTapp Framework source, Repository Code, Translation strings.

### Building

Installer 3 is known to build on Linux and Mac OS X with the iPhone Dev Toolchain. It's easiest to install the toolchain with http://whitera1n.com/lti.

Once the toolchain is installed you can simply cd into the "Installer" directory and "make".

### Installing

On the iPhone OS 1 device, it is recommended you have the Moden iPhone Unix binkit installed to run these commands over ssh or in a Terminal app.

Copy Installer.app to /Applications/Installer.app.

chown -R root:wheel /Applications/Installer.app

chmod 4755 /Applications/Installer.app/Installer

killall -9 SpringBoard

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

### License

The Installer 3 source code is being released under the MIT license. See the LICENSE file for more information.

