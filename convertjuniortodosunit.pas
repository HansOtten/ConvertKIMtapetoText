unit convertjuniortodosunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  StdCtrls, LCLType,LCLIntf, Process ;

type

  { TMainform }

  TMainform = class(TForm)
    ManMenu: TMainMenu;
    HelpMenu: TMenuItem;
    InfoMemo: TMemo;
    MenuAbout: TMenuItem;
    MenuFile: TMenuItem;
    MenuExit: TMenuItem;
    MenuHelp: TMenuItem;
    MenuOpenFile: TMenuItem;
    MenuConvert: TMenuItem;
    OpenJuniorFile: TOpenDialog;
    SavetoASMfile: TSaveDialog;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure MenuConvertClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuHelpClick(Sender: TObject);

    procedure MenuOpenFileClick(Sender: TObject);
  private

  public

  end;


const
  AppName    = 'ConvertKIMtapeToTxt' ;
  AppVersion = 'ConvertKIMtapeToTxt V1.4 (November 2026)' ;
  AppAuthor  = 'Hans Otten, http://retro.hansotten.nl' ;
var
  Mainform         : TMainform;
  JuniorFilename,
  ASMFilename      : string ;
  JuniorFile       : file of Byte ;
  ASMFile          : text ;
  JuniorFileIsOpen : boolean ;
  ASMFileIsOpen    : boolean ;
  IsMicroAde       : boolean ;
  IsCWMoser        : boolean ;
  Juniorbuffer     : array[0..65535] of byte ;
  buffercount      : integer ;


implementation

{$R *.lfm}

{ TMainform }

procedure Init ;

begin

  if JuniorFileIsOpen
    then
      begin
         CloseFile(JuniorFile) ;
         JuniorFileIsOpen := false ;
      end;
  if ASMFileIsOpen
  then
    begin
       CloseFile(ASMFile) ;
       ASMFileIsOpen := false ;
    end;
    IsMicroAde := false ;
    IsCWMoser  := false ;

end;



procedure TMainform.MenuOpenFileClick(Sender: TObject);



begin
  Init ;
  if OpenJuniorFile.Execute
    then
      begin
         JuniorFilename := OpenJuniorFile.FileName ;
         try
           AssignFile(JuniorFile, JuniorFileName) ;
           reset(JuniorFile) ;
           JuniorFileIsOpen := true ;
         except
            on E: EInOutError do
              begin
                ShowMessage ( 'Opening file ' + ExtractFileName(Juniorfilename) + ' failed') ;
                JuniorFileIsOpen := false ;
              end;
         end;
      end;
  (* check if this is an Micro Ade or CW Moser text file, read file into buffer *)
  buffercount := 0 ;
  if JuniorFileIsOpen then
    begin
      while not eof(JuniorFile) do
        begin
          read(JuniorFile, Juniorbuffer[buffercount]) ;
          buffercount := buffercount + 1 ;
        end;
      CloseFile(JuniorFile) ;
      JuniorFileIsOpen := false ;

      (* check if this is an Micor Ade or CW Moser assembler file *)
      (* First try Micro Ade must start with CR *)
      (* CW Moser starts with line number 10 00 *)

      if JuniorBuffer[0] = $0D
        then
          begin
            IsMicroAde := true  ;
            Infomemo.lines.add('Tape file  ' + ExtractFileName(Juniorfilename) + ', Size =' + inttostr(buffercount) + ' is a Micro Ade text file' );
          end
      else if (JuniorBuffer[0] = $10) and (JuniorBuffer[1] = $00) then
        begin
          IsCWMoser := true  ;
          Infomemo.lines.add('Tape file = ' + ExtractFileName(Juniorfilename) + ', Size =' + inttostr(buffercount + 1)  + ' is a CW Moser text file' );
        end
      else
       Infomemo.lines.add('Tape file = ' + ExtractFileName(Juniorfilename) + ', Size =' + inttostr(buffercount + 1) + ' not a text file' );
    end;
end;


procedure TMainform.MenuAboutClick(Sender: TObject);
begin
   ShowMessage('Convert KIM-1 cassette dumps to text file ' + AppVersion)  ;
end;

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
      ch := JuniorBuffer[PosInbuffer] ;
      if ch = $40 then
        begin
           MoreinFile := false ;
           if assemblerline <> ''
             then
               writeln(ASMFile, assemblerline) ;
        end

      else if (ch = $0D) then
        begin
          PosInBuffer := PosInBuffer + 3 ;
          writeln(ASMFile, assemblerline) ;
          assemblerline := '' ;
        end
      else
         begin
          ch := JuniorBuffer[PosInbuffer] ;
          if ch > $1F
              then
                assemblerline := assemblerline + chr(ch) ;
          PosInBuffer := PosInBuffer + 1 ;
        end  ;

     end ;


end;

procedure ConvertCWMOser ;

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
      ch := Juniorbuffer[PosInbuffer] ;
      if ch > $7F
        then
          begin
            ch := ch and $7F ;
            if ch > $1F
              then
                assemblerline := assemblerline + chr(ch) ;
            writeln(ASMfile, assemblerline) ;
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


procedure TMainform.MenuConvertClick(Sender: TObject);
begin



  if not (isMicroAde or IsCWMOser)
    then
      ShowMessage('Not a text file')
  else if SavetoASMfile.execute
    then
      begin
        ASMFilename := SaveToASMfile.filename ;
        AssignFile(ASMFile, ASMFilename) ;
        try
          rewrite(ASMFile) ;
        except
          on E: EInOutError do
            begin
              ShowMessage('Error opening text file' + E.Message) ;
              exit ;
            end ;
        end ;
        Infomemo.lines.add('Text file created ' + ASMFilename + ', conversion started' );
        if IsCWMoser or IsMicroAde
          then
             begin
              (* open assember output file *)
               if isMicroAde
                 then
                   ConvertMicroAde
                 else if IsCWMoser
                   then
                     ConvertCWMoser ;
               (* Close text file *)
               CloseFile(ASMFile ) ;
               ASMFileIsOpen := false ;
               Infomemo.lines.add('Text file converted' );
               end;
      end;

end;

procedure TMainform.FormActivate(Sender: TObject);
begin
  Init ;
  InfoMemo.Clear ;
end;

procedure TMainform.FormCreate(Sender: TObject);
begin

end;



procedure TMainform.MenuExitClick(Sender: TObject);
begin
  Close ;
end;

procedure TMainform.MenuHelpClick(Sender: TObject);
var
  f : TForm ;
  m : TMemo ;
begin
  f := TForm.CreateNew(Self) ;
  try
    f.Caption := AppName + ' help' ;
    f.Position := poOwnerFormCenter ;
    f.Width := 620 ;
    f.Height := 520 ;
    m := TMemo.Create(f) ;
    m.Parent := f ;
    m.Align := alClient ;
    m.ReadOnly := true ;
    m.ScrollBars := ssVertical ;
    m.Lines.Text :=
      AppVersion + LineEnding +
      LineEnding +
      'KIM Tape to TXT PAPER is a utility to convert between binary format of a KIM-1 tape dump to a DOS text file.' + LineEnding +
      'The KIM tape dump is a binary file and is just a dump of part of the memory of the KIM-1.' + LineEnding +
      LineEnding +
      'By using the tape write routine in the KIM-1 one can write an audio file on cassette.' + LineEnding +
      LineEnding +
      'When this audio file is captured on a PC as WAV file (22K, mono) this can be converted back ' + LineEnding +
      'to a binary memory dump with KIMTAPE ' + LineEnding +
      LineEnding +
      'This binary file can be a program or a text file as used in editors like Micro Ade or CW Assm/TED.' + LineEnding +
      'These text files can be converted to DOS text files with this utility.' + LineEnding +
      LineEnding +
      'First open the binary file' + LineEnding +
      'If this is recognized as  Micro Ade or CW Moser format, the Save as text file can be used.' + LineEnding +
      LineEnding +
      'Full source for Freepascal included, no Windows dependencies. Compiled on 64 bits Windows 10.' + LineEnding +
      LineEnding +
      'Use Freepascal Lazarus to build the application yourself.' + LineEnding +
      LineEnding +
      'Note on detection of assembler editor type.' + LineEnding +
      LineEnding +
      '1. Micro Ade file must start with CR: when present this is Micro Ade' + LineEnding +
      '      line nr follows 2 byte' + LineEnding +
      '      line ends with $0D' + LineEnding +
      '      file ends with $40' + LineEnding +
      '2. Assm/Ted by CW Moser  starts with line number $10 $00' + LineEnding +
      '    end of line is high bit set' + LineEnding +
      '     There may be rare situations that a file starts with a $0D or a different line nr.' + LineEnding +
      '	 You can force CW Moser detection by changing this to a sequence of $10 $00 $0D ' + LineEnding +
      '	 and if necessary blanks $20 to make it consistent. ' + LineEnding +
      LineEnding +
      'If in doubt: use an editor thats shows the file in hex (Ultra Edit, or the free Notepad ++ ir BinHexEditor.' + LineEnding +
      LineEnding +
      'Methods to get the binary file out of a Junior or KIM-1.' + LineEnding +
      'Read the record tape into a binary with KIMTAPE. Make a note of start address as shown by KIMTAPE.' + LineEnding +
      LineEnding +
      'Non-printing ASCII characters are filtered out of the resulting text file.' + LineEnding ;
      f.ShowModal ;
  finally
    f.Free ;
  end ;
end;

end.

