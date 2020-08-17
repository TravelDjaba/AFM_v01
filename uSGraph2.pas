unit uSGraph2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls,
  System.Generics.Defaults, System.Generics.Collections, GR32, GR32_LowLevel, GR32_Image,
  GR32_Paths, GR32_System, GR32_Polygons, GR32_Layers, MMatrix, System.DateUtils,
  Vcl.StdCtrls;

type

  TGraphMode = (gmStatic, gmDynamic, gmDynamicG);

  TCurve = class
    public
    name:string;
    magic:Integer;
    color:TColor32;
    length:UInt32;
    dataX:TMVector<Single>;
    dataY:TMVector<Single>;

    head, tail:Integer;

    constructor Create(name: string; color: TColor32; length: UInt32);
    destructor Destroy; override;
  end;

type
  TSGraph2 = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    img: TImage32;
    imgAxisY: TImage32;
    imgAxisX: TImage32;
    StatusBar1: TStatusBar;
    procedure imgResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure imgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer;
      Layer: TCustomLayer);
    procedure imgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure imgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
    procedure imgMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  private
    { Private declarations }
    fGraphMode:TGraphMode;
    bShowGrid:Boolean;
    bShowLabelX,bShowLabelY:Boolean;


    minX, maxX, minY, maxY:Single;
    limMinX, limMaxX, limMinY, limMaxY:Single;
    scaleXrev, scaleYrev:Double;

    ptDown:TFloatPoint;
    ptStartDragRect: TFloatRect;

    zoomX, zoomY:Double;
    stepX, stepY: double;


    function pixToValue(x,y:integer): TFloatPoint; inline;
    function ValueToPix(x, y: Single): TFloatPoint; inline;
    function VExp(value, minV, maxV: double): string; inline;

    procedure CalcStep(horizont: Boolean; min, max: double; var step: double);

    procedure Grid(horizont: Boolean; minV, maxV: double; step: double);
    procedure Axis(horizont: Boolean; minV, maxV: double; step: double);

  public
    { Public declarations }
    BGcolor, gridColor, textColor:TColor32;
    curves:TObjectList<TCurve>;
    bDrag:Boolean;

    class function CreateOn(AOwner: TComponent):TSGraph2;

    function AddCurve(name:string; color:TColor; length:UInt32 ):TCurve;
    procedure DelCurve(name:string ); overload;
    procedure DelCurveByIdx(idx:integer ); overload;
    procedure DelCurveByMagic(magic:integer ); overload;
    procedure DelCurves;


    procedure CalcResize;
    procedure RepaintGraph;
    procedure ResetTail(cur:TCurve);
    procedure SetMaxTail(cur:TCurve);
    procedure AddStaticValue(const X,Y:Single; cur:TCurve);
    procedure AddDynamicValue(const X,Y:Single; cur:TCurve); overload;
    procedure AddDynamicValue(const Y:Single; cur:TCurve);  overload;
    procedure SetMode(mode:TGraphMode);
    procedure SetLimitsX(const aLimMinX, aLimMaxX:Single);
    procedure SetLimitsY(const aLimMinY, aLimMaxY:Single);

  end;




implementation

uses System.Math;

{$R *.dfm}

var t1,t2,t3:Cardinal;

{ TSGraph2 }

function TSGraph2.AddCurve(name: string; color: TColor; length: UInt32): TCurve;
var curve:TCurve;
  idx:Integer;
begin
  curve:=TCurve.Create(name, Color32(color), length);
  idx:=curves.Add(curve);
//  result:=curve.magic;
//  result:=idx;
  result:=curve;
end;

procedure TSGraph2.AddDynamicValue(const X, Y: Single; cur: TCurve);
var fTail, fHead:Integer;
    shift:Single;
begin
//  fGraphMode:=gmDynamic;

  Inc(cur.tail);
  if cur.tail>=cur.length then
      Inc(cur.head);

  fTail:= cur.tail mod cur.length;
  fHead:= cur.head mod cur.length;

  cur.dataX[fTail]:=X;
  cur.dataY[fTail]:=Y;

  if cur.tail>=cur.length then
    begin
    shift:= cur.dataX[cur.tail mod cur.length] - cur.dataX[(cur.tail-1) mod cur.length];
    minX:=minX+shift;
    maxX:=maxX+shift;
    end;

  //RepaintGraph;
end;

procedure TSGraph2.AddDynamicValue(const Y: Single; cur: TCurve);
var fTail, fHead:Integer;
    shift:Single;
begin

  Inc(cur.tail);
  if cur.tail>=cur.length then
      Inc(cur.head);

  fTail:= cur.tail mod cur.length;
  fHead:= cur.head mod cur.length;

//  cur.dataX[fTail]:=X;
  cur.dataY[fTail]:=Y;

//  if cur.tail>=cur.length then
//    begin
//    shift:=1;// cur.dataX[cur.tail mod cur.length] - cur.dataX[(cur.tail-1) mod cur.length];
//    minX:=minX+shift;
//    maxX:=maxX+shift;
//    end;
end;

procedure TSGraph2.AddStaticValue(const X, Y: Single; cur:TCurve);
begin
//fGraphMode:=gmStatic;
if cur.tail<Cur.length then
 begin
  Inc(cur.tail);
  cur.dataX[cur.tail]:=X;
  cur.dataY[cur.tail]:=Y;

//  RepaintGraph;
 end;
end;

procedure TSGraph2.Axis(horizont: Boolean; minV, maxV, step: double);
var
  pix: Double;
  i, start: integer;
begin

  if horizont then
      if not bShowLabelX then Exit
  else
      if not bShowLabelY then Exit;


  imgAxisX.Bitmap.Font.color := textColor;
  imgAxisY.Bitmap.Font.color := textColor;

  start:= Round(minV / step);

  if start*step<minV then
    Inc(start);

  while start*step<maxV do
    begin
     if horizont then
       begin
       pix:= ValueToPix((start*step), 0).X ;
       imgAxisX.Bitmap.Textout(Round(pix) +35, 5, VExp(start*step, MinX, MaxX));
       end
     else
       begin
       pix:= ValueToPix(0, (start*step)).Y ;
       imgAxisY.Bitmap.Textout(1, Round(pix)- 8, VExp(start*step, MinY, MaxY));
       end;
       Inc(start);
    end;

end;

procedure TSGraph2.CalcResize;
begin

  img.Bitmap.SetSize(img.Width, img.Height);
  scaleXrev:=1/(maxX-minX)*img.Width;
  scaleYrev:=1/(maxY-minY)*img.Height;

  imgAxisX.Bitmap.SetSize(imgAxisX.Width, imgAxisX.Height);
  imgAxisY.Bitmap.SetSize(imgAxisY.Width, imgAxisY.Height);

  CalcStep(true, MinX, MaxX, stepX);
  CalcStep(False, MinY, MaxY, stepY);

  RepaintGraph;
end;

procedure TSGraph2.CalcStep(horizont: Boolean; min, max: double; var step: double);

var
  d1: double;
  s, se: string;
begin
  s := FormatFloat('0.0E+000', max - min);
  se := Copy(s, 5, 4);
  s := Copy(s, 1, 3);
  d1 := StrToFloat(s);

  begin
    // 0.1  0.2  0.5  1.0
    if d1 < 1.5 then
      step := 0.1
    else if d1 < 3.0 then
      step := 0.2
    else if d1 < 6.0 then
      step := 0.5
    else
      step := 1;
  end;

  if horizont then
  begin
    if img.Width  > 300 then
      step := step * StrToFloat('1E' + se)
    else if img.Width  > 100 then
      step := 3 * step * StrToFloat('1E' + se)
    else
      step := 6 * step * StrToFloat('1E' + se);
  end
  else
  begin
    if img.Height  > 200 then
      step := step * StrToFloat('1E' + se)
    else if img.Height  > 100 then
      step := 2 * step * StrToFloat('1E' + se)
    else
      step := 5 * step * StrToFloat('1E' + se);
  end;
end;

class function TSGraph2.CreateOn(AOwner: TComponent): TSGraph2;
begin
  Result:= TSGraph2.Create(AOwner);
  Result.Parent:= TWinControl(AOwner);
  Result.Align:=alClient;
  Result.BorderStyle:=bsNone;
  Result.Show;
end;

procedure TSGraph2.DelCurve(name: string);
var i:Integer;
begin
if curves.Count>0 then
for i := 0 to curves.Count-1 do
  if curves[i].name=name then
     begin
//     curves[i].Free;
     curves.Delete(i);
     Break;
     end;
end;

procedure TSGraph2.DelCurveByIdx(idx: integer);
begin
if curves.Count>=idx+1 then
    curves.Delete(idx);
end;

procedure TSGraph2.DelCurveByMagic(magic: integer);
var i:Integer;
begin
if curves.Count>0 then
for i := 0 to curves.Count-1 do
  if curves[i].magic=magic then
    begin
    curves.Delete(i);
    Break;
    end;
end;

procedure TSGraph2.DelCurves;
//var i:Integer;
begin
//if curves.Count>0 then
//for i := curves.Count-1 downto 0 do
//    curves[i].Free;

    curves.Clear;

end;

procedure TSGraph2.FormCreate(Sender: TObject);
begin
  curves:=TObjectList<TCurve>.Create;
  BGcolor:=clLightGray32;
  gridColor:=clDkGray32;
  textColor:=clDkGray32;

  bShowGrid:=True;
  bShowLabelX:=True;
  bShowLabelY:=True;

  fGraphMode:=gmStatic;

  img.Bitmap.SetSize(img.Width, img.Height);
  minX:=0; maxX:=1023;
  minY:=0; maxY:=4095;
  zoomX:=1;
  zoomY:=1;

  limMinX:=0;
  limMaxX:=1023;

  CalcResize;
end;

procedure TSGraph2.FormDestroy(Sender: TObject);
var i:Integer;
begin
if curves.Count>0 then
for i := 0 to curves.Count-1 do
    curves.Delete(0);

curves.Free;
end;



procedure TSGraph2.Grid(horizont: Boolean; minV, maxV, step: double);
var
  pix: Integer;
  start: integer;
begin

  start:= trunc(minV / step);

  if start*step<minV then
    Inc(start);

  while start*step<maxV do
    begin
     if horizont then
       begin
       pix:= Round(ValueToPix((start*step), 0).X );
       img.Bitmap.VertLineS(pix , 0, img.Height - 1 , GridColor);

       end
     else
       begin
       pix:= Round(ValueToPix(0, (start*step)).Y );
       img.Bitmap.HorzLineS(0, pix , img.Width - 1, GridColor);
       end;
       Inc(start);
    end;

end;

procedure TSGraph2.imgMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  if mbLeft = Button then
   begin
    bDrag:=True;
    ptDown:= PixToValue(X,Y);
    ptStartDragRect:=FloatRect(minX, minY, maxX, maxY);

    StatusBar1.Panels[0].Text :=Format('[%.1fx%.1f]',[ptDown.X, ptDown.Y]);
   end;


end;

procedure TSGraph2.imgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
var
    FP:TFloatPoint;
    shiftX, shiftY:Single;
    diffX, diff:Single;
begin
if  not(ssLeft  in Shift) then
  bDrag:=False;

FP:=pixToValue(X, Y);
//sStatusBar1.Panels[0].Text :=Format('[%.1fx%.1f]',[fp.X+minX, fp.Y+minY]);

if {ssMiddle in Shift and} bDrag then
   begin
   shiftX:=FP.X-ptDown.X;
   shiftY:=FP.Y-ptDown.Y;

   if fGraphMode=gmStatic then
    begin
    minX:= (ptStartDragRect.Left - shiftX);
    maxX:= (ptStartDragRect.Right - shiftX);
    end;

//   minX:= (ptStartDragRect.Left - shiftX);
//   maxX:= (ptStartDragRect.Right - shiftX);
//
//   diffX:=maxX-minX;
//
//    if minX<limMinX then
//     begin
//       minX:=limMinX;
//       maxX:=minX+diffX;
//       if maxX>limMaxX then
//        maxX:=limMaxX;
//     end;
//
//    if maxX>limMaxX then
//     begin
//       maxX:=limMaxX;
//       minX:=maxX-diffX;
//       if minX<limMinX then
//        minX:=limMinX;
//     end;



   minY:= (ptStartDragRect.Top - shiftY);
   maxY:= (ptStartDragRect.Bottom - shiftY);

   diff:=maxY-minY;

    if minY<limMinY then
     begin
       minY:=limMinY;
       maxY:=minY+diff;
       if maxY>limMaxY then
        maxY:=limMaxY;
     end;

    if maxY>limMaxY then
     begin
       maxY:=limMaxY;
       minY:=maxY-diff;
       if minY<limMinY then
        minY:=limMinY;
     end;

   RepaintGraph;
   end;
end;

procedure TSGraph2.imgMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer; Layer: TCustomLayer);
begin
  bDrag:=False;
end;

procedure TSGraph2.imgMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  P: TPoint;
  FP, cPoint:TFloatPoint;
  mul, diff:Single;
begin
P:=img.ScreenToClient( MousePos );
FP:=pixToValue(P.X, P.Y);

FP.X:=FP.X+minX;
FP.Y:=FP.Y+minY;

  if WheelDelta>0 then
    mul:=11/10
    else
  if WheelDelta<0 then
    mul:=11/12;



    if ssCtrl in Shift then
     begin
      if fGraphMode=gmStatic then
      begin
        minX:=FP.X-(FP.X-minX)*mul;
        maxX:=FP.X+(maxX-FP.X)*mul;
      end;
     end
    else
    if ssShift in Shift then
     begin
     if fGraphMode=gmStatic then
      begin
        minX:=FP.X-(FP.X-minX)*mul;
        maxX:=FP.X+(maxX-FP.X)*mul;
      end;
      minY:=FP.Y-(FP.Y-minY)*mul;
      maxY:=FP.Y+(maxY-FP.Y)*mul;

      diff:=maxY-minY;

      if minY<limMinY then
       begin
         minY:=limMinY;
         maxY:=minY+diff;
         if maxY>limMaxY then
          maxY:=limMaxY;
       end;

      if maxY>limMaxY then
       begin
         maxY:=limMaxY;
         minY:=maxY-diff;
         if minY<limMinY then
          minY:=limMinY;
       end;
     end
    else
      begin
      minY:=FP.Y-(FP.Y-minY)*mul;
      maxY:=FP.Y+(maxY-FP.Y)*mul;

      diff:=maxY-minY;

      if minY<limMinY then
       begin
         minY:=limMinY;
         maxY:=minY+diff;
         if maxY>limMaxY then
          maxY:=limMaxY;
       end;

      if maxY>limMaxY then
       begin
         maxY:=limMaxY;
         minY:=maxY-diff;
         if minY<limMinY then
          minY:=limMinY;
       end;

      end;


  CalcResize;

end;

procedure TSGraph2.imgResize(Sender: TObject);
begin
  CalcResize;
end;

function TSGraph2.pixToValue(x, y: integer): TFloatPoint;
begin
  Result.X:=X/img.Width*(maxX-minX);
  Result.Y:=(img.Height-Y)/img.Height*(maxY-minY);
end;

procedure TSGraph2.RepaintGraph;
var i,j, jj, x:Integer;
    h, w:integer;
    fp:TFloatPoint;

    fHead, fTail:Integer;

begin

  t1:=t3;
  t3:=GetTickCount;

  img.Bitmap.BeginUpdate;

  img.Bitmap.Clear(BGcolor);

  //repaint grid
  h:= img.Bitmap.Height;
  w:=img.Bitmap.Width;


  img.Bitmap.LineAS(0, 0, 0, h-1, gridColor, true);
  img.Bitmap.LineAS(0, h-1, w-1, h-1 , gridColor, true);

  if bShowGrid then
  begin
    Grid(true, MinX, MaxX, stepX);
    Grid(False, MinY, MaxY, stepY);
  end;


  //repaint curves
  if fGraphMode=gmStatic then

  if curves.Count>0 then
    for i := 0 to curves.Count-1 do
      if curves[i].tail>curves[i].head then

      begin
      img.Bitmap.PenColor:= curves[i].color;

      fp:=ValueToPix(curves[i].dataX[curves[i].head],curves[i].dataY[curves[i].head]);
      img.Bitmap.MoveToF(fp.X, fp.Y);

      for j:=curves[i].head+1 to curves[i].tail do
        begin
          fp:=ValueToPix(curves[i].dataX[j],curves[i].dataY[j]);

          if (curves[i].dataX[j]<minX) then
            img.Bitmap.MoveToF(fp.X, fp.Y)
          else
            begin
            img.Bitmap.LineToFS(fp.X, fp.Y);
            if (curves[i].dataX[j]>maxX) then Break;
            end;
        end;

      end;


  if fGraphMode=gmDynamic then

  if curves.Count>0 then
    for i := 0 to curves.Count-1 do
      if curves[i].tail>curves[i].head then

      begin
      img.Bitmap.PenColor:= curves[i].color;
      fHead:= curves[i].head mod curves[i].length;
      fTail:= curves[i].tail mod curves[i].length;

      fp:=ValueToPix(curves[i].dataX[fHead],curves[i].dataY[fHead]);
      img.Bitmap.MoveToF(fp.X, fp.Y);

      for j:=curves[i].head+1 to curves[i].tail do
        begin
          jj:=j mod curves[i].length;
          fp:=ValueToPix(curves[i].dataX[jj],curves[i].dataY[jj]);

          if (curves[i].dataX[jj]<minX) then
            img.Bitmap.MoveToF(fp.X, fp.Y)
          else
            begin
            img.Bitmap.LineToFS(fp.X, fp.Y);
            if (curves[i].dataX[jj]>maxX) then Break;
            end;
        end;

      end;

  if fGraphMode=gmDynamicG then

  if curves.Count>0 then
    for i := 0 to curves.Count-1 do
      if curves[i].tail>curves[i].head then

      begin
      img.Bitmap.PenColor:= curves[i].color;
      fHead:= curves[i].head mod curves[i].length;
      fTail:= curves[i].tail mod curves[i].length;

      fp:=ValueToPix(curves[i].dataX[0],curves[i].dataY[fHead]);
      img.Bitmap.MoveToF(fp.X, fp.Y);
      x:=1;

      for j:=curves[i].head+1 to curves[i].tail do
        begin
          jj:=j mod curves[i].length;
          fp:=ValueToPix(curves[i].dataX[x],curves[i].dataY[jj]);
          Inc(x);

          if (curves[i].dataX[jj]<minX) then
            img.Bitmap.MoveToF(fp.X, fp.Y)
          else
            begin
            img.Bitmap.LineToFS(fp.X, fp.Y);
            if (curves[i].dataX[jj]>maxX) then Break;
            end;
        end;

      end;

  img.Bitmap.EndUpdate;

  // repaint axis
  imgAxisX.Bitmap.BeginUpdate;
  imgAxisX.Bitmap.Clear(BGcolor);
  Axis(true, MinX, MaxX, stepX);

  imgAxisX.Bitmap.EndUpdate;


  imgAxisY.Bitmap.BeginUpdate;
  imgAxisY.Bitmap.Clear(BGcolor);
  Axis(False, MinY, MaxY, stepY);
  imgAxisY.Bitmap.EndUpdate;



   t2:=GetTickCount;

//   if t3<>t1 then
//   img.Bitmap.Textout(35, 35, Format('%.10f',[ {(t2-t3){/}Single(t3-t1)]  ));

   img.Refresh;
   imgAxisX.Refresh;
   imgAxisY.Refresh;
//   Application.ProcessMessages;
end;

procedure TSGraph2.ResetTail(cur:TCurve);
begin
  cur.head:=0;
  cur.tail:=-1;

  minX:=0;
  maxX:=cur.length-1;

  CalcResize;

end;

procedure TSGraph2.SetLimitsX(const aLimMinX, aLimMaxX: Single);
begin
  limMinX:=aLimMinX;
  limMaxX:=aLimMaxX;
end;

procedure TSGraph2.SetLimitsY(const aLimMinY, aLimMaxY: Single);
begin
  limMinY:=aLimMinY;
  limMaxY:=aLimMaxY;
//  CalcResize;
end;

procedure TSGraph2.SetMaxTail(cur: TCurve);
begin
  cur.head:=0;
  cur.Tail:=cur.length-1;

  RepaintGraph;

end;

procedure TSGraph2.SetMode(mode: TGraphMode);
begin
  fGraphMode:=mode;
end;

function TSGraph2.ValueToPix(x, y: Single): TFloatPoint;
begin
 Result.X:= (x-minX)*scaleXrev;
 Result.Y:= img.Height-(Y-minY)*scaleYrev;
end;

function TSGraph2.VExp(value, minV, maxV: double): string;
begin
  if max(abs(maxV), abs(minV)) > 1E6 then
    result := FormatFloat('#.###E+00', value)
  else if max(abs(maxV), abs(minV)) > 0.001 then
  begin
    if (maxV - minV) > 0.1 then
      result := FormatFloat('0.####', value)
    else
      result := FormatFloat('#.###E+00', value);
  end

  else
    result := FormatFloat('#.###E+00', value);
end;

{ TCurve }

constructor TCurve.Create(name: string; color: TColor32; length: UInt32);
var i:Integer;
begin
  Self.name:=name;
  Self.color:=color;
  Self.length:=length;
  Self.magic:= DateTimeToFileDate(Now);
  Self.dataX:=TMVector<Single>.Create(length);
  Self.dataY:=TMVector<Single>.Create(length);

  Self.magic:= DateTimeToFileDate(Now);
  Self.head:=0;
  Self.tail:=length-1;

  for i := 0 to length-1 do
    Self.dataX[i]:=i;

end;

destructor TCurve.Destroy;
begin
  dataX.Free;
  dataY.Free;
  inherited;
end;

end.
