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
-ExecNoError

==Implemented Script Keys==
-Install
-Uninstall

==TODO==

-Automatically get unix time and set it in xml
-Implement all script commands supported by Installer 3

==Usage==

By using args, you can manually specify what Script Commands you want in your XML. This can be much more effecient when compared to the argless usage of AppTapp Installer Writer, which asks you if you want each Script Command one by one.

Usage:
aiw --start --cp --rp -e --ene --help --version
--start Start an Installer source XML
--cp Specify you want CopyPath
--rp Specify you want RemovePath
-e Specify you want Exec
-ene Specify you want ExecNoError

