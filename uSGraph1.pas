unit uSGraph1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VclTee.TeeGDIPlus, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart;

type
  TSGraph1 = class(TForm)
    Chart1: TChart;
    Series1: TFastLineSeries;
  private
    { Private declarations }
  public
    { Public declarations }
    class function CreateOn(AOwner: TComponent):TSGraph1;
  end;

var
  SGraph1: TSGraph1;

implementation

{$R *.dfm}

{ TForm1 }

class function TSGraph1.CreateOn(AOwner: TComponent): TSGraph1;
begin

end;

end.
