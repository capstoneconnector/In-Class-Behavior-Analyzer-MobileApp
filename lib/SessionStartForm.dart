import 'package:behavior_analyzer/APIManager.dart';
import 'package:behavior_analyzer/StudentMainView.dart';
import 'package:flutter/material.dart';
import 'AppConsts.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:behavior_analyzer/BluetoothView.dart';


class SessionStartForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        resizeToAvoidBottomPadding: false,
        body: SafeArea(
          child: SessionStartPage(title: ''),

        ),
      ),
    );
  }

}

class SessionStartPage extends StatefulWidget {
  SessionStartPage({Key key, this.title}) : super(key: key);

  final String title;
  @override
  SessionStartPageState createState() => SessionStartPageState();
}

class SessionStartPageState extends State<SessionStartPage> {
  static const String MODULE_NAME = 'Session Start Form';
  bool isReady = true;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  var bluetoothScan;
  String beaconOne = "88:3F:4A:E5:F6:E2";
  String beaconTwo = "88:3F:4A:E5:FA:7C";
  String beaconThree = "88:3F:4A:E5:FD:C5";
  int scanAttempts = 0;
  List<String> classItems = [];
  var currentClassSelected;


  flutterBlueTestOn(){
    flutterBlue.isOn.then((res){
      if(res.toString() != 'true'){
        setState(() {
          AppResources.showErrorDialog(MODULE_NAME, "The Bluetooth is not activated. Please turn on your bluetooth", context);
        });
        return true;
      }
    else{
      return false;}
    });}
  flutterBlueAvailabilityTest(){
    flutterBlue.isOn.then((res){
      if(res.toString() != 'true'){
        setState(() {
          AppResources.showErrorDialog(MODULE_NAME, "WARNING! This device does not support required bluetooth capabilities!", context);
        });
        return true;}
      else{
        return false;}
    });}

  setStateReady(){
    setState(() {
      isReady = true;
    });
  }

  Future beaconScan() async {
    int beaconOneRssiValue = 0;
    int beaconTwoRssiValue = 0;
    int beaconThreeRssiValue = 0;
    setState(() {
      isReady = false;
    });

    bluetoothScan = flutterBlue.scan().listen((scanResult) {
      int beaconRssiValue = scanResult.rssi;
      if (scanResult.device.id.id == BluetoothView.beaconOne) {beaconOneRssiValue = beaconRssiValue;}
      if (scanResult.device.id.id == BluetoothView.beaconTwo){beaconTwoRssiValue = beaconRssiValue;}
      if (scanResult.device.id.id == BluetoothView.beaconThree){beaconThreeRssiValue = beaconRssiValue;}

      new Future.delayed(const Duration(seconds: 2), () {
          bluetoothScan.cancel();
          if (beaconOneRssiValue < 0){
            if(beaconTwoRssiValue < 0){
              if (beaconThreeRssiValue < 0){
                setState(() {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => StudentMainView()));
                });
              }
              if(beaconThreeRssiValue == 0){
                scanAttempts++;
                beaconThreeRssiValue++;
                AppResources.showErrorDialog(MODULE_NAME, "ERROR, Beacon Three wasnt reached. Please try again", context);
                setStateReady();}
            }
            if(beaconTwoRssiValue == 0){
              scanAttempts++;
              beaconTwoRssiValue++;
              AppResources.showErrorDialog(MODULE_NAME, "ERROR, Beacon Two wasnt reached. Please try again", context);
              setStateReady();}
          }
          if(beaconOneRssiValue == 0){
            scanAttempts++;
            beaconOneRssiValue++;
            AppResources.showErrorDialog(MODULE_NAME, "ERROR, Beacon One wasnt reached. Please try again", context);
            setStateReady();
          }
          if (scanAttempts == 5){
            setStateReady();
            AppResources.showErrorDialog(MODULE_NAME, "ERROR, A beacon wasn't reached after multiple attempts. Please notify an administrator. You may close the app.", context);
          }

      });
      });
  }

  @override
  initState() {
    isReady = false;
    classItems.clear();
    super.initState();
    test();
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return Center(
      child: Column(

          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Image.asset('assets/Benny2.jpg', fit: BoxFit.contain, alignment: Alignment.center),
              height: 200.0,
              alignment: Alignment.center,

            ),
            new Container(
              margin: EdgeInsets.all(20.0),
              child: new Text("This application requires bluetooth to be activated.",
                softWrap: true,
                style: new TextStyle(fontSize: 25.0, color: AppResources.labelTextColor),
              ),
            ),
            Text('Select Class:', style: new TextStyle(color: AppResources.labelTextColor),),
            DropdownButton<String>(
              value : currentClassSelected,
              items: classItems.map((String dropDownStringItem){
                return DropdownMenuItem<String>(
                  value: dropDownStringItem,
                  child: Text(dropDownStringItem),
                );
              }).toList(),
              onChanged: (String newValueSelected){
                setState((){
                  currentClassSelected = newValueSelected;
                });
              },
              iconSize: 50,
            ),
            new Container(
               margin: EdgeInsets.all(25.0),
                child: new RaisedButton(
                  onPressed:beaconScan,
                  child: new Text("Start Session", style: new TextStyle(color: AppResources.buttonTextColor,fontStyle: FontStyle.italic,fontSize: 15.0)),
                  color: AppResources.buttonBackColor,)
            ),
            new Container(
                margin: EdgeInsets.all(25.0),
                child: new RaisedButton(
                  onPressed:test,
                  child: new Text("Test", style: new TextStyle(color: AppResources.buttonTextColor,fontStyle: FontStyle.italic,fontSize: 15.0)),
                  color: AppResources.buttonBackColor,)
            ),
          ]
      ),
    );
  }
  test(){
    APIManager.classRequest().then((response){
      if (response.body.split("{").length>2) {
        int x = 0;
        for(var section in response.body.split("{")){
          if(x >=2){
            classItems.add(section.split(",")[1].split(":")[1].replaceAll('"', "").substring(1));
            print(x);}
          x++;
        }
      }
      if (response.body.split("{").length<=2){
        AppResources.showErrorDialog(MODULE_NAME, "ERROR, \nYou are not in any classes.\nContact administration", context);
      }
      });
    setStateReady();
    }

}