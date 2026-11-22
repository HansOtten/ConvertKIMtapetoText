program ConvCWMAtotxt;


{ Last update Hans Otten, 2 october 2022 }

{

  MIT License

  Copyright (c) 2019, 2022 Hans Otten

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
 }


{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  sysutils, Classes ;

const
  VersionInfo = 'Convert CW Moser or Micro Ade tape file to text V1.1, Hans Otten 2022' ;

var
  inFile           : file of Byte ;
  outFile          : text ;
  IsMicroAde       : boolean ;
  IsCWMoser        : boolean ;
  buffer           : array[0..65535] of byte ;
  buffercount      : integer ;
  cnt              : integer ;
  yesno            : char ;
  ch               : byte ;
procedure ShowHelp ;
begin
  writeln('Syntax: CVMACW <CW Moser or Micro Ade tape file> <text file>') ;
  writeln ;
end ;


procedure ConvertMicroAde ;
(* Micro Ade source file layout *)
(* $0D | n n | 0 to 64 databytes |  ... |n n | $40 | $0D *)
(* n n is line number, ignored further *)
(* empty line possible *)
var
  PosInBuffer   : integer ;
  assemblerline : string ;
  ch            : byte ;
  MoreInFile    : boolean ;

begin
  PosInbuffer := 3 ;
  assemblerline := '' ;
  ch := 0 ;
  MoreInfile := true ;
  while MoreinFile do
    begin
      ch := Buffer[PosInbuffer] ;
      if ch = $40 then
        begin
           MoreinFile := false ;
           if assemblerline <> ''
             then
               writeln(outFile, assemblerline) ;
        end

      else if (ch = $0D) then
        begin
          PosInBuffer := PosInBuffer + 3 ;
          writeln(outFile, assemblerline) ;
          assemblerline := '' ;
        end
      else
         begin
          ch := Buffer[PosInbuffer] ;
          if ch > $1F
              then
                assemblerline := assemblerline + chr(ch) ;
          PosInBuffer := PosInBuffer + 1 ;
        end  ;
     end ;
end;

procedure ConvertCWMoser ;
(* CW Moser file layout *)
(* repeated n n | 0 or more databytes | last databyte in line high bit set *)
(* empty lines not possible *)
var
  PosInBuffer   : integer  ;
  assemblerline : string ;
  ch            : byte ;

begin
  PosInbuffer := 2 ;
  assemblerline := '' ;
  while PosInbuffer <  buffercount do
    begin
      ch := buffer[PosInbuffer] ;
      if ch > $7F
        then
          begin
            ch := ch and $7F ;
            if ch > $1F
              then
                assemblerline := assemblerline + chr(ch) ;
            writeln(outfile, assemblerline) ;
            PosInbuffer := PosInBuffer + 3 ;
            assemblerline := '' ;
          end
      else
        begin
          if ch > $1F
            then
              assemblerline := assemblerline + chr(ch) ;
          PosInbuffer := PosInBuffer + 1 ;
         end  ;
     end ;
end;

{$R *.res}

begin
  IsMicroAde := false ;
  IsCWMoser  := false ;
  writeln(VersionInfo) ;
  if Paramcount < 2
    then
      begin
        ShowHelp ;
        Exit ;
      end ;
  AssignFile(InFile, paramstr(1)) ;
  {$i-}
  reset(InFile) ;
  {$i+}
  if IOResult <> 0
    then
      begin
        writeln('Opening file ', paramstr(1), ' failed') ;
        exit ;
      end;

  AssignFile(OutFile, paramstr(2)) ;
  {$i-}
  rewrite(OutFile) ;
  {$i+}
  if IOResult <> 0
    then
      begin
        writeln('Opening file ', paramstr(2), ' failed') ;
        exit ;
      end;

  buffercount := 0 ;
  write('Checking .') ;
  while not eof(inFile) do
    begin
      read(InFile, buffer[buffercount]) ;
      if (buffercount mod 1000) = 0
        then write('.') ;
      buffercount := buffercount + 1 ;
    end;
  writeln ;
  CloseFile(InFile) ;
  (* check if this is an Micro Ade or CW Moser assembler file *)
  (* First try Micro Ade must start with CR *)
  (* CW Moser starts with line number 10 00 *)

  write('Tape file ', paramstr(1), ' Size', buffercount, ' bytes') ;
  if buffer[0] = $0D
    then
      begin
        IsMicroAde := true  ;
        write(' is a Micro Ade text file' );
      end
  else if (Buffer[0] = $10) and (Buffer[1] = $00)
    then
      begin
        IsCWMoser := true  ;
        write(' is a CW Moser text file' );
      end
  else
    begin
      write('File starts with ') ;
        for cnt := 0 to 40 do
          begin
            ch := buffer[cnt] and $7F ;
            if (ch > $20)
              then
                write(chr(ch))
            else if ch = $0D
              then
                write('CR')
            else
                write('.') ;
          end;
      writeln ;
      write('CWMoser [Y/n]?') ;
      readln(yesno) ;
      if (yesno = 'y') or (yesno = 'Y')
        then
          IsCWMoser := true
      else
        begin
          write('MICRO ADE [Y/n]?') ;
          readln(yesno) ;
          if (yesno = 'y') or (yesno = 'Y')
            then
              IsMicroAde := true
            else
              begin
                Closefile(outfile) ;
                DeleteFile(paramstr(2)) ;
                writeln(paramstr(1), ' is not a CW Moser Or Micro Ade  file, no text file created' );
                exit
              end ;
        end ;
    end;

  if IsMicroAde
    then
      ConvertMicroAde
  else if IsCWMoser
    then
      ConvertCWMoser  ;
  writeln(' converted to text file ',paramstr(2) ) ;
  Close(outfile)
end.

