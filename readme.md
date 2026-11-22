KIM Tape to TXT

Converts binary memory dumps of Micro Ade or CW Moser Assm/TED editor to DOS text files.

Hans Otten, May 2019 Version 1.3
 
Applicable license: Creative Commons Naamsvermelding-Niet Commercieel 2.5 Nederland
See http://creativecommons.org/licenses/by-nc/2.5/nl/

KIM Tape to TXT PAPER is a utility to convert between binary format of a KIM-1 tape dump to a DOS text file.
The KIM tape dump is a binary file and is just a dump of part of the memory of the KIM-1.
 
By using the tape write routine in the KIM-1 one can write an audio file on cassette.

When this audio file is captured on a PC as WAV file (22K, mono) this can be converted back to a binary memory dump with ED's Utility KIMTape (see the  retro website.

This binary file can be a program or a text file as used in editors like Micro Ade or CW Assm/TED.
These text files can be converted to DOS text files with this utility.

First open the binary file
If this is recognized as  Micro Ade or CW Moser format, the Save as text file can be used. 

Full source for Freepascal included, no Windows dependencies. Compiled on 64 bits Windows 10.

Use Freepascal Lazarus to build the application yourself.

Note on detection of assembler editor type.

1. Micro Ade file must start with CR: when present this is Micro Ade
   
      line nr follows 2 byte
      line ends with $0D
      file ends with $40
      
2. Assm/Ted by CW Moser  starts with line number $10 $00

    end of line is high bit set
    
   There may be rare situations that a file starts with a $0D or a different line nr. You can force CW Mose detection by changing this to a sequence of $10 $00 $0D and if necessary blanks $20 to make it consistent. 

If doubts: use an editor thats shows the file in hex (Ultra Edit, or the free Notepad ++,  Text editor PRO) and stuy the tape file.

Methods to get the binary file out of a Junior or KIM-1.

Read the record tape into a binary with Ed's DX-Forth and Utilities Page (http://dxforth.mirrors.minimaltype.com/) KIMTAPE conversion. It is MS-DOS and runs fine in VDOS (https://www.vdos.info/) or DOsbox (slow).
Make a note of start address as shown by KIMTAPE.

Non-printing ASCII charactyers are filtered out of the resulting text file