unit CustomSerialPort;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Threading, System.SyncObjs, System.StrUtils, libserialport, Vcl.Dialogs;

const timeout_ms = 1000;

const WM_PORT_LOSTCONNECTION = WM_USER+1;

type
  Tlog_event = procedure(s:string) of object;
  TrxData_event = procedure( cmd:AnsiString) of object;

  TPortInfo = record
    name, description:AnsiString;
    transport_type:sp_transport;
    usb_manufacturer,usb_product,usb_serial:AnsiString;
    usb_vid,usb_pid,usb_bus,usb_address:Integer;
    bluetooth_address:AnsiString;
  end;

type

  TMonitoringThread = class;

  TCustomSerialPort =  class(TComponent)
  private
    fHWnd: HWND;
    fOnOpen, fOnClose:TNotifyEvent;

    fBaudrate, fDataBits, fStopBits:Integer;
    fParity:sp_parity;
    fFlowcontrol:sp_flowcontrol;

    CritSec:TCriticalSection;
    FMonitoringThread: TMonitoringThread;
    fWA:Boolean;

    fOnRXdata:TrxData_event;

    function getBaudrate: Integer;
    function getDataBits: Integer;
    function getFlowcontrol: sp_flowcontrol;
    function getParity: sp_parity;
    function getStopBits: Integer;
    procedure setBaudrate(const Value: Integer);
    procedure setDataBits(const Value: Integer);
    procedure setFlowControl(const Value: sp_flowcontrol);
    procedure setParity(const Value: sp_parity);
    procedure setStopBits(const Value: Integer);

    procedure DoPortLostConnection;

  protected
    fPort:Psp_port;
    fPortInfo:TPortInfo;
    fPortConfig:Psp_port_config;
    event_set:Psp_event_set;

    fConnected:Boolean;

    procedure WndMethod(var Msg: TMessage); virtual;

    procedure Log(s:String);
    procedure LogErr(s:String);

    {/* Helper function for error handling. */}
    function check(res:sp_return):integer;

    {/* Helper function to give a name for each parity mode. */}
    function parity_name( parity:sp_parity):string;
    function transport_name(transport:sp_transport):String;

  public
    vLog, vLogErr:Tlog_event;

    PortList:array of TPortInfo;
    PortName:AnsiString;

    constructor Create(AOwner:TComponent);
    destructor Destroy; override;

    function Open:Boolean;
    procedure Close;

    function getPortList:integer;
    function getPortInfo(const port:Psp_port):TPortInfo;

    procedure write( data:Pointer; count:UInt32);
    function writeStrAnsw(data: AnsiString; logged:Boolean=false):AnsiString;
    procedure read(data:Pointer; count:Uint32);
    procedure flush;
    procedure startMonitoring;
    procedure stopMonitoring;

    property baudrate:Integer read getBaudrate write setBaudrate;
    property dataBits:Integer read getDataBits write setDataBits;
    property stopBits:Integer read getStopBits write setStopBits;
    property parity:sp_parity read getParity write setParity;
    property flowcontrol:sp_flowcontrol read getFlowcontrol write setFlowControl;


    property Connected:Boolean read fConnected;
    property OnOpen:TNotifyEvent read fOnOpen write fOnOpen;
    property OnClose:TNotifyEvent read fOnClose write fOnClose;

    property OnRXdata:TrxData_event read fOnRXdata write fOnRXdata;

  end;

  TMonitoringThread = class (TThread)
   private
       FOwner: TCustomSerialPort;
       incdata:AnsiString;

     protected
       procedure ProcessCommand;
       procedure Execute; override;

     public
       constructor Create(AOwner: TCustomSerialPort);
       destructor Destroy; override;
       procedure Stop;

   end;

implementation

uses System.Math;
{ TCustomSerialPort }

function TCustomSerialPort.check(res: sp_return): integer;
var error_message:AnsiString;
begin
{/* For this example we'll just exit on any error by calling abort(). */}

        case (res) of
         SP_ERR_ARG:
                begin
                LogErr('Error: Invalid argument.');
                Exit(-1);
                end;
         SP_ERR_FAIL:
                begin
                error_message := sp_last_error_message();
                Log( Format('Error: Failed: %s', [error_message]));
                sp_free_error_message(@error_message);
                Exit(-2);
                end;

         SP_ERR_SUPP:
                begin
                Log('Error: Not supported.');
                Exit(-3);
                end;
         SP_ERR_MEM:
                begin
                Log('Error: Couldn''t allocate memory.');
                Exit(-4);
                end;

         SP_OK:
                Result:= Integer(res);
         else   Result:= Integer(res);
        end;
end;

procedure TCustomSerialPort.Close;
begin
  stopMonitoring;

  sp_free_event_set(event_set);
  check(sp_close(fPort));

 { Free the port structure created by sp_get_port_by_name(). }
 if fPort<>nil then
  sp_free_port(fPort) ;

  if fPortConfig<>nil then
  sp_free_config(fPortConfig);

  fConnected:=False;
  if Assigned(fOnClose) then
    fOnClose(Self);

end;

constructor TCustomSerialPort.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  // Create hidden window using WndMethod as window proc
  fHWnd := AllocateHWnd(WndMethod);

  CritSec:=TCriticalSection.Create;
  fConnected:=false;

  PortName:='';

end;

destructor TCustomSerialPort.Destroy;
begin

  if fConnected then
    Close;

  if CritSec <> nil then
  CritSec.Free;

  // Destroy hidden window
  DeallocateHWnd(fHWnd);

  inherited;
end;



function TCustomSerialPort.getBaudrate: Integer;
begin
  Result:=fBaudrate;
end;

function TCustomSerialPort.getDataBits: Integer;
begin
  Result:=fDataBits;
end;

function TCustomSerialPort.getFlowcontrol: sp_flowcontrol;
begin
  Result:=fFlowcontrol;
end;

function TCustomSerialPort.getParity: sp_parity;
begin
  Result:=fParity;
end;

function TCustomSerialPort.getPortInfo(const port: Psp_port): TPortInfo;
begin
   with Result do
   begin
      name := sp_get_port_name(port);
      description:=sp_get_port_description(port);
      transport_type:=sp_get_port_transport(port);

      if transport_type=SP_TRANSPORT_USB then
        begin
        usb_manufacturer:=sp_get_port_usb_manufacturer(port);
        usb_product:=sp_get_port_usb_product(port);
        usb_serial:=sp_get_port_usb_serial(port);

        sp_get_port_usb_vid_pid(port, @usb_vid, @usb_pid);
        sp_get_port_usb_bus_address(port, @usb_bus, @usb_address);
        end
      else if transport_type=SP_TRANSPORT_BLUETOOTH then
        bluetooth_address:=sp_get_port_bluetooth_address(port);
   end;
end;


function TCustomSerialPort.getPortList:integer;
var port_list:PPsp_port;
    port:Psp_port;
    ret:sp_return;
    i:Integer;
begin
  SetLength(PortList, 0);
  ret:=sp_list_ports(@port_list);

  if (ret <> SP_OK) then
    begin
      LogErr('sp_list_ports() failed!');
      Exit(0);
    end;

  {$POINTERMATH ON}
{  Iterate through the ports. When port_list[i] is NULL
         * this indicates the end of the list. }
  i:=0;
  while (port_list[i]<>nil) do
    begin
      port := port_list[i];
      { Get the info of the port. }

      SetLength(PortList, i+1);
      PortList[i]:=getPortInfo(port);

      Inc(i);
    end;

  { Free the array created by sp_list_ports(). }
  sp_free_port_list(port_list);

  {/* Note that this will also free all the sp_port structures
   * it points to. If you want to keep one of them (e.g. to
   * use that port in the rest of your program), take a copy
   * of it first using sp_copy_port(). */}
{$POINTERMATH OFF}
  result:=i;
end;

function TCustomSerialPort.getStopBits: Integer;
begin
  Result:=fStopBits;
end;

procedure TCustomSerialPort.Log(s: String);
begin
   if @vLog<>nil then
    vLog(s);
end;

procedure TCustomSerialPort.LogErr(s: String);
begin
   if @vLogErr<>nil then
    vLogErr(s);
end;

procedure TCustomSerialPort.DoPortLostConnection;
begin

  Close;
  Log('Port was disconnected');

  MessageDlg('Connection lost', mtError, [mbOK], 0);

end;

function TCustomSerialPort.Open: Boolean;
var ret:Integer;

begin
  { Call sp_get_port_by_name() to find the port. The port
         * pointer will be updated to refer to the port found. }

  if PortName='' then Exit(False);

  ret:=check(sp_get_port_by_name(@PortName[1], @fPort));
  if ret<>0  then
     Exit(False);

  fPortInfo:=getPortInfo(fPort);

  ret:=check(sp_open(fPort, SP_MODE_READ_WRITE));
  if ret<>0  then
     Exit(False);


  {/* Allocate a configuration for us to read the port config into. */}
  ret:=check(sp_new_config(@fPortConfig));

  {/* Read the current config from the port into that configuration. */}
  ret:=check(sp_get_config(fPort, fPortConfig));

  { Setting port to default 115200 8N1, no flow control }

  fBaudrate:=115200;
  fDataBits:=8;
  fStopBits:=1;
  fParity:=SP_PARITY_NONE;
  fFlowcontrol:=SP_FLOWCONTROL_NONE;

  ret:=check(sp_set_config_baudrate(fPortConfig, fBaudrate));
  ret:=check(sp_set_config_bits(fPortConfig, fDataBits));
  ret:=check(sp_set_config_parity(fPortConfig, fParity));
  ret:=check(sp_set_config_stopbits(fPortConfig, fStopBits));
  ret:=check(sp_set_config_flowcontrol(fPortConfig, fFlowcontrol));

  ret:=check(sp_set_config(fPort, fPortConfig));

  {/* Allocate the event set. */}
  ret:=check(sp_new_event_set(@event_set));
  {/* Adding port RX event to event set. */}
  ret:=check(sp_add_port_events(event_set, fPort, SP_EVENT_RX_READY));

  startMonitoring;

  fConnected:=True;

  if Assigned(fOnOpen) then
      fOnOpen(Self);

  Result:=True;
end;

function TCustomSerialPort.parity_name(parity: sp_parity): string;
begin
        case (parity) of
         SP_PARITY_INVALID:
                Result:='(Invalid)';
         SP_PARITY_NONE:
                Result:='None';
         SP_PARITY_ODD:
                Result:='Odd';
         SP_PARITY_EVEN:
                Result:='Even';
         SP_PARITY_MARK:
                Result:='Mark';
         SP_PARITY_SPACE:
                Result:='Space';
        else
                Result:='Else';
        end;
end;

procedure TCustomSerialPort.flush;
begin
check(sp_flush(fPort, SP_BUF_BOTH));
end;

procedure TCustomSerialPort.read(data: Pointer; count: Uint32);
begin
if data<>nil then
check(sp_blocking_read(fPort, data, count, timeout_ms));

end;

procedure TCustomSerialPort.setBaudrate(const Value: Integer);
begin
  if check(sp_set_baudrate(fPort, Value))=0 then
    fBaudrate:=Value;
end;

procedure TCustomSerialPort.setDataBits(const Value: Integer);
begin
   if check(sp_set_bits(fPort, Value))=0 then
    fDataBits:=Value;
end;

procedure TCustomSerialPort.setFlowControl(const Value: sp_flowcontrol);
begin
   if check(sp_set_flowcontrol(fPort, Value))=0 then
    fFlowcontrol:=Value;
end;

procedure TCustomSerialPort.setParity(const Value: sp_parity);
begin
   if check(sp_set_parity(fPort, Value))=0 then
    fParity:=Value;
end;

procedure TCustomSerialPort.setStopBits(const Value: Integer);
begin
   if check(sp_set_stopbits(fPort, Value))=0 then
    fStopBits:=Value;
end;

procedure TCustomSerialPort.startMonitoring;
begin
  FMonitoringThread:= TMonitoringThread.Create(Self);
  FMonitoringThread.Priority:=tpNormal;
  FMonitoringThread.Start;
end;

procedure TCustomSerialPort.stopMonitoring;
begin
   if FMonitoringThread <> nil then
  begin
    FMonitoringThread.Stop;

    FMonitoringThread.WaitFor;  //Do not free until thread is finished executing
    FMonitoringThread.Free;
    FMonitoringThread := nil;
  end;
end;

function TCustomSerialPort.transport_name(transport: sp_transport): String;
begin
  case transport of
    SP_TRANSPORT_NATIVE: result:='Native';
    SP_TRANSPORT_USB: result:='USB';
    SP_TRANSPORT_BLUETOOTH: result:='Bluetooth';
  end;
end;

procedure TCustomSerialPort.WndMethod(var Msg: TMessage);
var
  Handled: Boolean;
begin
  // Assume we handle message
  Handled := True;
  case Msg.Msg of
    WM_PORT_LOSTCONNECTION: DoPortLostConnection; // Code to handle a message

  //  WM_SOMETHINGELSE: DoSomethingElse;  // Code to handle another message
    // Handle other messages here
    else
      // We didn't handle message
      Handled := False;
  end;
  if Handled then
    // We handled message - record in message result
    Msg.Result := 0
  else
    // We didn't handle message
    // pass to DefWindowProc and record result
    Msg.Result := DefWindowProc(fHWnd, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TCustomSerialPort.write(data: Pointer; count: UInt32);
begin
  check(sp_blocking_write(fPort,data, size_t(count), timeout_ms));
end;

function TCustomSerialPort.writeStrAnsw(data: AnsiString; logged:Boolean=false): AnsiString;
var bytes_waiting, i:Integer;
    data_:AnsiString;
    answ:array[0..255] of Byte;
    complete:Boolean;
    t:Cardinal;
begin
  if not fConnected then
    Exit('');

  CritSec.Acquire;
  fWA:=True;

  complete:=False;
  Result:='';

  if logged then
    Log('<<'+data);

  check(sp_flush(fPort, SP_BUF_BOTH));

  data_:=data+#13#10;
  check(sp_blocking_write(fPort,@data_[1], length(data_), timeout_ms));

  t:=GetTickCount;

  while not complete do
    begin
    check(sp_wait(event_set, timeout_ms));

    {/* Get number of bytes waiting. */}
    bytes_waiting:= check(sp_input_waiting(fPort));
    check(sp_blocking_read(fPort, @answ[0], bytes_waiting, timeout_ms));

    for i := 0 to bytes_waiting-1 do
       case answ[i] of
         13: ;
         10: begin
             complete:=True;
             Break;
             end;
         else
             Result:=Result+AnsiChar(answ[i]);
       end;

    if complete then Break;
    if GetTickCount-t> timeout_ms then
      begin
      Result:='ERR timeout ['+Result+']';
      Break;
      end;
    end;

  if logged then
    Log('>>'+Result);


  fWA:=False;
  CritSec.Release;
end;

{ TMonitoringThread }

constructor TMonitoringThread.Create(AOwner: TCustomSerialPort);
begin
  FOwner:=AOwner;

  incdata:='';
  FreeOnTerminate := False;
  inherited Create(True); //create suspended
end;

destructor TMonitoringThread.Destroy;
begin

  inherited;
end;

procedure TMonitoringThread.ProcessCommand;
begin
 if not FOwner.fConnected then Exit;

 if Assigned(FOwner.fOnRXdata) then
  FOwner.fOnRXdata(incdata);

end;

procedure TMonitoringThread.Execute;
  var i, res, bytes_waiting, cnt:Integer;
      stopByDisconnect:Boolean;
      data:array[0..511] of Byte;

begin
stopByDisconnect:=False;

while not Terminated do
    begin

      if not FOwner.fConnected then Break;
      Sleep(1);

        if not FOwner.fWA then
        begin

        FOwner.CritSec.Acquire;

        FOwner.check(sp_wait(FOwner.event_set, 50));

        bytes_waiting:= FOwner.check(sp_input_waiting(FOwner.fPort));
        if bytes_waiting>0 then
          begin
          cnt:=min(512, bytes_waiting);
          FOwner.read(@data[0], cnt);

          for i := 0 to cnt-1 do

               case data[i] of
                 13: ;
                 10: begin
//                     Synchronize(ProcessCommand);
                     ProcessCommand;
                     incdata:='';
                     end;
                 else
                     incdata:=incdata+AnsiChar(data[i]);
               end;

          end
          else
          if bytes_waiting<0 then
              stopByDisconnect:=True;
//
        FOwner.CritSec.Release;

        if stopByDisconnect then
          Break;

        end;

    end;

 if stopByDisconnect then
  PostMessage( FOwner.fHWnd, WM_PORT_LOSTCONNECTION,0,0);


end;

procedure TMonitoringThread.Stop;
begin
 Self.Terminate;
  while FOwner.fWA do
    Sleep(10);
end;

end.
