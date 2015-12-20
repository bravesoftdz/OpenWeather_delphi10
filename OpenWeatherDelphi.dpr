program OpenWeatherDelphi;

uses
  System.StartUpCopy,
  FMX.Forms,
  UIDemo1 in 'UIDemo1.pas' {frmUIDemo},
  classOpenWeather in 'classOpenWeather.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmUIDemo, frmUIDemo);
  Application.Run;
end.
