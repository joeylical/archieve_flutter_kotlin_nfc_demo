import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(new MyApp());

const cmdChannel = const MethodChannel("com.ediacaranstudio.datacard/commands");
const eventChannel = const EventChannel("com.ediacaranstudio.datacard/events");
const showMsg = const EventChannel("com.ediacaranstudio.datacard/showMsg");
const rmChannel = const EventChannel("com.ediacaranstudio.datacard/rmrecord");
const writeChannel =
    const EventChannel("com.ediacaranstudio.datacard/writecounter");

void rmRecord(int rid) async {
  try {
    await cmdChannel.invokeMethod("deleteRecord", {"rid": rid});
  } on PlatformException catch (e) {
    print(e.toString());
  }
}

void writeNfc(NfcInfo info) async {
  try {
    await cmdChannel.invokeMethod("writeNfc", info.toMap());
  } on PlatformException catch (e) {
    print(e.toString());
  }
}

class NfcInfo {
  const NfcInfo({
    this.protocolVersion,
    this.deviceName,
    this.manufacturer,
    @required this.model,
    this.serialNumber,
    this.hardwareVersion,
    this.softwareVersion,
    this.eeVersion,
  });
  final String protocolVersion;
  final String deviceName;
  final String manufacturer;
  final String model;
  final String serialNumber;
  final String hardwareVersion;
  final String softwareVersion;
  final String eeVersion;

  Map<String, String> toMap() {
    return {
      "protocolVersion": protocolVersion,
      "deviceName": deviceName,
      "manufacturer": manufacturer,
      "model": model,
      "serialNumber": serialNumber,
      "hardwareVersion": hardwareVersion,
      "softwareVersion": softwareVersion,
      "eeVersion": eeVersion,
    };
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'NFC Data Card',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'NFC Data Card'),
    );
  }
}

Color getClassification(int sys, int dia) {
  const List<int> sysRange = [0, 120, 130, 140, 160, 180];
  const List<int> diaRange = [0, 80, 85, 90, 100, 110];
  const List<Color> colors = [
    Colors.green,
    Colors.green,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red
  ];

  var i = 0;
  var j = 0;

  for (; sys > sysRange[i] && i < sysRange.length; i++) {}
  for (; dia > diaRange[j] && j < diaRange.length; j++) {}

  if (i > j)
    return colors[i];
  else
    return colors[j];
}

class BloodResult extends StatelessWidget {
  const BloodResult({
    this.systolic,
    this.diastolic,
    this.pulseRate,
  });
  final int systolic;
  final int diastolic;
  final int pulseRate;

  bool get isValid =>
      systolic != null && diastolic != null && pulseRate != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle =
        theme.textTheme.headline.copyWith(color: Colors.black);
    final TextStyle numberStyle =
        theme.textTheme.caption.copyWith(fontSize: 45.0);

    return new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        new Container(
          width: 16.0,
//          child: new Text(
//            '结果:',
//            style: titleStyle.copyWith(
//              fontSize: 14.0,
//            ),
//          ),
          child: new Icon(
            Icons.assessment,
            size: 52.0,
            color: getClassification(systolic, diastolic),
          ),
        ),
        new Text(
          systolic.toString(),
          style: numberStyle,
        ),
        new Text(
          diastolic.toString(),
          style: numberStyle,
        ),
        new Text(
          pulseRate.toString(),
          style: numberStyle,
        ),
      ],
    );
  }
}

class PWVResult extends StatelessWidget {
  const PWVResult({
    this.bloodPressure,
    this.leftPwv,
    this.rightPwv,
  });
  final List<BloodResult> bloodPressure;
  final int leftPwv;
  final int rightPwv;

  bool get isValid =>
      bloodPressure.length == 4 && leftPwv != null && rightPwv != null;

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Column(
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Container(
                  width: 48.0,
                  child: new Text('血压:'),
                ),
                new Text(bloodPressure[0].systolic.toString()),
                new Text(bloodPressure[0].diastolic.toString()),
                new Text(bloodPressure[0].pulseRate.toString()),
              ],
            ),
            new Column(
              children: bloodPressure.sublist(1).map((BloodResult result) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Container(
                      width: 48.0,
                    ),
                    new Text(result.systolic.toString()),
                    new Text(result.diastolic.toString()),
                    new Text(result.pulseRate.toString()),
                  ],
                );
              }).toList(),
            )
          ],
        ),
        new Divider(height: 1.0, indent: 0.0, color: Colors.black26),
        new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Text('PWV:'),
            new Text(leftPwv.toString()),
            new Text(rightPwv.toString()),
          ],
        )
      ],
    );
  }
}

class ResultData {
  const ResultData({
    this.rid,
    this.userName,
    this.time,
    this.value,
  });
  final int rid;
  final String userName;
  final DateTime time;
  final Object value;

  bool get isValid => userName != null && time != null && value != null;
}

final List<ResultData> results = <ResultData>[];

String getNow(DateTime time) {
  final _15min = Duration(minutes: 15);
  final _1hour = Duration(hours: 1);
  final _1day = Duration(days: 1);
  DateTime now = new DateTime.now();
  final _diff = now.difference(time);
  if (_diff <= _15min) {
    return "刚刚";
  } else if (_diff <= _1hour) {
    return "${_diff.inMinutes}分钟前";
  } else if (_diff <= _1day) {
    return "${_diff.inHours}小时前";
  } else if (now.year == time.year &&
      now.month == time.month &&
      now.day == time.day) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  } else {
    return "${time.year.toString()}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}";
  }
}

class ResultDataItem extends StatelessWidget {
  ResultDataItem({Key key, @required this.resultData, this.shape})
      : assert(resultData != null && resultData.isValid),
        super(key: key);

  final ResultData resultData;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle =
        theme.textTheme.headline.copyWith(color: Colors.white);
    final TextStyle descriptionStyle = theme.textTheme.subhead;

    return new SafeArea(
        top: false,
        bottom: false,
        child: new Container(
          padding: const EdgeInsets.all(4.0),
          child: new Card(
              shape: shape,
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 基本信息
                  new SizedBox(
                    height: 40.0,
                    child: new Stack(
                      children: <Widget>[
                        new Positioned.fill(
                          child: new Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 8.0, 16.0, 0.0),
                              child: new Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  new Text(
                                    resultData.userName,
                                    style: titleStyle.copyWith(
                                      color: Colors.black54,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  new Text(
                                    getNow(resultData.time),
                                    style: descriptionStyle.copyWith(
                                      color: Colors.black26,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              )),
                        ),
                      ],
                    ),
                  ),
                  new Divider(
                    height: 2.0,
                  ),
                  // 数据内容
                  new Center(
                    child: new Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                        child: new DefaultTextStyle(
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: descriptionStyle,
                          child: resultData.value,
                        )),
                  ),
                  new Divider(
                    color: Colors.black26,
                    height: 2.0,
                  ),
                  // 工具按钮
                  new ButtonTheme.bar(
                      height: 16.0,
                      padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
                      child: new ButtonBar(
                        alignment: MainAxisAlignment.end,
                        children: <Widget>[
                          new FlatButton(
                            textColor: Colors.amber.shade500,
                            onPressed: () {},
                            child: const Icon(Icons.share),
                          ),
                          new FlatButton(
                            textColor: Colors.amber.shade500,
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return new AlertDialog(
                                      title: new Text('确认删除？'),
                                      actions: <Widget>[
                                        new FlatButton(
                                          child: new Text('否'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        new FlatButton(
                                          child: new Text('是'),
                                          onPressed: () {
                                            rmRecord(resultData.rid);
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                              );
                            },
                            child: const Icon(Icons.delete),
                          ),
                        ],
                      ))
                ],
              )),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  void _onEvent(Object _event) {
    final event = jsonDecode(_event) as Map<dynamic, dynamic>;

    if (!event.containsKey("type")) {
      return;
    }

    final value = jsonDecode(event["value"]) as Map<dynamic, dynamic>;

    var result;
    if (event["type"] == "bloodpressure") {
      result = new ResultData(
        rid: event["rid"],
        userName: event["userName"],
        time: DateTime.fromMillisecondsSinceEpoch(event["time"] * 1000,
            isUtc: true),
        value: BloodResult(
          systolic: value["systolic"],
          diastolic: value["diastolic"],
          pulseRate: value["pulse"],
        ),
      );
    } else if (event["type"] == "pwv") {
      final List<BloodResult> temp = new List<BloodResult>();
      for (var i = 0; i < 4; i++) {
        final bp = value["bloodPressure"][i];
        temp.add(new BloodResult(
          systolic: bp["systolic"],
          diastolic: bp["diastolic"],
          pulseRate: bp["pulse"],
        ));
      }
      result = new ResultData(
          rid: event["rid"],
          userName: event["userName"],
          time: DateTime.fromMillisecondsSinceEpoch(event["time"] * 1000,
              isUtc: true),
          value: PWVResult(
            bloodPressure: temp,
            leftPwv: value["leftPwv"],
            rightPwv: value["rightPwv"],
          ));
    } else {
      return;
    }

    setState(() {
      results.insert(0, result);
    });
  }

  void _onError(Object event) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);

    showMsg.receiveBroadcastStream().listen(
        (event) => setState(() {
              _scaffoldKey.currentState.removeCurrentSnackBar();
              _scaffoldKey.currentState.showSnackBar(new SnackBar(
                content: new Text(event.toString()),
              ));
            }),
        onError: (event) => {});

    rmChannel.receiveBroadcastStream().listen(
        (event) => setState(() {
              results.removeWhere((element) => element.rid == int.parse(event));
            }),
        onError: (event) {});

    cmdChannel.invokeMethod("loaded");
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.border_color),
              onPressed: () {
                Navigator.push(context,
                    new MaterialPageRoute(builder: (ctx) => new WritePage()));
              }),
        ],
      ),
      body: new ListView(
        children: results.map((ResultData result) {
          return new Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: new ResultDataItem(
              resultData: result,
              shape: null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class WritePage extends StatefulWidget {
  WritePage({Key key}) : super(key: key);

  @override
  _WritePage createState() => new _WritePage();
}

class _WritePage extends State<WritePage> {
  final wInfo = Map.of({
    'protocolVersion': 'com.jiuan.BPV10',
    'deviceName': 'BP Monitor',
    'manufacturer': 'Jiuan',
    'model': 'KD-560',
    'serialNumber': '10000000',
    'hardwareVersion': '1.0.0',
    'softwareVersion': '1.0.0',
    'eeVersion': '1.0.0',
  });

  final FocusNode focusPV = FocusNode();
  final FocusNode focusName = FocusNode();
  final FocusNode focusMa = FocusNode();
  final FocusNode focusMd = FocusNode();
  final FocusNode focusNo = FocusNode();
  final FocusNode focusHV = FocusNode();
  final FocusNode focusSV = FocusNode();
  final FocusNode focusEV = FocusNode();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text("数据写入")),
        body: new ListView(
          padding: EdgeInsets.only(left: 12.0, right: 12.0),
          children: <Widget>[
            new TextField(
              controller:
                  new TextEditingController(text: wInfo['protocolVersion']),
              keyboardType: TextInputType.text,
              focusNode: focusPV,
              textInputAction: TextInputAction.next,
              decoration: new InputDecoration(
                labelText: "协议版本",
                hintText: wInfo['protocolVersion'],
              ),
              onChanged: (value) {
                wInfo['protocolVersion'] = value;
                FocusScope.of(context).requestFocus(focusName);
              },
              onSubmitted: (value) {
                wInfo['protocolVersion'] = value;
                FocusScope.of(context).requestFocus(focusName);
              },
            ),
            new TextField(
              controller: new TextEditingController(text: wInfo['deviceName']),
              keyboardType: TextInputType.text,
              focusNode: focusName,
              textInputAction: TextInputAction.next,
              decoration: new InputDecoration(
                labelText: "名称",
                hintText: wInfo['deviceName'],
              ),
              onChanged: (value) {
                wInfo['deviceName'] = value;
                FocusScope.of(context).requestFocus(focusMa);
              },
              onSubmitted: (value) {
                wInfo['deviceName'] = value;
                FocusScope.of(context).requestFocus(focusMa);
              },
            ),
            new TextField(
              controller:
                  new TextEditingController(text: wInfo['manufacturer']),
              keyboardType: TextInputType.text,
              focusNode: focusMa,
              textInputAction: TextInputAction.next,
              decoration: new InputDecoration(
                  labelText: "生产商", hintText: wInfo['manufacturer']),
              onChanged: (value) {
                wInfo['manufacturer'] = value;
                FocusScope.of(context).requestFocus(focusMd);
              },
              onSubmitted: (value) {
                wInfo['manufacturer'] = value;
                FocusScope.of(context).requestFocus(focusMd);
              },
            ),
            new TextField(
              controller: new TextEditingController(text: wInfo['model']),
              keyboardType: TextInputType.text,
              focusNode: focusMd,
              textInputAction: TextInputAction.next,
              decoration: new InputDecoration(
                  labelText: "型号", hintText: wInfo['model']),
              onChanged: (value) {
                wInfo['model'] = value;
                FocusScope.of(context).requestFocus(focusNo);
              },
              onSubmitted: (value) {
                wInfo['model'] = value;
                FocusScope.of(context).requestFocus(focusNo);
              },
            ),
            new TextField(
              controller:
                  new TextEditingController(text: wInfo['serialNumber']),
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
              textInputAction: TextInputAction.next,
              focusNode: focusNo,
              decoration: new InputDecoration(
                  labelText: "序列号", hintText: wInfo['serialNumber']),
              onChanged: (value) {
                wInfo['serialNumber'] = value;
                FocusScope.of(context).requestFocus(focusHV);
              },
              onSubmitted: (value) {
                wInfo['serialNumber'] = value;
                FocusScope.of(context).requestFocus(focusHV);
              },
            ),
            new TextField(
              controller:
                  new TextEditingController(text: wInfo['hardwareVersion']),
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
              textInputAction: TextInputAction.next,
              focusNode: focusHV,
              decoration: new InputDecoration(
                  labelText: "硬件版本", hintText: wInfo['hardwareVersion']),
              onChanged: (value) {
                wInfo['hardwareVersion'] = value;
                FocusScope.of(context).requestFocus(focusSV);
              },
              onSubmitted: (value) {
                wInfo['hardwareVersion'] = value;
                FocusScope.of(context).requestFocus(focusSV);
              },
            ),
            new TextField(
              controller:
                  new TextEditingController(text: wInfo['softwareVersion']),
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
              textInputAction: TextInputAction.next,
              focusNode: focusSV,
              decoration: new InputDecoration(
                  labelText: "软件版本", hintText: wInfo['softwareVersion']),
              onChanged: (value) {
                wInfo['softwareVersion'] = value;
                FocusScope.of(context).requestFocus(focusEV);
              },
              onSubmitted: (value) {
                wInfo['softwareVersion'] = value;
                FocusScope.of(context).requestFocus(focusEV);
              },
            ),
            new TextField(
              controller: new TextEditingController(text: wInfo['eeVersion']),
              keyboardType:
                  TextInputType.numberWithOptions(signed: false, decimal: true),
              textInputAction: TextInputAction.done,
              focusNode: focusEV,
              decoration: new InputDecoration(
                  labelText: "EEPROM版本", hintText: wInfo['eeVersion']),
              onChanged: (value) {
                wInfo['eeVersion'] = value;
              },
              onSubmitted: (value) {
                wInfo['eeVersion'] = value;
              },
            ),
            new Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(4.0),
              child: new RaisedButton(
                  child: new Text("写入"),
                  onPressed: () {
                    cmdChannel.invokeMethod("writeNfc", wInfo);
                    showDialog(context: context, builder: (_) => Dialog());
                  }),
            )
          ],
        ));
  }
}

class Dialog extends StatefulWidget {
  Dialog({Key key}) : super(key: key);

  @override
  _DialogStatus createState() => _DialogStatus();
}

class _DialogStatus extends State<Dialog> {
  int writeCounter = 0;
  int writeFailedCounter = 0;

  @override
  void initState() {
    super.initState();
    writeChannel.receiveBroadcastStream().listen((event) => setState(() {
          if (event.toString() == "sucess")
            writeCounter++;
          else if (event.toString() == "failed")
            writeFailedCounter++;
        }));
  }

//  @override
//  void didChangeAppLifecycleState(AppLifecycleState state) {
//    super.didChangeDependencies();
//    switch(state) {
//      case AppLifecycleState.paused:
//        cmdChannel.invokeMethod("setIdle");
//        break;
//      case AppLifecycleState.resumed:
//        Navigator.of(context).pop();
//        break;
//      case AppLifecycleState.inactive:
//        cmdChannel.invokeMethod("setIdle");
//        break;
//      case AppLifecycleState.suspending:
//        cmdChannel.invokeMethod("setIdle");
//        break;
//    }
//  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        cmdChannel.invokeMethod("cancelWrite");
        Navigator.of(context).pop();
      },
      child: new AlertDialog(
        title: new Text("靠近NFC卡片以写入"),
        content: new Text("写入成功： $writeCounter次\n写入失败： $writeFailedCounter次"),
        actions: <Widget>[
          new FlatButton(
            child: new Text("停止"),
            onPressed: () {
              cmdChannel.invokeMethod("cancelWrite");
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }
}
