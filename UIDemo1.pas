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
  IdSSLOpenSSL, System.Sensors, System.Sensors.Components, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.UI.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.FMXUI.Wait, Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet,
  System.Rtti, System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.DBScope, System.IOUtils, System.Generics.Collections, Math;

type

  TLocationItem = class
    id: integer;
    name: string;
    country: string;
  end;

  TfrmUIDemo = class(TForm)
    ToolBar1: TToolBar;
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
    LocationSensor1: TLocationSensor;
    tiLocations: TTabItem;
    Layout2: TLayout;
    btnSearch: TButton;
    Edit1: TEdit;
    ListView1: TListView;
    CityListsTable: TFDQuery;
    CityListsTableid: TIntegerField;
    CityListsTablename: TWideMemoField;
    CityListsTableCountry: TWideMemoField;
    CityListsTablename_country: TWideStringField;
    FDQuery1: TFDQuery;
    FDQuery1CountryCode: TWideMemoField;
    FDQuery1CommonName: TWideMemoField;
    FDQuery1FormalName: TWideMemoField;
    FDQuery1Type: TWideMemoField;
    FDQuery1SubType: TWideMemoField;
    FDQuery1Sovereignty: TWideMemoField;
    FDQuery1Capital: TWideMemoField;
    FDQuery1CurrencyCode: TWideMemoField;
    FDQuery1Currency: TWideMemoField;
    FDQuery1TelephoneCode: TWideMemoField;
    qryWorker: TFDQuery;
    FDConnection1: TFDConnection;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    CityListsTableSHORT_LIST: TBooleanField;
    LinkListControlToField1: TLinkListControlToField;
    btnAddToShortList: TButton;
    btnRemoveFromShortList: TButton;
    btnJumpTOAddLocations: TButton;
    Button1: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbxWeatherDblClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure FDConnection1BeforeConnect(Sender: TObject);
    procedure FDConnection1AfterConnect(Sender: TObject);
    procedure btnAddToShortListClick(Sender: TObject);
    procedure btnRemoveFromShortListClick(Sender: TObject);
    procedure btnJumpTOAddLocationsClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    OnActivateDone: boolean;
    OpenWeatherData: TOpenWeatherData;
    LocationList: TObjectList<TLocationItem>;
    procedure load_short_list;
    procedure show_weather_data(Sender: TObject);
    procedure get_new_new_weather_data(_url: string);
    procedure process_new_weather_data(Sender: TObject);
  public
  end;


  TWeatherReaderThread = class(TTHread)
    JSONData: string;
    WeatherData:  TOpenWeatherData;
    url: string;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    function  get_utc_time: TDateTime;
    function get_local_time(_lat, _lon: string): TDateTime;
    procedure Execute; override;
    constructor create (_url: string; _WeatherData: TOpenWeatherData;
                        _RESTClient: TRESTClient;_RESTRequest: TRESTRequest; _RESTResponse: TRESTResponse);
  end;

var
  frmUIDemo: TfrmUIDemo;

implementation

{$R *.fmx}

const
  sThumbNailName = 'TI';
  sCaption = 'CA';


function DistanceBetweenLonLat(const Lat1, Lon1, Lat2, Lon2: Extended): Extended;
begin
  Result := RadToDeg(ArcCos(Sin(DegToRad(Lat1))
            * Sin(DegToRad(Lat2))
            + Cos(DegToRad(Lat1)) * Cos(DegToRad(Lat2)) * Cos(DegToRad(Lon1 - Lon2)))) * 69.09;
end;



procedure TfrmUIDemo.show_weather_data(Sender: TObject);
var _Item: TListViewItem;
    _BitMap: TBitMap;
    _Size: TSize;
    _ListItemImage: TListItemImage;
    _BitmapItem: TBitmapItem;
    _hoursAgo: double;
    _idx: integer;
    _Distance: Extended;
    //https://maps.googleapis.com/maps/api/timezone/json?location=-37.81,144.96&timestamp=0&key=AIzaSyB24zZQrfu8dNsF4sn2LIXa5glDiS9Q5Jk

begin
  _hoursAgo:= (OpenWeatherData.local_time-  OpenWeatherData.last_updated) *24;
  Memo1.lines.Clear;
  Memo1.Lines.Add(OpenWeatherData.url);
  for _idx := 0 to OpenWeatherData.debug_text.Count-1 do
     Memo1.Lines.Add(OpenWeatherData.debug_text[_idx]);

  //Memo1.Lines.Assign(OpenWeatherData.debug_text);
  //Memo1.Lines.Insert(0,'Local TIme: '+DateTimeToStr(OpenWeatherData.local_time));
  lbxWeather.Items.Clear;
  _Size.Width:= 24;
  _Size.Height:= 24;
  _BitMap:=  ImageList1.Bitmap(_Size,0 );
  OpenWeatherData.icon:= lowercase(OpenWeatherData.icon);
  if OpenWeatherData.icon = '01d' then  _BitMap:=  ImageList1.Bitmap(_Size,0 );
  if OpenWeatherData.icon = '01n' then  _BitMap:=  ImageList1.Bitmap(_Size,0 );
  if OpenWeatherData.icon = '02d' then  _BitMap:=  ImageList1.Bitmap(_Size,1 );
  if OpenWeatherData.icon = '02n' then  _BitMap:=  ImageList1.Bitmap(_Size,1 );
  if OpenWeatherData.icon = '03d' then  _BitMap:=  ImageList1.Bitmap(_Size,2 );
  if OpenWeatherData.icon = '03n' then  _BitMap:=  ImageList1.Bitmap(_Size,2 );
  if OpenWeatherData.icon = '04d' then  _BitMap:=  ImageList1.Bitmap(_Size,3 );
  if OpenWeatherData.icon = '04n' then  _BitMap:=  ImageList1.Bitmap(_Size,3 );
  if OpenWeatherData.icon = '09d' then  _BitMap:=  ImageList1.Bitmap(_Size,4 );
  if OpenWeatherData.icon = '09n' then  _BitMap:=  ImageList1.Bitmap(_Size,4 );
  if OpenWeatherData.icon = '10d' then  _BitMap:=  ImageList1.Bitmap(_Size,5 );
  if OpenWeatherData.icon = '10n' then  _BitMap:=  ImageList1.Bitmap(_Size,5 );
  if OpenWeatherData.icon = '11d' then  _BitMap:=  ImageList1.Bitmap(_Size,6 );
  if OpenWeatherData.icon = '11n' then  _BitMap:=  ImageList1.Bitmap(_Size,6 );
  if OpenWeatherData.icon = '13d' then  _BitMap:=  ImageList1.Bitmap(_Size,7 );
  if OpenWeatherData.icon = '13n' then  _BitMap:=  ImageList1.Bitmap(_Size,7 );
  if OpenWeatherData.icon = '50d' then  _BitMap:=  ImageList1.Bitmap(_Size,8 );
  if OpenWeatherData.icon = '50n' then  _BitMap:=  ImageList1.Bitmap(_Size,8 );
  imgWeather.Bitmap.Assign(_BitMap);;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= OpenWeatherData.name+' - '+OpenWeatherData.country_name;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= OpenWeatherData.description;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Current Temp: '+OpenWeatherData.temp+' '+ char(176)+'C';
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Wind: '+OpenWeatherData.wind_speed+' km/h';
   _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Humidity: '+OpenWeatherData.humidity+'%';

  if  not LocationSensor1.Sensor.Latitude.IsNan()  then begin
      _Distance:=   DistanceBetweenLonLat(LocationSensor1.Sensor.Latitude, LocationSensor1.Sensor.Longitude,
                    StrToFloat(OpenWeatherData.lat), StrToFloat(OpenWeatherData.lon));
      _Item:= lbxWeather.Items.Add;
      _Item.Text:= Format('Distance: %s km.',[FormatCurr('#,##0',_Distance)])
  end;
  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Local Time: '+FormatDateTime('dd/mm/yy hh:nn am/pm',OpenWeatherData.local_time);

  _Item:= lbxWeather.Items.Add;
  _Item.Text:= 'Lat: '+OpenWeatherData.lat+'  '+'Lon: '+OpenWeatherData.lon;

  _Item:= lbxWeather.Items.Add;
  _Item.Text:= //' Last Update: '+FormatDateTime('dd/mm/yy hh:nn am/pm   ',OpenWeatherItem.last_updated)+
               Format('Last Update %f hours ago',[_hoursAgo]);


  //lbxWeather.Items.Add('Current Temp: '+OpenWeatherItem.temp);
  //lbxWeather.Items.Add('Max Temp: '+OpenWeatherItem.temp_max);
  //lbxWeather.Items.Add('Min Temp: '+OpenWeatherItem.temp_min);
  //lbxWeather.Items.Add('Pressure: '+OpenWeatherItem.pressure);
  //lbxWeather.Items.Add('Humidity: '+OpenWeatherItem.humidity);
  //lbxWeather.Items.Add('Wind Direction: '+OpenWeatherItem.wind_deg);

end;

procedure TfrmUIDemo.btnAddToShortListClick(Sender: TObject);
begin
   Memo1.Lines.Clear;
   Memo1.Lines.Add(CityListsTable.FieldByName('name').asString);
   qryWorker.Close;
   qryWorker.SQL.Text:= 'update city_list set  short_list = 1 where id = :id ';
   qryWorker.ParamByName('id').AsInteger:= CityListsTable.FieldByName('id').AsInteger;
   qryWorker.ExecSQL;
   qryWorker.Close;
   load_short_list;
   MessageDlg(CityListsTable.FieldByName('name').AsString+' has been added to your favourites',
            System.UITypes.TMsgDlgType.mtInformation,
            [System.UITypes.TMsgDlgBtn.mbOK],0,Nil);
   cboLocation.ItemIndex:= cboLocation.Items.IndexOf(CityListsTable.FieldByName('name').AsString);
   TabControl1.ActiveTab:= tiWeather;
end;

procedure TfrmUIDemo.btnJumpTOAddLocationsClick(Sender: TObject);
begin
    TabControl1.ActiveTab:= tiLocations;
end;

procedure TfrmUIDemo.btnRefreshClick(Sender: TObject);
//Melbourne,au
//London,gb
//Tokyo,jp
//http://api.openweathermap.org/data/2.5/weather?lat=35&lon=139&APPID=24fdfebe24ee484cd7d2081c74b3bba5
//'http://api.openweathermap.org/data/2.5/weather?q='+CityLocation+'&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5';
var _url: string;
    _cityLocation: string;
    _GPSLocation: string;
    _LocationItem: TLocationItem;
begin
     if cboLocation.ItemIndex < 0 then
       exit;
     if cboLocation.ItemIndex = 0 then begin
        if LocationSensor1.Sensor.Latitude.IsNan() then
                exit;
         _cityLocation:= '';
         _GPSLocation:= format('lat=%f&lon=%f',[LocationSensor1.Sensor.Latitude, LocationSensor1.Sensor.Longitude]);
         _url:=  format('http://api.openweathermap.org/data/2.5/weather?%s&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5',
                        [_GPSLocation]);
         get_new_new_weather_data(_url);
         exit;
     end;
     _LocationItem:= TLocationItem(cboLocation.Items.Objects[cboLocation.ItemIndex]);
     _cityLocation:= _LocationItem.name+','+_LocationItem.country;
     _url:=  format('http://api.openweathermap.org/data/2.5/weather?q=%s&units=metric&APPID=24fdfebe24ee484cd7d2081c74b3bba5',
                    [_cityLocation]);
     get_new_new_weather_data(_url);
end;

procedure TfrmUIDemo.btnRemoveFromShortListClick(Sender: TObject);
var _LocationItem: TLocationItem;
    _Name: string;
begin
  if cboLocation.ItemIndex <=0 then
    exit;
  _LocationItem:= TLocationItem(cboLocation.Items.Objects[cboLocation.ItemIndex]);
  _Name:= _LocationItem.name;
  qryWorker.Close;
  qryWorker.SQL.Text:= 'update city_list set  short_list = 0 where id = :id ';
  qryWorker.ParamByName('id').AsInteger:= _LocationItem.id;
  qryWorker.ExecSQL;
  qryWorker.Close;
  load_short_list;
   MessageDlg(_Name+' has been removed from your favourites',
            System.UITypes.TMsgDlgType.mtInformation,
            [System.UITypes.TMsgDlgBtn.mbOK],0,Nil);
end;

procedure TfrmUIDemo.btnSearchClick(Sender: TObject);
var _sql: string;
    _searchStr: string;
begin
  _searchStr:= Trim(Edit1.Text);
  if length(_searchStr) > 2 then begin
    CityListsTable.Close;
     _sql:=
    'select city_list.*,concat(concat(city_list.name,'' - ''),country_codes.CommonName) as name_country  from city_list '+
    'join country_codes on city_list.Country = country_codes.CountryCode '+
    format('where name like ''%s%%'' ',[_searchStr])+ ' '+
    'order by  name limit 50 ';
    CityListsTable.Open(_sql);
  end;

end;

procedure TfrmUIDemo.Button1Click(Sender: TObject);
begin
    TabControl1.ActiveTab:= tiWeather;
end;

procedure TfrmUIDemo.FDConnection1AfterConnect(Sender: TObject);
begin
    load_short_list;
end;

procedure TfrmUIDemo.FDConnection1BeforeConnect(Sender: TObject);
begin
{$IF DEFINED(iOS) or DEFINED(ANDROID)}
  FDConnection1.Params.Values['Database'] :=
      System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'OpenWeather.db');
  {$ENDIF}
end;

procedure TfrmUIDemo.FormActivate(Sender: TObject);
var _WeatherReaderThread: TWeatherReaderThread;
begin
    if OnActivateDone then
      exit;
    OnActivateDone:= true;
   btnRefreshClick(Sender);
end;

procedure TfrmUIDemo.FormCreate(Sender: TObject);
begin
  OnActivateDone:= false;
  //WeatherData:= TJsonDataFromThread.Create;
  OpenWeatherData:= TOpenWeatherData.Create;
  LocationList:=  TObjectList<TLocationItem>.Create(True);
  FDConnection1.Open();
end;

procedure TfrmUIDemo.FormDestroy(Sender: TObject);
begin
    OpenWeatherData.Free;
    LocationList.Free;
    //WeatherData.Free;
end;


procedure TfrmUIDemo.get_new_new_weather_data(_url: string);
var _WeatherReaderThread: TWeatherReaderThread;
begin
    _WeatherReaderThread:= TWeatherReaderThread.create(_url,OpenWeatherData,RESTClient,RESTRequest,RESTResponse);
    _WeatherReaderThread.OnTerminate:= process_new_weather_data;
    _WeatherReaderThread.FreeOnTerminate:= True;
    _WeatherReaderThread.Start;
end;

procedure TfrmUIDemo.lbxWeatherDblClick(Sender: TObject);
begin
  TabControl1.ActiveTab:= tiDebug;
end;



procedure TfrmUIDemo.load_short_list;
var _LocationItem: TLocationItem;
    i: integer;
begin
    cboLocation.OnChange:= Nil;
    LocationList.Clear;
    qryWorker.Close;
    qryWorker.Open('select * from city_list where short_list = 1 order by name');
    while not qryWorker.Eof do begin
      _LocationItem:= TLocationItem.Create;
      _LocationItem.id:=  qryWorker.FieldByName('id').AsInteger;
      _LocationItem.name:=  qryWorker.FieldByName('name').AsString;
      _LocationItem.country:=  qryWorker.FieldByName('country').AsString;
      LocationList.Add(_LocationItem);
      qryWorker.Next;
    end;
    qryWorker.Close;
    cboLocation.Items.Clear;
    cboLocation.Items.Add('Current Location');
    for i := 0 to LocationList.Count-1 do begin
      _LocationItem:=  LocationList.Items[i];
      if  _LocationItem = nil then
        continue;
       cboLocation.Items.AddObject(_LocationItem.name,_LocationItem);
    end;
    cboLocation.OnChange:= btnRefreshClick;
end;



procedure TfrmUIDemo.process_new_weather_data(Sender: TObject);
begin
    // Memo1.Lines.Clear;
    // Memo1.Lines.Add('Done');
    // Memo1.Lines.Add('Name: '+OpenWeatherData.name);
    OpenWeatherData.country_name:= '';
    qryWorker.Close;
    qryWorker.SQL.Text:= 'select * from country_codes where CountryCode = :CountryCode';
    qryWorker.ParamByName('CountryCode').AsString:= OpenWeatherData.country;
    qryWorker.Open();;
    if not (qryWorker.Eof and qryWorker.BOF) then   begin
      OpenWeatherData.country_name:=  qryWorker.FieldByName('CommonName').AsString;
      OpenWeatherData.country_capital:=  qryWorker.FieldByName('Capital').AsString;
    end;
    qryWorker.Close;

    show_weather_data(sender);
     //show_weather_data(sender);
     //Label1.Text:= 'Got New Data from Thread';
//     Memo1.Lines.Clear;
//     Memo1.Lines.Add(OpenWeatherData.name);
end;

{ TWeatherReaderThread }

function  TWeatherReaderThread.get_utc_time: TDateTime;
var
  Response: TStringStream;
  _UTC_Time, _url: string;
  _JSONObject: TJSONObject;
  _JSONPair: TJSONPair;
   _ParseResult: integer;
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

function TWeatherReaderThread.get_local_time(_lat, _lon: string): TDateTime;
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



constructor TWeatherReaderThread.create(_url: string; _WeatherData: TOpenWeatherData;
                        _RESTClient: TRESTClient;_RESTRequest: TRESTRequest; _RESTResponse: TRESTResponse);
begin
   RESTClient:= _RESTClient;
   RESTRequest:= _RESTRequest;
   RESTResponse:= _RESTResponse;
   url:= _url;
   WeatherData:=    _WeatherData;
   WeatherData.url:= url;
   inherited Create(true);
end;

procedure TWeatherReaderThread.Execute;
begin
  RESTClient.BaseURL :=  url;
  RESTRequest.Resource := '';
  RESTRequest.Execute;
  JSONData:= RESTResponse.Content;
  WeatherData.loadFromJsonData(JSONData);
  WeatherData.local_time:=  get_local_time(WeatherData.lat, WeatherData.lon);
end;



end.
