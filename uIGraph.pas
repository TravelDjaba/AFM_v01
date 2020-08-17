unit uIGraph;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, GR32_Image, GR32, GR32_Resamplers, MMatrix, System.Math;

const
    strPalette : array[0..3] of string = ('AFM','AFM hot','Grey','copper');

 type
    TPalette = ( palAFM, palHotAFM, palGrey, palCopper);

type
  TIGraph = class(TForm)
    img: TImage32;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure imgResize(Sender: TObject);
  private
    { Private declarations }
    workingPalette: array[0..255] of TColor32;
    palette:TPalette;
    DataBuffer:TBitmap32;
    imgOffsetX,imgOffsetY:Integer;

  public
    { Public declarations }

    class function CreateOn(AOwner: TComponent):TIGraph;
    procedure SetSize(width, height:integer);
    procedure LoadData(imgData:TMMatrix<Byte>);
    procedure SetPalette(newPalette:TPalette);
    procedure RepaintGraph;
    procedure Clear;
  end;



implementation

{$R *.dfm}

function palette_gray( x:Single ):TColor32; inline;
var r,g,b: byte;
   begin
    r   := Max(0, Round(255*(Min(x,1))));
    g := Max(0, Round(255*(Min(x,1))));
    b  := Max(0, Round(255*(Min(x,1))));
    result:=Color32(r,g,b);
   end;


function palette_AFMhot( x:Single ):TColor32; inline;
var r,g,b: byte;
begin
    r   := Round( 255* Max(0, (Min(1, 2*x))));
    g := Round( 255* Max(0, (Min(1, 2*x-0.5))));
    b  := Round( 255* Max(0, (Min(1, 2*x-1))));
    result:=Color32(r,g,b);
end;


function palette_AFM( x:Single ):TColor32; inline;
var r,g,b: byte;
begin
    r   := Max(0, Round(255*(Min(3*x,1))));
    g := Max(0, Round(255*(Min(3*x-1,1))));
    b  := Max(0, Round(255*(Min(3*x-2,1))));
    result:=Color32(r,g,b);
end;

function palette_copper ( x:Single ):TColor32;
var r,g,b: byte;
//

begin
    r   := Max(0, Round((255*Min(x, 1))));
    g := Max(0, Round((255*Min(0.6*x, 1))));
    b  := Max(0, Round((255*Min(0, 1))));
    result:=Color32(r,g,b);
end;


{ TIGraph }

procedure TIGraph.Clear;
var x,y:integer;
line:PColor32Array;
begin

// LoadDataFromBuffer
DataBuffer.BeginUpdate;

     for y := 0 to DataBuffer.Height-1 do
       begin
        line:=DataBuffer.ScanLine[y];
        for x := 0 to DataBuffer.Width-1 do
        line[x]:=workingPalette[0];
       end;

DataBuffer.EndUpdate;

RepaintGraph;
end;

class function TIGraph.CreateOn(AOwner: TComponent): TIGraph;
begin
  Result:= TIGraph.Create(AOwner);
  Result.Parent:= TWinControl(AOwner);
  Result.Align:=alClient;
  Result.BorderStyle:=bsNone;
  Result.Show;
end;

procedure TIGraph.FormCreate(Sender: TObject);
begin
  DataBuffer:=TBitmap32.Create;
  DataBuffer.SetSize(256,256);
  img.Bitmap.SetSize(img.Width,img.Height);
  imgOffsetX:=0;
  imgOffsetY:=0;

  SetPalette(palAFM);
end;

procedure TIGraph.FormDestroy(Sender: TObject);
begin
FreeAndNil(DataBuffer);
end;

procedure TIGraph.imgResize(Sender: TObject);
begin
img.Bitmap.SetSize(img.Width, img.Height);
RepaintGraph;
end;

procedure TIGraph.LoadData(imgData: TMMatrix<byte>);
var x,y:integer;
line:PColor32Array;
begin

// LoadDataFromBuffer
DataBuffer.BeginUpdate;

   for y := 0 to imgData.Height-1 do
     begin
      line:=DataBuffer.ScanLine[y];
      for x := 0 to imgData.Width-1 do
      line[x]:=workingPalette[ imgData.Values[x,y]];
     end;

DataBuffer.EndUpdate;

RepaintGraph;

end;

procedure TIGraph.RepaintGraph;
begin
   img.Bitmap.Clear;

   DataBuffer.Resampler:= TNearestResampler.Create(DataBuffer);
   DataBuffer.DrawMode:=dmOpaque;
   DataBuffer.DrawTo(img.Bitmap, Rect(0, 0, img.width-1, img.Height-1), Rect(imgOffsetX,imgOffsetY, DataBuffer.Width-1,DataBuffer.Height-1) );
   img.Invalidate;
end;

procedure TIGraph.SetPalette(newPalette:TPalette);
const vmax=255;
var i:Integer;
begin
  palette:=newPalette;

for i := 0 to vmax do
  case palette of
    palGrey: workingPalette[i]:=palette_gray(i/vmax);
    palAFM: workingPalette[i]:=palette_AFM(i/vmax);
    palHotAFM: workingPalette[i]:=palette_AFMhot(i/vmax);
    palCopper:  workingPalette[i]:=palette_copper(i/vmax);
  end;

end;

procedure TIGraph.SetSize(width, height: integer);
begin
  DataBuffer.SetSize(width, height);
//  img.Bitmap.SetSize(width, height);
end;

end.
