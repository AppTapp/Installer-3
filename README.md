# Installer 3

### What is this?

After a decade, we are glad to be able to open source Installer 3.

Installer 3 was the de facto package manager for iPhoneOS 1 developed by Ripdev & Nullriver Software (company). It uses the AppTapp framework for managing packages.

### What is included?

Installer source code, AppTapp Framework source, and Translation strings.

### Building

Installer 3 can be compiled or cross compiled with 3 different compilers. See the file INSTALL for documentation. 

### Packaging

Historically, Installer 3 Sources were setup all by hand. AppTapp Installer Writer is a new program that automates writing bits of XML for packages as well as setting up a source from scratch. 

To build AppTapp Installer Writer, cd into the Writer directory and execute make. 

By using args, you can manually specify what Script Commands you want in your XML. This can be much more effecient when compared to the argless usage of AppTapp Installer Writer, which asks you if you want each Script Command one by one.

Full Usage:
aiw --start --cp --rp -e --ene --help --version
--start Start an Installer source XML
--cp Specify you want CopyPath
--rp Specify you want RemovePath
-e Specify you want Exec
-ene Specify you want ExecNoError

For examples of existing sources, see

- http://lexploit.com/apptapp/repo.xml
- http://lexploit.com/bigboss/repo.xml
- http://simplysmp.net/installer/repo.xml
- http://pwnstaller.cc/repo.xml
- http://apptapp.saurik.com/


### Credit

Ripdev

Nullriver Software

### Translations

English 

Russian 

Dutch

French

### Future Development

Installer 3 is being further developed by AppTapp & members of the Legacy Jailbreak community for iPhone OS 1. There are no plans to update Installer 3 past iPhoneOS 1. For iPhoneOS 2, see the upcoming Installer 4 source code. See /r/LegacyJailbreak & https://discord.gg/4qec5AV

### Changelog 

See the file CHANGELOG.md for all changes made from version 3.0 to the currently in development 3.1.3 beta.

### License

The Installer 3 source code is being released under the MIT license. See the LICENSE file for more information.

