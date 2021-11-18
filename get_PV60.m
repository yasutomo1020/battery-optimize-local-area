function PVS2 = get_PV60(workbookFile, sheetName, dataLines)
%IMPORTFILE スプレッドシートからデータをインポート
%  PVS2 = IMPORTFILE(FILE) は、FILE という名前の Microsoft Excel スプレッドシート
%  ファイルの最初のワークシートからデータを読み取ります。  数値データを返します。
%
%  PVS2 = IMPORTFILE(FILE, SHEET) は、指定されたワークシートから読み取ります。
%
%  PVS2 = IMPORTFILE(FILE, SHEET, DATALINES)
%  は、指定されたワークシートから指定された行区間を読み取ります。DATALINES
%  を正の整数スカラーとして指定するか、行区間が不連続の場合は正の整数スカラーからなる N 行 2 列の配列として指定します。
%
%  例:
%  PVS2 = importfile("C:\Users\PowerSystem\MATLAB Drive\EV_Battery_local_model\PV導入量.xlsx", "Tohoku", [39, 39]);
%
%  READTABLE も参照してください。
%
% MATLAB からの自動生成日: 2021/11/11 14:52:58

%% 入力の取り扱い

% シートが指定されていない場合、最初のシートを読み取ります
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end

% 行の始点と終点が指定されていない場合、既定値を定義します
if nargin <= 2
    dataLines = [39, 39];
end

%% インポート オプションの設定およびデータのインポート
opts = spreadsheetImportOptions("NumVariables", 24);

% シートと範囲の指定
opts.Sheet = sheetName;
opts.DataRange = "B" + dataLines(1, 1) + ":Y" + dataLines(1, 2);

% 列名と型の指定
opts.VariableNames = ["PV", "VarName3", "VarName4", "VarName5", "VarName6", "VarName7", "VarName8", "VarName9", "VarName10", "VarName11", "VarName12", "VarName13", "VarName14", "VarName15", "VarName16", "VarName17", "VarName18", "VarName19", "VarName20", "VarName21", "VarName22", "VarName23", "VarName24", "VarName25"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% データのインポート
PVS2 = readtable(workbookFile, opts, "UseExcel", false);

for idx = 2:size(dataLines, 1)
    opts.DataRange = "B" + dataLines(idx, 1) + ":Y" + dataLines(idx, 2);
    tb = readtable(workbookFile, opts, "UseExcel", false);
    PVS2 = [PVS2; tb]; %#ok<AGROW>
end

%% 出力型への変換
PVS2 = table2array(PVS2);
end