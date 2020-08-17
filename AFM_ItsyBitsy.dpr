program AFM_ItsyBitsy;

uses
  Vcl.Forms,
  main in 'main.pas' {AFMmain},
  libserialport in 'libserialport.pas',
  CustomSerialPort in 'CustomSerialPort.pas',
  Vcl.Themes,
  Vcl.Styles,
  uSGraph2 in 'uSGraph2.pas' {SGraph2},
  MMatrix in 'MMatrix.pas',
  uIGraph in 'uIGraph.pas' {IGraph};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Onyx Blue');
  Application.CreateForm(TAFMmain, AFMmain);
  Application.Run;
end.
