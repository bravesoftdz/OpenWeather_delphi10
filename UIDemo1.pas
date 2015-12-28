unit UIDemo1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit, FMX.ScrollBox, FMX.Memo,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, System.JSON,
  IPPeerClient, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope, classOpenWeather,
  FMX.TabControl, FMX.ListBox, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.Objects, System.ImageList,
  FMX.ImgList, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL;

type

  TJsonDataFromThread = class(TObject)
    json_data: string;
  end;

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
    imgCross: TImage;
    lbxWeather: TListView;
    imgArrow: TImage;
    ImageList1: TImageList;
    Layout1: TLayout;
    cboLocation: TComboBox;
    imgWeather: TImage;
    Rectangle1: TRectangle;
    Label1: TLabel;
    IdHTTP1: TIdHTTP;
    procedure btnRefreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbxWeatherDblClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    OnActivateDone: boolean;
    WeatherData: TJsonDataFromThread;
    OpenWeatherItem: TOpenWeatherItem;
    procedure process_new_weather_data(Sender: TObject);
    function  get_utc_time: TDateTime;
    function get_local_time(_lat, _lon: string): TDateTime;
  public
  end;


  TWeatherReaderThread = class(TTHread)
    JSONData: string;
    WeatherData:  TJsonDataFromThread;
    CityLocation: string;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    procedure writeToMainThread;
    procedure Execute; override;
    constructor create (_CityLocation: string; _WeatherData: TJsonDataFromThread;
                        _RESTClient: TRESTClient;_RESTRequest: TRESTRequest; _RESTResponse: TRESTResponse);
  end;

var
  frmUIDemo: TfrmUIDemo;

implementation

{$R *.fmx}

const
  sThumbNailName = 'TI';
  sCaption = 'CA';


function  TfrmUIDemo.get_utc_time: TDateTime;
var
  Response: TStringStream;
  _UTC_Time, _url: string;
  _JSONObject: TJSONObject;
  _JSONPair: TJSONPair;
   _ParseResult: integer;
  // http://www.timeapi.org/utc/now
  // 2015-12-26T06:19:44+00:00
  //'{"dateString":"2015-12-28T09:49:54+00:00"}'
begin
  Result:= 0;
  //_UTC_Time := GetPage('http://www.timeapi.org/utc/now');
  _url:= 'http://www.timeapi.org/utc/now';
  RESTClient.BaseURL :=  _url;
  RESTRequest.Resource := '';
  RESTRequest.Execute;
  _UTC_Time:= RESTResponse.Content;
  if _UTC_Time <> '' then
  try
      _JSONObject:=  TJSONObject.Create;
      _ParseResult := _JSONObject.Parse(BytesOf(_UTC_Time ),0);
      _JSONPair := _JSONObject.Get('dateString');  //rawOffset       dstOffset
      if _JSONPair <> Nil  then  _UTC_Time:=  _JSONPair.JSONValue.ToString;
  finally
      _JSONObject.Free;
  end;
  _UTC_Time:= StringReplace(_UTC_Time, '"', '',[rfReplaceAll, rfIgnoreCase]);
  if length(_UTC_Time) = 25  then begin //2015-12-26T06:19:44+00:00
     Result:= EncodeDate(
                 StrToIntDef(copy(_UTC_Time,1,4),1970),
                 StrToIntDef(copy(_UTC_Time,6,2),1),
                 StrToIntDef(copy(_UTC_Time,9,2),1));
     Result:= trunc(Result);
     Result:= Result+ EncodeTime(
                        StrToIntDef(copy(_UTC_Time,12,2),1),
                        StrToIntDef(copy(_UTC_Time,15,2),1),
                        StrToIntDef(copy(_UTC_Time,18,2),1),0);

  end;
end;

function TfrmUIDemo.get_local_time(_lat, _lon: string): TDateTime;
//https://maps.googleapis.com/maps/api/timezone/json?location=-37.81,144.96&timestamp=0&key=AIzaSyB24zZQrfu8dNsF4sn2LIXa5glDiS9Q5Jk
(*
{
   "dstOffset" : 3600,
   "rawOffset" : 36000,
   "status" : "OK",
   "timeZoneId" : "Australia/Hobart",
   "timeZoneName" : "Australian Eastern Daylight Time"
}
*)
const ONE_SECOND = 1/24/60/60;
var  _JSONObject: TJSONObject;
     _json_data: string;
     _url: string;
     _ParseResult: integer;
     _JSONPair: TJSONPair;
     _dstOffset: integer;
     _rawOffset: integer;
     _UTC_time: TDateTime;
begin
  _UTC_time:=  get_utc_time;
   Result:= _UTC_time;
  _url:= format('https://maps.googleapis.com/maps/api/timezone/json?location=%s,%s&timestamp=0&key=AIzaSyB24zZQrfu8dNsF4sn2LIXa5glDiS9Q5Jk',
         [_lat, _lon]);
  RESTClient.BaseURL :=  _url;
  RESTRequest.Resource := '';
  RESTRequest.Execute;
  _json_data:= RESTResponse.Content;
  //_json_data:=   GetPage(_url);
  if _json_data <> '' then
  try
      _JSONObject:=  TJSONObject.Create;
      _ParseResult := _JSONObject.Parse(BytesOf(_json_data ),0);
      _JSONPair := _JSONObject.Get('rawOffset');  //rawOffset       dstOffset
      if _JSONPair <> Nil  then  _rawOffset:=  StrToIntDef(_JSONPair.JSONValue.ToString,0);
      _JSONPair := _JSONObject.Get('dstOffset');  //rawOffset       dstOffset
      if _JSONPair <> Nil  then  _dstOffset:=  StrToIntDef(_JSONPair.JSONValue.ToString,0);
      Result:= _UTC_time+_rawOffset*ONE_SECOND+_dstOffset*ONE_SECOND;
  finally
      _JSONObject.Free;
  end;
end;


procedure TfrmUIDemo.btnRefreshClick(Sender: TObject);
var _responce: string;
    _Item: TListViewItem;
    _BitMap: TBitMap;
    _Size: TSize;
    _ListItemImage: TListItemImage;
    _BitmapItem: TBitmapItem;
    _localTime: TDateTime;
    _hoursAgo: double;
    //https://maps.googleapis.com/maps/api/timezone/json?location=-37.81,144.96&timestamp=0&key=AIzaSyB24zZQrfu8dNsF4sn2LIXa5glDiS9Q5Jk

begin
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
  _localTime:= get_local_time(OpenWeatherItem.lat, OpenWeatherItem.lon);
  _hoursAgo:= (_localTime-  OpenWeatherItem.last_updated) *24;
  Memo1.Lines.Assign(OpenWeatherItem.debug_text);
  Memo1.Lines.Insert(0,'Local TIme: '+DateTimeToStr(_localTime));
  lbxWeather.Items.Clear;

 // _Item:= lbxWeather.Items.Add;
 // _Item.Text:= '            '+OpenWeatherItem.name;
  _Size.Width:= 24;
  _Size.Height:= 24;
  _BitMap:=  ImageList1.Bitmap(_Size,0 );
  OpenWeatherItem.icon:= lowercase(OpenWeatherItem.icon);
  if OpenWeatherItem.icon = '01d' then  _BitMap:=  ImageList1.Bitmap(_Size,0 );
  if OpenWeatherItem.icon = '01n' then  _BitMap:=  ImageList1.Bitmap(_Size,0 );
  if OpenWeatherItem.icon = '02d' then  _BitMap:=  ImageList1.Bitmap(_Size,1 );
  if OpenWeatherItem.icon = '02n' then  _BitMap:=  ImageList1.Bitmap(_Size,1 );
  if OpenWeatherItem.icon = '03d' then  _BitMap:=  ImageList1.Bitmap(_Size,2 );
  if OpenWeatherItem.icon = '03n' then  _BitMap:=  ImageList1.Bitmap(_Size,2 );
  if OpenWeatherItem.icon = '04d' then  _BitMap:=  ImageList1.Bitmap(_Size,3 );
  if OpenWeatherItem.icon = '04n' then  _BitMap:=  ImageList1.Bitmap(_Size,3 );
  if OpenWeatherItem.icon = '09d' then  _BitMap:=  ImageList1.Bitmap(_Size,4 );
  if OpenWeatherItem.icon = '09n' then  _BitMap:=  ImageList1.Bitmap(_Size,4 );
  if OpenWeatherItem.icon = '10d' then  _BitMap:=  ImageList1.Bitmap(_Size,5 );
  if OpenWeatherItem.icon = '10n' then  _BitMap:=  ImageList1.Bitmap(_Size,5 );
  if OpenWeatherItem.icon = '11d' then  _BitMap:=  ImageList1.Bitmap(_Size,6 );
  if OpenWeatherItem.icon = '11n' then  _BitMap:=  ImageList1.Bitmap(_Size,6 );
  if OpenWeatherItem.icon = '13d' then  _BitMap:=  ImageList1.Bitmap(_Size,7 );
  if OpenWeatherItem.icon = '13n' then  _BitMap:=  ImageList1.Bitmap(_Size,7 );
  if OpenWeatherItem.icon = '50d' then  _BitMap:=  ImageList1.Bitmap(_Size,8 );
  if OpenWeatherItem.icon = '50n' then  _BitMap:=  ImageList1.Bitmap(_Size,8 );
  imgWeather.Bitmap.Assign(_BitMap);;
 // _BitMap.SaveToFile('C:\aaa\c.bmp');
 (*
  _Item.BitmapRef := _BitMap;//imgCross.Bitmap;
  _ListItemImage:=  (_Item.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := _BitMap;//imgCross.Bitmap;
   end;
   *)
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= OpenWeatherItem.description;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Current Temp: '+OpenWeatherItem.temp;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Wind Speed: '+OpenWeatherItem.wind_speed;
   _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Humidity: '+OpenWeatherItem.humidity;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Local Time: '+FormatDateTime('dd/mm/yy hh:nn am/pm',_localTime);

  _Item:= lbxWeather.Items.Add;
  _Item.Text:= //' Last Update: '+FormatDateTime('dd/mm/yy hh:nn am/pm   ',OpenWeatherItem.last_updated)+
               Format('Last Update %f hours ago',[_hoursAgo]);
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Lat: '+OpenWeatherItem.lat;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Lon: '+OpenWeatherItem.lon;

  //lbxWeather.Items.Add('Current Temp: '+OpenWeatherItem.temp);
  //lbxWeather.Items.Add('Max Temp: '+OpenWeatherItem.temp_max);
  //lbxWeather.Items.Add('Min Temp: '+OpenWeatherItem.temp_min);
  //lbxWeather.Items.Add('Pressure: '+OpenWeatherItem.pressure);
  //lbxWeather.Items.Add('Humidity: '+OpenWeatherItem.humidity);
  //lbxWeather.Items.Add('Wind Direction: '+OpenWeatherItem.wind_deg);

end;

procedure TfrmUIDemo.FormActivate(Sender: TObject);
var _WeatherReaderThread: TWeatherReaderThread;
begin
    if OnActivateDone then
      exit;
    OnActivateDone:= true;
    _WeatherReaderThread:= TWeatherReaderThread.create('Melbourne,au',WeatherData,RESTClient,RESTRequest,RESTResponse);
    _WeatherReaderThread.OnTerminate:= process_new_weather_data;
    _WeatherReaderThread.Execute;
    _WeatherReaderThread.Free;

    //btnRefreshClick(Sender);
    OnActivateDone:= true;
end;

procedure TfrmUIDemo.FormCreate(Sender: TObject);
begin
  OnActivateDone:= false;
  WeatherData:= TJsonDataFromThread.Create;
  OpenWeatherItem:= TOpenWeatherItem.Create;
end;

procedure TfrmUIDemo.FormDestroy(Sender: TObject);
begin
    OpenWeatherItem.Free;
    WeatherData.Free;
end;

procedure TfrmUIDemo.lbxWeatherDblClick(Sender: TObject);
begin
  TabControl1.ActiveTab:= tiDebug;
end;



procedure TfrmUIDemo.process_new_weather_data(Sender: TObject);
begin
     Label1.Text:= 'Got New Data from Thread';
     Memo1.Lines.Clear;
     Memo1.Lines.Add(weatherdata.json_data);
end;

{ TWeatherReaderThread }

constructor TWeatherReaderThread.create(_CityLocation: string; _WeatherData: TJsonDataFromThread;
                        _RESTClient: TRESTClient;_RESTRequest: TRESTRequest; _RESTResponse: TRESTResponse);
begin
   RESTClient:= _RESTClient;
   RESTRequest:= _RESTRequest;
   RESTResponse:= _RESTResponse;
   CityLocation:= _CityLocation;
   WeatherData:=    _WeatherData;
   inherited Create(true);
end;

procedure TWeatherReaderThread.Execute;
begin
  RESTClient.BaseURL :=
     'http://api.openweathermap.org/data/2.5/weather?q='+CityLocation+'&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5';
  RESTRequest.Resource := '';
  RESTRequest.Execute;
  JSONData:= RESTResponse.Content;
  Synchronize(writeToMainThread);
end;

procedure TWeatherReaderThread.writeToMainThread;
begin
  WeatherData.json_data:= JSONData;
end;

end.
