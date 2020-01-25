### Building Requirements

Installer 3 can be built on Linux, Mac OS X, and iOS 1.0-1.1.5 itself. You can use the arm-apple-darwin iPhone Dev Toolchain, Saurik's arm-apple-darwin8 toolchain, or Saurik's native iOS 1.x GCC. The tool chains can be installed by Lex's Toolchain Installer found at http://lexploit.com/lti .

To compile Installer 3 on iOS 1.x You will need to install these packages:

-Modern iPhone Unix
-Make
-Saurik iPhone Toolchain
-Git(optional)
-ssh or Terminal

These can be found at http://lexploit.com/pxl

### Building

execute config gcc for compiling on iOS 1 with Saurik's GCC 4.2.1 compiler.

execute config arm-apple-darwin for cross compiling with the iPhone Dev Team LLVM-GCC 4.0.1 compiler.

execute config arm-apple-darwin8 for cross compiling with the Saurik LLVM-GCC 4.2.1 compiler.

Then execute make.

### Installing A Native Build

If you built on the jailbroken firmware 1.0-1.1.5 iPhone or iPod Touch itself you can do the command:

make install 

to install the App on your device. It will replace any current Installer version on your device. You may need to restart SpringBoard to see it.

### Cross Compiled Installation

On the iOS 1 device, it is recommended you have the Moden iPhone Unix binkit installed to run these commands over ssh or in a Terminal app.

Automatic testing can be used if you edit the TESTHOST in the MakeFile to your IP. Then cd into the "Installer" directory and "make test"

Manual testing/installation can be done with these instructions:

Copy Installer.app to /Applications/Installer.app.

chown -R root:wheel /Applications/Installer.app

chmod 4755 /Applications/Installer.app/Installer

Restart SpringBoard

### Debugging 

A neat trick you can do is run executables on the iPhone or iPod Touch like you can on Mac OS X. Over SSH execute /Applications/Installer.app/Installer (if your root you don't even need to set those pesky permissions). Installer.app will open and you can see all the printfs as it runs. This allows you to see where stuff is working and where stuff is broken when making changes to the source. When you want to exit Installer.app, you need to use the ctrl+c combo on whatever you used to SSH into your test device.
