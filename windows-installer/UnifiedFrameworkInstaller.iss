#ifndef InstallerVersion
  #error InstallerVersion must be supplied with /DInstallerVersion=x.y.z
#endif
#define AppVersion InstallerVersion
#ifndef PayloadDir
  #define PayloadDir "staging"
#endif

[Setup]
AppName=Instalador de Frameworks de IA
AppVersion={#AppVersion}
AppPublisher=FernandoRD
DefaultDirName={autopf}\Frameworks de IA
DisableDirPage=yes
DisableProgramGroupPage=yes
Uninstallable=no
OutputDir=output
OutputBaseFilename=Instalador-Framework-Windows-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\\BrazilianPortuguese.isl"

[Files]
Source: "{#PayloadDir}\\catalog.ini"; Flags: dontcopy
Source: "{#PayloadDir}\\*"; DestDir: "{tmp}\\frameworks"; Flags: recursesubdirs createallsubdirs ignoreversion

[Code]
var
  ProductPage: TWizardPage;
  TargetPage: TInputDirWizardPage;
  SpecialistsPage: TWizardPage;
  ProductCombo: TNewComboBox;
  PlatformCombo: TNewComboBox;
  SpecialistList: TNewCheckListBox;
  SelectAllButton, SelectNoneButton: TNewButton;
  CatalogPath: String;
  ProductIds, PlatformIds: TArrayOfString;

function CsvValues(Value: String): TArrayOfString;
var
  Item: String;
  P, I: Integer;
begin
  SetArrayLength(Result, 0);
  while Value <> '' do
  begin
    P := Pos(',', Value);
    if P = 0 then
    begin
      Item := Value;
      Value := '';
    end
    else
    begin
      Item := Copy(Value, 1, P - 1);
      Delete(Value, 1, P);
    end;
    if Item <> '' then
    begin
      I := GetArrayLength(Result);
      SetArrayLength(Result, I + 1);
      Result[I] := Item;
    end;
  end;
end;

function ProductId: String;
begin
  Result := ProductIds[ProductCombo.ItemIndex];
end;

function PlatformId: String;
begin
  Result := PlatformIds[PlatformCombo.ItemIndex];
end;

function ProductValue(Key: String): String;
begin
  Result := GetIniString('product.' + ProductId, Key, '', CatalogPath);
end;

function PlatformValue(Key: String): String;
begin
  Result := GetIniString('product.' + ProductId + '.platform.' + PlatformId, Key, '', CatalogPath);
end;

procedure FillSpecialists;
var
  Items: TArrayOfString;
  I: Integer;
begin
  SpecialistList.Items.Clear;
  Items := CsvValues(PlatformValue('specialists'));
  for I := 0 to GetArrayLength(Items) - 1 do
    SpecialistList.AddCheckBox(Items[I], '', 0, False, True, False, True, nil);
end;

procedure FillPlatforms;
var
  Items: TArrayOfString;
  I: Integer;
begin
  PlatformCombo.Items.Clear;
  Items := CsvValues(ProductValue('platforms'));
  PlatformIds := Items;
  for I := 0 to GetArrayLength(Items) - 1 do
    PlatformCombo.AddItem(GetIniString('product.' + ProductId + '.platform.' + Items[I], 'display', Items[I], CatalogPath), nil);
  if PlatformCombo.Items.Count > 0 then PlatformCombo.ItemIndex := 0;
  FillSpecialists;
end;

procedure SelectionChanged(Sender: TObject);
begin
  FillPlatforms;
end;

procedure PlatformChanged(Sender: TObject);
begin
  FillSpecialists;
end;

procedure SetAllSpecialists(Checked: Boolean);
var
  I: Integer;
begin
  for I := 0 to SpecialistList.Items.Count - 1 do SpecialistList.Checked[I] := Checked;
end;

procedure SelectAllClick(Sender: TObject);
begin
  SetAllSpecialists(True);
end;

procedure SelectNoneClick(Sender: TObject);
begin
  SetAllSpecialists(False);
end;

function SelectedAliases: String;
var
  I: Integer;
  Specialist, Alias: String;
begin
  Result := '';
  for I := 0 to SpecialistList.Items.Count - 1 do begin
    if SpecialistList.Checked[I] then begin
      Specialist := SpecialistList.Items[I];
      Alias := GetIniString('specialist.' + ProductId + '.platform.' + PlatformId + '.' + Specialist, 'alias', '', CatalogPath);
      if Alias = '' then RaiseException('Catálogo inválido: especialista sem alias: ' + Specialist);
      Result := Result + ' -' + Alias;
    end;
  end;
end;

function SelectedSpecialistsSummary: String;
var
  I: Integer;
begin
  Result := 'Nenhum';
  for I := 0 to SpecialistList.Items.Count - 1 do
    if SpecialistList.Checked[I] then begin
      if Result = 'Nenhum' then Result := SpecialistList.Items[I]
      else Result := Result + ', ' + SpecialistList.Items[I];
    end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = TargetPage.ID then begin
    if Trim(TargetPage.Values[0]) = '' then begin
      MsgBox('Escolha a pasta do projeto.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
  Result := 'Produto: ' + ProductValue('title') + NewLine +
    'Plataforma: ' + PlatformValue('display') + NewLine +
    'Pasta do projeto: ' + TargetPage.Values[0] + NewLine +
    'Especialistas: ' + SelectedSpecialistsSummary + NewLine + NewLine +
    'O instalador usará apenas o install.ps1 do pacote selecionado.';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  PackagePath, ScriptPath, Parameters: String;
  ResultCode: Integer;
begin
  if CurStep <> ssPostInstall then exit;
  if not ForceDirectories(TargetPage.Values[0]) then
    RaiseException('Não foi possível criar a pasta do projeto: ' + TargetPage.Values[0]);

  PackagePath := GetIniString('product.' + ProductId + '.platform.' + PlatformId, 'package', '', CatalogPath);
  ScriptPath := ExpandConstant('{tmp}\\frameworks\\' + PackagePath + '\\scripts\\install.ps1');
  if not FileExists(ScriptPath) then RaiseException('Instalador Windows não encontrado: ' + ScriptPath);
  Parameters := '-NoProfile -ExecutionPolicy Bypass -File ' + AddQuotes(ScriptPath) +
    ' -Target ' + AddQuotes(TargetPage.Values[0]) + ' -Apply' + SelectedAliases;
  Log('Executando apenas o instalador PowerShell selecionado: ' + ScriptPath);
  if not Exec(ExpandConstant('{sys}\\WindowsPowerShell\\v1.0\\powershell.exe'), Parameters, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    RaiseException('Não foi possível iniciar o PowerShell.')
  else if ResultCode <> 0 then
    RaiseException('A instalação falhou. Código do PowerShell: ' + IntToStr(ResultCode) + '. Consulte o log do instalador.');
end;

procedure InitializeWizard;
var
  Products: TArrayOfString;
  I: Integer;
begin
  ExtractTemporaryFile('catalog.ini');
  CatalogPath := ExpandConstant('{tmp}\\catalog.ini');
  ProductPage := CreateCustomPage(wpWelcome, 'Escolha o framework', 'Selecione o produto e a plataforma de IA.');
  with TNewStaticText.Create(ProductPage) do begin
    Parent := ProductPage.Surface; Caption := 'Produto:';
    SetBounds(ScaleX(0), ScaleY(8), ScaleX(520), ScaleY(20));
  end;
  ProductCombo := TNewComboBox.Create(ProductPage);
  ProductCombo.Parent := ProductPage.Surface;
  ProductCombo.SetBounds(ScaleX(0), ScaleY(28), ScaleX(520), ScaleY(24));
  ProductCombo.Style := csDropDownList;
  ProductCombo.OnChange := @SelectionChanged;
  with TNewStaticText.Create(ProductPage) do begin
    Parent := ProductPage.Surface; Caption := 'Plataforma:';
    SetBounds(ScaleX(0), ScaleY(66), ScaleX(520), ScaleY(20));
  end;
  PlatformCombo := TNewComboBox.Create(ProductPage);
  PlatformCombo.Parent := ProductPage.Surface;
  PlatformCombo.SetBounds(ScaleX(0), ScaleY(86), ScaleX(520), ScaleY(24));
  PlatformCombo.Style := csDropDownList;
  PlatformCombo.OnChange := @PlatformChanged;

  TargetPage := CreateInputDirPage(ProductPage.ID, 'Pasta do projeto', 'Escolha onde instalar',
    'Os arquivos serão instalados no projeto selecionado. A pasta será criada se ainda não existir.');
  TargetPage.Add('Pasta do projeto:', False);

  SpecialistsPage := CreateCustomPage(TargetPage.ID, 'Especialistas opcionais', 'Marque os especialistas que deseja instalar.');
  SpecialistList := TNewCheckListBox.Create(SpecialistsPage);
  SpecialistList.Parent := SpecialistsPage.Surface;
  SpecialistList.SetBounds(ScaleX(0), ScaleY(8), ScaleX(520), ScaleY(180));
  SelectAllButton := TNewButton.Create(SpecialistsPage);
  SelectAllButton.Parent := SpecialistsPage.Surface;
  SelectAllButton.Caption := 'Selecionar todos';
  SelectAllButton.SetBounds(ScaleX(0), ScaleY(198), ScaleX(120), ScaleY(28));
  SelectAllButton.OnClick := @SelectAllClick;
  SelectNoneButton := TNewButton.Create(SpecialistsPage);
  SelectNoneButton.Parent := SpecialistsPage.Surface;
  SelectNoneButton.Caption := 'Nenhum';
  SelectNoneButton.SetBounds(ScaleX(130), ScaleY(198), ScaleX(100), ScaleY(28));
  SelectNoneButton.OnClick := @SelectNoneClick;

  Products := CsvValues(GetIniString('products', 'ids', '', CatalogPath));
  ProductIds := Products;
  for I := 0 to GetArrayLength(Products) - 1 do
    ProductCombo.AddItem(GetIniString('product.' + Products[I], 'title', Products[I], CatalogPath), nil);
  if ProductCombo.Items.Count = 0 then RaiseException('Catálogo de produtos vazio.');
  ProductCombo.ItemIndex := 0;
  FillPlatforms;
end;
