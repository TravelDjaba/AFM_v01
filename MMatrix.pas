unit MMatrix;

interface

uses Classes, SysUtils, Winapi.Windows, System.Generics.Defaults, System.Generics.Collections;


type
    TMArray = class (TObject)
    private
    FAllocatedBuffer: PAnsiChar;
    FBuffer: Pointer;
    Fvalsize:integer;
    FUsedSize: integer;
    FCount: integer;

    protected
    constructor Create(ACount, AValsize:integer);

    public
    destructor Destroy; override;

    procedure ReadFromStream(S:TStream);
    procedure WriteToStream(S:TStream);

    property Buffer: Pointer read FBuffer write FBuffer;
    property Count: integer read FCount;
    property UsedSize: integer read FUsedSize;

    end;

  TMVector<T> = class(TMArray)
  type
    P = ^T;
  private
    function GetLength:integer; inline;
    function GetValue(i:integer):T; inline;
    procedure SetValue(i:integer; val:T); inline;
  public
    constructor Create(ALength:integer);

    procedure FillValue(val:T);
    property Length: integer read GetLength;
    property Values[i:integer]: T read GetValue write SetValue; default;
  end;

  TMMatrix<T> = class(TMArray)
  type
    P = ^T;
  private
    FWidth, FHeight:Integer;
    function GetWidth:integer; inline;
    function GetHeight:integer; inline;
    function GetValue(x, y: integer): T;
    procedure SetValue(x, y: integer; const Value: T);
  public
    constructor Create(AWidth, AHeight:integer);

    procedure GetRow(ARowNumber:integer; Result:TMVector<T>);
    procedure GetColumn(AColNumber:integer; Result:TMVector<T>);
    procedure FillValue(val:T);

    property Width: integer read GetWidth;
    property Height: integer read GetHeight;
    property Values[x,y:integer]: T read GetValue write SetValue; default;

  end;

implementation

//GetMem wrapper that aligns the pointer on a 16 bit boundry
procedure GetMemA(var P: Pointer; const Size: DWORD); inline;
var
  OriginalAddress : Pointer;
begin
  P := nil;
  GetMem(OriginalAddress,Size + 32); //Allocate users size plus extra for storage
  If OriginalAddress = nil Then Exit; //If not enough memory then exit
  P := PByte(OriginalAddress) + 4; //We want at least enough room for storage
  DWORD(P) := (DWORD(P) + (15)) And (Not(15)); //align the pointer
  If DWORD(P) < DWORD(OriginalAddress) Then Inc(PByte(P),16); //If we went into storage goto next boundry
  Dec(PDWORD(P)); //Move back 4 bytes so we can save original pointer
  PDWORD(P)^ := DWORD(OriginalAddress); //Save original pointer
  Inc(PDWORD(P)); //Back to the boundry
end;

//Freemem wrapper to free aligned memory
procedure FreeMemA(P: Pointer); inline;
begin
  Dec(PDWORD(P)); //Move back to where we saved the original pointer
  DWORD(P) := PDWORD(P)^; //Set P back to the original
  FreeMem(P); //Free the memory
end;


{ TMArray }

constructor TMArray.Create(ACount, AValsize: integer);
begin
inherited Create;
  FCount:=ACount;
  FValSize:=AValSize;
  FUsedSize:=ACount*AValSize;
//  GetMem(FAllocatedBuffer, FUsedSize);
  GetMemA(Pointer(FAllocatedBuffer), FUsedSize);
  if FAllocatedBuffer=nil then
    raise Exception.Create('MArray memory allocation error');

  FBuffer:=FAllocatedBuffer;


end;



destructor TMArray.Destroy;
begin
if Assigned(FAllocatedBuffer) then
//    FreeMem(FAllocatedBuffer,FUsedSize);
    FreeMemA(FAllocatedBuffer);

  inherited Destroy;
end;

procedure TMArray.ReadFromStream(S: TStream);
begin
  S.ReadBuffer(FBuffer^,FUsedSize);
end;

procedure TMArray.WriteToStream(S: TStream);
begin
  S.WriteBuffer(FBuffer^,FUsedSize);
end;

{ TMVector<T> }

constructor TMVector<T>.Create(ALength: integer);
begin
  inherited Create(ALength, SizeOf(T));
end;

procedure TMVector<T>.FillValue(val: T);
var
  i: Integer;
begin
  for i := 0 to FCount-1 do
  P(FAllocatedBuffer+i*Fvalsize)^:=val;
end;

function TMVector<T>.GetLength: integer;
begin
  result:=FCount;
end;

function TMVector<T>.GetValue(i: integer): T;
begin
    Result:=P( FAllocatedBuffer+i*Fvalsize )^;
end;

procedure TMVector<T>.SetValue(i: integer; val: T);
begin
   P(FAllocatedBuffer+i*Fvalsize)^:=val;
end;

{ TMMatrix<T> }

constructor TMMatrix<T>.Create(AWidth, AHeight: integer);
begin
   inherited Create(AWidth*AHeight, SizeOf(T));
   FWidth:= AWidth;
   FHeight:=AHeight;
end;

procedure TMMatrix<T>.FillValue(val: T);
var i:Integer;
begin
  for i := 0 to FCount-1 do
  P(FAllocatedBuffer+i*Fvalsize)^:=val;
end;

procedure TMMatrix<T>.GetColumn(AColNumber: integer; Result: TMVector<T>);
var
  i: Integer;
begin
  if AColNumber>FWidth then
    raise Exception.Create('Column number to big');

  for i := 0 to FHeight-1 do
    P( Result.FAllocatedBuffer+i*Fvalsize )^ := P( FAllocatedBuffer + (i*FWidth + AColNumber)*Fvalsize )^;
end;

function TMMatrix<T>.GetHeight: integer;
begin
  Result:=FHeight;
end;

procedure TMMatrix<T>.GetRow(ARowNumber: integer; Result: TMVector<T>);
var
  i: Integer;
begin
  if ARowNumber>FHeight then
    raise Exception.Create('Column number to big');

  for i := 0 to FWidth-1 do
    P( Result.FAllocatedBuffer+i*Fvalsize )^ := P( FAllocatedBuffer + (ARowNumber*FWidth + i)*Fvalsize )^;
end;

function TMMatrix<T>.GetValue(x, y: integer): T;
begin
  Result:=P( FAllocatedBuffer + (y*FWidth + x)*Fvalsize )^;
end;

function TMMatrix<T>.GetWidth: integer;
begin
  Result:=FWidth;
end;

procedure TMMatrix<T>.SetValue(x, y: integer; const Value: T);
begin
   P( FAllocatedBuffer + (y*FWidth + x)*Fvalsize )^:=Value;
end;

end.
