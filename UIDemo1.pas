unit UIDemo1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.ScrollBox, FMX.Memo,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, System.JSON,
  IPPeerClient, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope, classOpenWeather,
  FMX.TabControl, FMX.ListBox, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.Objects;

type
  TfrmUIDemo = class(TForm)
    ToolBar1: TToolBar;
    Layout3: TLayout;
    btnRefresh: TButton;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    TabControl1: TTabControl;
    tiWeather: TTabItem;
    tiDebug: TTabItem;
    Memo1: TMemo;
    Label3: TLabel;
    cboLocation: TComboBox;
    lbxWeather: TListView;
    Image1: TImage;
    btnLoadCities: TButton;
    procedure btnRefreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    OpenWeatherItem: TOpenWeatherItem;

    function GetPage(aURL: string): string;
  public
    { Public declarations }
  end;

var
  frmUIDemo: TfrmUIDemo;

implementation

{$R *.fmx}

function  TfrmUIDemo.GetPage(aURL: string): string;
var
  Response: TStringStream;
begin
(*
  Result := '';
  Response := TStringStream.Create('');
  try
    IdHTTP1.Get(aURL, Response);
    if IdHTTP1.ResponseCode = 200 then begin
      Result := Response.DataString;
    end else begin
      // Nothing returned or error
    end;
  finally
    Response.Free;
  end;
*)
end;

procedure TfrmUIDemo.btnRefreshClick(Sender: TObject);
var _responce: string;
    LItem: TListViewItem;
begin
// API key: 24fdfebe24ee484cd7d2081c74b3bba5
// api.openweathermap.org/data/2.5/forecast/city?id=524901&APPID=24fdfebe24ee484cd7d2081c74b3bba5
//api.openweathermap.org/data/2.5/weather?lat=35&lon=1391&APPID=24fdfebe24ee484cd7d2081c74b3bba5
//api.openweathermap.org/data/2.5/weather?q=London&APPID=24fdfebe24ee484cd7d2081c74b3bba5
  //s:=  GetPage('http://api.openweathermap.org/data/2.5/weather?q=London&APPID=24fdfebe24ee484cd7d2081c74b3bba5');
  //Memo1.Lines.Clear;
  //Memo1.Lines.Add(s);
  // lat=35&lon=139
//  RESTClient.BaseURL := 'http://api.openweathermap.org/data/2.5/weather??lat=35&lon=139&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5';
  case cboLocation.ItemIndex of
    0: RESTClient.BaseURL := 'http://api.openweathermap.org/data/2.5/weather?q=Melbourne,au&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5';
    1: RESTClient.BaseURL := 'http://api.openweathermap.org/data/2.5/weather?q=London,gb&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5';
    2: RESTClient.BaseURL := 'http://api.openweathermap.org/data/2.5/weather?q=Tokyo,jp&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5';
  else
     exit;
  end;
  RESTRequest.Resource := '';
  RESTRequest.Execute;
  _responce:= RESTResponse.Content;

  OpenWeatherItem.loadFromJsonData(_responce);
  Memo1.Lines.Assign(OpenWeatherItem.debug_text);
  lbxWeather.Items.Clear;

  LItem:= lbxWeather.Items.Add;
  LItem.Text:= OpenWeatherItem.name;
  LItem.Bitmap:=  Image1.Bitmap;
  (*
  lbxWeather.Items.Add(OpenWeatherItem.name);
  lbxWeather.Items.Add(OpenWeatherItem.description);
  lbxWeather.Items.Add('Current Temp: '+OpenWeatherItem.temp);
  lbxWeather.Items.Add('Max Temp: '+OpenWeatherItem.temp_max);
  lbxWeather.Items.Add('Min Temp: '+OpenWeatherItem.temp_min);
  lbxWeather.Items.Add('Last Update: '+FormatDateTime('dd/mm/yy hh:nn am/pm',OpenWeatherItem.last_updated));
  lbxWeather.Items.Add('Pressure: '+OpenWeatherItem.pressure);
  lbxWeather.Items.Add('Humidity: '+OpenWeatherItem.humidity);
  lbxWeather.Items.Add('Wind Speed: '+OpenWeatherItem.wind_speed);
  lbxWeather.Items.Add('Wind Direction: '+OpenWeatherItem.wind_deg);
  lbxWeather.Items.Add('Lat: '+OpenWeatherItem.lat);
  lbxWeather.Items.Add('Lon: '+OpenWeatherItem.lon);
   *)

end;

procedure TfrmUIDemo.FormCreate(Sender: TObject);
begin
  OpenWeatherItem:= TOpenWeatherItem.Create;
end;

procedure TfrmUIDemo.FormDestroy(Sender: TObject);
begin
    OpenWeatherItem.Free;
end;

end.
