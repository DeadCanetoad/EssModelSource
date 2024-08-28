"ESS-Model is a powerful, reverse engine, UML-tool for 
Delphi/Kylix and Java-files."



ESS-Model used to be an commercial product but is now
released as an Open Source under the GPL.

Note about compiling the source:


The source is written in Delphi 6.

The following conditional defines can be set:

GIF_SUPPORT - Define this to use the free GIF-component which
can be downloaded from: http://www.melander.dk/delphi/gifimage/

DRAG_SUPPORT - Define this to use the free Drag and drop component
which can be downloaded from: http://www.melander.dk/delphi/dragdrop/


We started developing an Kylix version, about 90% of the code
is platform independent.


Here follows the original readme-file:





ESS-Model
---------

o  Introduction
o  Installation
o  Command line options
o  Explorer and Delphi integration
o  Registering ESS-Model



Introduction
------------
ESS-Model is a powerful, reverse engine, UML-tool for Delphi/Kylix and Java-files.

The easiest way to get class diagrams from source code.

Easy to use, lightning fast and with automatic documentation
possibilities. 

ESS-Model Free version includes:

- Automatic generation of UML-standard class diagrams from your source.
- Lightning fast installation and execution, only 1 exe-file needed (approx.700Kb)
- Delphi/Kylix (.dpr, .pas) and Java (.class, .java) parser.
- Easy Drag-n-Drop user interface.
- Easy integration into Delphi/Kylix.
- Full control from command-line.

ESS-Model Registered version features: 

- All of the above. 
- JavaDoc-style HTML-documentation. 
- XMI-export features. 
- No limit on nr of inputfiles.
 


Installation
------------
You do not need to run an separate installation program.

Simply extract ESSMODEL.EXE from the zip file to the directory 
you want to put it in. 

Then doubleclick on the programicon to start ESS-Model.

No other files are needed for the free version. 

To use the HTML documentation feature in the registered version 
of ESS-Model you need the library MSXML.DLL, normally installed 
with Microsoft's Internet Explorer 5 (IE5) or later.

Please note that you need version 3.0 or later of this library.

You can obtain the file as part of the XML Parser package from 
the Microsoft Download Center at:

   http://www.microsoft.com/downloads/search.asp

Choose the "Keyword Search" option, then search for "MSXML".




Command line options
--------------------
ESS-Model can be controlled from the command line.

Syntax: essmodel [options] [@list] [files...]

The following options are available:
  -help       Show help for the options.
  -d[path]    Generate documentation to the path specified.
  -x[file]    Export model to xmi file.

Files can be specified with wildcards.

Examples:
  essmodel *.java subdir\*.java
  essmodel *.dpr
  essmodel myproj.dpr -dc:\myproj\doc         Parse and generate documentation

Examples of how to use in batchfiles:
  doDoc.bat
    rem Parse and generate documentation.
    essmodel MyProject.dpr -dC:\MyProject\doc
  
  doModel.bat
    rem Open essmodel with all java-files from current path and downwards.
    dir *.java /S /B > files.tmp
    essmodel @files.tmp
        

All the examples above assumes that essmodel.exe is in the current
search path. Otherwise you need to type the full path to essmodel, 
for instance c:\utils\esmodel.exe.




Diagram indicators for operations and attributes
------------------------------------------------
Italic font = Abstract
Green = Constructor
Red = Destructor
Black = Procedure  
Gray = Function
Plus-sign = Public
Minus-sign = Private
Hash-sign = Protected



Explorer and Delphi integration
-------------------------------
ESS-Model can be configured to run from the Explorer
contextmenu and from the Delphi IDE Tools menu.

From the main menu select File - Change settings.
Use the checkboxes to choose integration options.

When the shortcuts are active, ESS-Model will appear
as 'View as model diagram' in the menues.




Other info can be found at ESS-Model homepage: 

  http://www.essmodel.com

  http://www.eldean.se/essmodel





Copyright (C) 2001 by Eldean AB, Sweden. All Rights Reserved.
