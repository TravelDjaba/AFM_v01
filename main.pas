unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ToolWin, Vcl.StdCtrls, Vcl.ExtCtrls,
  libserialport, CustomSerialPort, Vcl.Buttons, uSGraph2, MMatrix, uIGraph,
  sTrackBar;

type
    TWorkMode = (wmodStop=0, wmodMonitor=1, wmodScan=2);

type
  TAFMmain = class(TForm)
    StatusBar1: TStatusBar;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    lblStatusConnection: TLabel;
    btnConnect: TButton;
    lboxLog: TListBox;
    GroupBox2: TGroupBox;
    btnMonitoring: TSpeedButton;
    btnScan: TSpeedButton;
    btnStop: TSpeedButton;
    pnlHGraph: TPanel;
    Timer1: TTimer;
    edtCmd: TEdit;
    trbMonInterval: TTrackBar;
    Timer250: TTimer;
    pnlTop: TPanel;
    trbScanInterval: TTrackBar;
    Label2: TLabel;
    Label3: TLabel;
    pnlMap: TPanel;
    Panel1: TPanel;
    pnlLeft: TPanel;
    rgMapX: TRadioGroup;
    Splitter1: TSplitter;
    rangeContrast: TsRangeSelector;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnMonitoringClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure edtCmdKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer250Timer(Sender: TObject);
    procedure pnlMapResize(Sender: TObject);
    procedure rangeContrastChange(Sender: TObject);

  private
    CPort:TCustomSerialPort;
    dataCurve:TCurve;
    SGraph: TSGraph2;
    IGraph: TIGraph;

    rawData:TMMatrix<Word>;
    imgData:TMMatrix<Byte>;
    minI, maxI: Word;

    canChange:Boolean;

    mapSizeX, mapSizeY:Integer;

    prevMonI, prevScanI:Integer;

    scanPtX, scanPtY:Integer;

    procedure Log(s:string);
    procedure OnCPortOpen(Sender:TObject);
    procedure OnCPortClose(Sender:TObject);
    procedure OnPortData( cmd:AnsiString);

    procedure FindPorts;
    procedure RescaleGraph(vmin, vmax:integer);
    procedure setDynamicGraph;


  public
    workMode:TWorkMode;
  end;

var
  AFMmain: TAFMmain;



implementation

uses System.Math;

{$R *.dfm}

var incdata:AnsiString='';
    idx:Integer=0;

    MaxPoints,ScrollPoints:Integer;




procedure TAFMmain.btnConnectClick(Sender: TObject);
var i, len:Integer;
    answ:AnsiString;
begin

  if CPort.Connected then
    begin
    CPort.writeStrAnsw('MOD STP');
    CPort.Close;
    end
  else
    begin
    lboxLog.Items.Clear;
    FindPorts;
    len:=Length(CPort.PortList);

    if len>0 then
      begin
      for i := 0 to len-1 do
       if CPort.PortList[i].transport_type=SP_TRANSPORT_USB then
       if AnsiPos('Adafruit ItsyBitsy',  CPort.PortList[i].usb_product )>0 then
         begin
          CPort.PortName:=CPort.PortList[i].name;
          if CPort.Open then
           begin
           CPort.flush;
           answ:= CPort.writeStrAnsw('LOG IN');
           if answ='AFM micro' then
            begin
            CPort.writeStrAnsw('MOD STP');
            CPort.flush;
            Break;
            end
           else
            CPort.Close;

           end;
         end;

      end;
    end;
end;

procedure TAFMmain.btnMonitoringClick(Sender: TObject);
var answ:AnsiString;
begin
answ:=CPort.writeStrAnsw('MOD MON', true);
if answ='MOD MON' then
  begin
  workMode:=wmodMonitor;
  setDynamicGraph;


//  Timer1.Enabled:=True;
  end;
//  Log('>> '+answ);
end;

procedure TAFMmain.btnScanClick(Sender: TObject);
var answ:AnsiString;
begin

  case rgMapX.ItemIndex of
    0:mapSizeX:=256;
    1:mapSizeX:=512;
    2:mapSizeX:=1024;
    3:mapSizeX:=2048;
    4:mapSizeX:=4096;
    5:mapSizeX:=32;
  end;

  mapSizeY:=mapSizeX;

//if (mapSizeX<>rawData.Width) or (mapSizeY<>rawData.Height) then
  begin
    rawData.Free;
    rawData:=TMMatrix<Word>.Create(mapSizeX,mapSizeY);
    rawData.FillValue(0);

    imgData.Free;
    imgData:=TMMatrix<Byte>.Create(mapSizeX,mapSizeY);
    imgData.FillValue(0);

  end;

  IGraph.SetSize(mapSizeX, mapSizeY);
  IGraph.Clear;

  SGraph.DelCurve('1');
//  SGraph.DelCurves;
  dataCurve:=SGraph.AddCurve('1', clRed, mapSizeX);
  SGraph.SetLimitsX(0, mapSizeX-1);

  SGraph.ResetTail(dataCurve);
  SGraph.SetMode(gmStatic);

  SGraph.CalcResize;


 if CPort.Connected then
      // The precision value forces 0 padding to the desired size
  begin
  CPort.writeStrAnsw( Format('MAPX %.4d', [mapSizeX]));
  CPort.writeStrAnsw( Format('MAPY %.4d', [mapSizeY]));


  answ:=CPort.writeStrAnsw('MOD SCN', true);
  if answ='MOD SCN' then
    workMode:=wmodScan;

  end;
 // Log('>> '+answ);
end;

procedure TAFMmain.btnStopClick(Sender: TObject);
var answ:AnsiString;
begin
answ:=CPort.writeStrAnsw('MOD STP', true);
answ:=CPort.writeStrAnsw('MOD STP', true);
if answ='MOD STP' then
  begin
  workMode:=wmodStop;

//  Timer1.Enabled:=False;
  end;

//  Log('>> '+answ);

end;



procedure TAFMmain.edtCmdKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if Key=VK_RETURN then
  begin
    CPort.writeStrAnsw(edtCmd.Text, true);
  end;
end;

procedure TAFMmain.FindPorts;
var i, cnt:Integer;

begin
with CPort do
  begin
  cnt:=getPortList;

  if cnt>0 then
    for i := 0 to cnt-1 do
    begin
      Log(Format('Port: %s', [PortList[i].name]));
      Log(Format('Description: %s', [PortList[i].description]));

      if PortList[i].transport_type=SP_TRANSPORT_NATIVE then
        Log('Type: Native')
      else
      if PortList[i].transport_type=SP_TRANSPORT_USB then
        begin
        Log('Type: USB');
        Log(Format('Manufacturer: %s', [PortList[i].usb_manufacturer]));
        Log(Format('Product: %s', [PortList[i].usb_product]));
        Log(Format('Serial: %s', [PortList[i].usb_serial]));

        Log(Format('VID: %4x PID: %4x', [PortList[i].usb_vid, PortList[i].usb_pid]));
        Log(Format('USB bus: %d USB address: %d', [PortList[i].usb_bus, PortList[i].usb_address]));
        end
      else
      if PortList[i].transport_type=SP_TRANSPORT_BLUETOOTH then
        begin
          Log('Type: Bluetooth');
          Log(Format('MAC: %s', [PortList[i].bluetooth_address]));
        end;
    Log('');
    end;
  end;
end;

procedure TAFMmain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CPort.Connected then
    begin
    CPort.writeStrAnsw('MOD STP');
    CPort.Close;
    end
end;

procedure TAFMmain.FormCreate(Sender: TObject);
begin
  CPort:=TCustomSerialPort.Create(Self);
  CPort.OnOpen:=OnCPortOpen;
  CPort.OnClose:=OnCPortClose;
  CPort.OnRXdata:=OnPortData;
  CPort.vLog:=Log;
  CPort.vLogErr:=Log;

  IGraph:=TIGraph.CreateOn(pnlMap);

  SGraph:=TSGraph2.CreateOn(pnlHGraph);
  SGraph.SetLimitsY(0,4095);

  workMode:=wmodStop;

  rawData:=TMMatrix<Word>.Create(256,256);
  imgData:=TMMatrix<Byte>.Create(256,256);

  canChange:=False;

end;

procedure TAFMmain.FormDestroy(Sender: TObject);
begin
  rawData.Free;
  imgData.Free;

  CPort.Free;
  SGraph.Free;
  IGraph.Free;
end;

procedure TAFMmain.FormShow(Sender: TObject);
begin
  OnCPortClose(Self);
  IGraph.SetSize(256,256);
  IGraph.Clear;

  canChange:=True;

end;

procedure TAFMmain.Log(s: string);
begin
  lboxLog.Items.Add(s);
end;

procedure TAFMmain.OnCPortClose(Sender: TObject);
begin
   lblStatusConnection.Caption:='Disconnected';
   btnConnect.Caption:='Connect';
end;

procedure TAFMmain.OnCPortOpen(Sender: TObject);
begin
   lblStatusConnection.Caption:='Connected';
   btnConnect.Caption:='Disconnect';
end;

procedure TAFMmain.OnPortData( cmd:AnsiString);
var val:Integer;
begin

  case workMode of
    wmodStop: ;
    wmodMonitor:
            begin
              val:=StrToUIntDef(cmd, 99999);
              if val<>99999 then
              SGraph.AddDynamicValue(val, dataCurve);
            end;
    wmodScan:
            begin
              if (cmd[1]>='0') and (cmd[1]<='9') then
              begin
                val:=StrToUIntDef(cmd, 0);

            //    if (scanPtX<mapSizeX) and (scanPtY<mapSizeY) then
                rawData[scanPtX, scanPtY]:=val;

                SGraph.AddStaticValue(scanPtX, val, dataCurve);

                Inc(scanPtX);

              end
              else
              if AnsiPos('SCN', cmd)=1 then
              //start scanning
              begin
               scanPtX:=0;
               scanPtY:=0;
               StatusBar1.Panels[1].Text:='Started';
              end
              else
              if AnsiPos('LN', cmd)=1 then
              //start new line
              begin
                 SGraph.ResetTail(dataCurve);
                 scanPtX:=0;
                 StatusBar1.Panels[1].Text:=Format('NewLine [%d] ', [scanPtY]);

              end
              else
              if AnsiPos('EL', cmd)=1 then
              //finish line
              begin
                 StatusBar1.Panels[1].Text:=Format('EndLine [%d] ', [scanPtY]);
                 inc(scanPtY);
               //update image

               RescaleGraph(minI, maxI);
               IGraph.LoadData(imgData);
               IGraph.RepaintGraph;

              end
              else
              if AnsiPos('FIN', cmd)=1 then
              //finish scanning
              begin

               StatusBar1.Panels[1].Text:='Finish';

              end;


            end;
  end;

//  Memo1.Text:=Memo1.Text+String(data);

end;



procedure TAFMmain.pnlMapResize(Sender: TObject);
begin
pnlMap.Width:=pnlMap.Height;
end;

procedure TAFMmain.rangeContrastChange(Sender: TObject);
begin
if not canChange then Exit;

minI:=rangeContrast.Position1*8;
maxI:=rangeContrast.Position2*8;
//
RescaleGraph(minI, maxI);
IGraph.LoadData(imgData);
IGraph.RepaintGraph;
end;

procedure TAFMmain.RescaleGraph(vmin, vmax: integer);
var i, j,v:Integer;
    k:Single;
begin
if vmin>=vmax then Exit;
//  RAWData
//  ImageData
 k:=255/(vmax-vmin);


for j := 0 to rawData.Height-1 do
  for i := 0 to rawData.Width-1 do
    begin
    v:= Round((rawData.Values[i,j]-vmin)*k);
    imgData.Values[i,j]:= max(0, min(255, v));
    end;

end;

procedure TAFMmain.setDynamicGraph;
begin
SGraph.DelCurve('1');

  if SGraph.curves.Count=0 then
  dataCurve:=SGraph.AddCurve('1', clRed, 1024);

  SGraph.ResetTail(dataCurve);
  SGraph.SetMode(gmDynamicG);
  idx:=0;

  SGraph.CalcResize;
end;

procedure TAFMmain.Timer1Timer(Sender: TObject);
begin
if workMode<>wmodStop then
  SGraph.RepaintGraph;
end;

procedure TAFMmain.Timer250Timer(Sender: TObject);
var scanI, monI:Cardinal;
begin
  monI:=trbMonInterval.Max-trbMonInterval.Position;
  scanI:=trbScanInterval.Max-trbScanInterval.Position;

if monI<>prevMonI then
  begin
    prevMonI:=monI;

    if CPort.Connected then
    CPort.writeStrAnsw( Format('MONI %.3d', [ Round(Min(99,Power(10, monI/100)))]));

  end;

if scanI<>prevScanI then
  begin
    prevScanI:=scanI;

    if CPort.Connected then
    CPort.writeStrAnsw( Format('SCNI %.3d', [ Round(Min(99,Power(10, scanI/100)))]));

  end;
end;

end.
