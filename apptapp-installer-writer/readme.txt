AppTapp Installer Writer by lex

-For all of Installer 1-3's life, the bane of it's existence has been manually writing the repo.xml file.

Apptapp Installer Writer is written in C and libxml, and is highly portable. It asks for input then generates the desired XML into an i3.xml file. 

==Build==

-Libxml is required (already included in Mac OS X)

Execute make.

==Implemented Script Commands==

-CopyPath 
-RemovePath
-Exec

==Implemented Script Keys==
-Install
-Uninstall

==TODO==

-Automatically get unix time and set it in xml
-Implement all script commands supported by Installer 3
