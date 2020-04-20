unit Backupper;

{$mode delphi}

interface

uses ExtCtrls;

procedure createBackupFile(path: string; onTableEdit: boolean=false);
procedure SessionBackupFileCreate(sender: TObject=nil);
procedure SessionBackupFileRemove(path: string);
function SessionBackupFileExists(path: string; out backupPath: string): boolean;

var
  BackupperUseSubdirectory: boolean;

  BackupperBackupOnSave: boolean;
  BackupperBackupFileCount: integer;

  BackupperSessionBackup: boolean;

  BackupperFileHistory: boolean;
  BackupperFileHistoryInterval: integer;

  BackupperDelayTimer: TTimer;

implementation

uses MainUnit, OpenSave, fileaccess, SysUtils, Controls, Dialogs, LazFileUtils;

resourcestring
  rsBackupFileDetected = 'Backup file detected. Do you want to load the backup file?';

var
  BackupperFileHistoryLastSave: qword=0;

function getProjectNameFromMainFormDialogs: string; inline;
begin
  if MainForm.savedialog1.FileName='' then result := MainForm.opendialog1.FileName else result := MainForm.savedialog1.FileName;
  // savedialog1.FileName has bigger priority than opendialog1.FileName
end;

function appendSubDirToPath(path, subdir: string): string; inline;
begin
  result := ExtractFileDir(path)+DirectorySeparator+subdir+DirectorySeparator+ExtractFileName(path)
end;

procedure renameBackupFile(oldname, newname: string; utf8: boolean); inline;
begin
  if utf8 then renamefileUTF8(oldname,newname) else renamefile(oldname,newname);
end;

procedure removeFile(path: string; utf8: boolean); inline;
begin
  if            (utf8 and FileExistsUTF8(path)) then deletefileUTF8(path)
  else if ((not utf8) and     FileExists(path)) then     deletefile(path);
end;

function createDirectory(path: string; utf8: boolean): boolean;
begin
  result := true;
  path := ExtractFileDir(path);
  if (utf8 and (not DirectoryExistsUTF8(path))) or ((not utf8) and (not DirectoryExists(path))) then
  begin
    if (utf8 and (not CreateDirUTF8(path))) or ((not utf8) and (not CreateDir(path))) then
    begin
      //failure in creating the dir
      {$IFDEF windows}
      MakePathAccessible(path);
      {$ENDIF}
      if (utf8 and (not CreateDirUTF8(path))) or ((not utf8) and (not CreateDir(path))) then result:=false;
    end;
  end;
end;

procedure createBackupFile(path: string; onTableEdit: boolean=false);
var s: string;
    utf8,edited: boolean;
    i: integer;
begin
  edited := MainForm.editedsincelastsave; // because savetable sets it to false
  utf8 := DirectoryExistsUTF8(ExtractFileDir(path));

  if BackupperUseSubdirectory then path := appendSubDirToPath(path, 'backup');
  if not createDirectory(path, utf8) then exit;

  if onTableEdit then // triggered by modifying the table
  begin
    if BackupperFileHistory and ((GetTickCount64-BackupperFileHistoryLastSave)>BackupperFileHistoryInterval*60*1000) then
    begin
      BackupperFileHistoryLastSave := GetTickCount64;
      s := appendSubDirToPath(path, ExtractFileNameOnly(path)+'-version-history');
      if createDirectory(s, utf8) then savetable(ChangeFileExt(s,'.'+FormatDateTime('yyyy-mm-dd hh-nn-ss', Now)+'.CT'));
    end;
    path := ChangeFileExt(path,'.~CT');
  end
  else
  begin   // triggered by manual save (delete oldest, rename 1->2 2->3)
    removeFile(ChangeFileExt(path,'.'+IntToStr(BackupperBackupFileCount)+'.CT'), utf8);

    for i := BackupperBackupFileCount-1 downto 1 do
      renameBackupFile(ChangeFileExt(path,'.'+IntToStr(i)+'.CT'), ChangeFileExt(path,'.'+IntToStr(i+1)+'.CT'), utf8);

    path := ChangeFileExt(path,'.1.CT');
  end;

  savetable(path);

  MainForm.fEditedSinceLastSave := edited;
end;

procedure SessionBackupFileCreate();
var path: string;
begin
  BackupperDelayTimer.Enabled := false;

  path := getProjectNameFromMainFormDialogs;
  if (path='') or (uppercase(extractfileext(path))<>'.CT') then exit;

  createBackupFile(path, true);
end;

procedure SessionBackupFileRemove(path: string);
var utf8: boolean;
begin
  if (path='') or (uppercase(extractfileext(path))<>'.CT') then exit;

  path := ChangeFileExt(path,'.~CT');
  utf8 := DirectoryExistsUTF8(ExtractFileDir(path));

  if BackupperUseSubdirectory then path := appendSubDirToPath(path, 'backup');

  removeFile(path, utf8);
end;

function SessionBackupFileExists(path: string; out backupPath: string): boolean;
var app: word;
begin
  if BackupperUseSubdirectory then path := appendSubDirToPath(path, 'backup');
  path := ChangeFileExt(path,'.~CT');

  if FileExists(path) or FileExistsUTF8(path) then
  begin
    backupPath := path;
    app := messagedlg(rsBackupFileDetected, mtConfirmation, mbYesNo, 0);
    result := (app=mrYes);
  end
  else
    result := false;
end;

end.

