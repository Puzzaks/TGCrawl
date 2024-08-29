import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:async/async.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tdlib/td_client.dart';
import 'package:tdlib/td_api.dart' as tdApi;
import 'package:tdlib/tdlib.dart';

class tgProvider with ChangeNotifier {
  TextEditingController number = TextEditingController();
  TextEditingController code = TextEditingController();
  TextEditingController password = TextEditingController();
  bool isLoggedIn = false;
  bool isWaitingPassword = false;
  bool isWaitingCode = false;
  bool isWaitingNumber = false;
  List updates = [];
  int _clientId = 0;
  Map lastUpdate = {};
  String status = "Loading TDLib";
  int authAt = 0;
  bool doReadUpdates = true;
  RestartableTimer fetchTimer = RestartableTimer(Duration(seconds: 10), (){});
  final _tdReceiveSubject = BehaviorSubject();
  StreamSubscription? _tdReceiveSubscription;

  void startTdReceiveUpdates() async {
    while (doReadUpdates) {
      var result = await tdReceive(1);
      _tdReceiveSubject.add(result?.toJson().cast<dynamic, dynamic>());
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  String jsonify({required String raw}) {
    String jsonString = raw;

    /// add quotes to json string
    jsonString = jsonString.replaceAll('{', '{"');
    jsonString = jsonString.replaceAll(': ', '": "');
    jsonString = jsonString.replaceAll(', ', '", "');
    jsonString = jsonString.replaceAll('}', '"}');

    /// remove quotes on object json string
    jsonString = jsonString.replaceAll('"{"', '{"');
    jsonString = jsonString.replaceAll('"}"', '"}');

    /// remove quotes on array json string
    jsonString = jsonString.replaceAll('"[{', '[{');
    jsonString = jsonString.replaceAll('}]"', '}]');

    return jsonString;
  }

  Future<void> launch () async {
    final directory = await getApplicationDocumentsDirectory();
    final tdlibPath = (Platform.isAndroid || Platform.isLinux || Platform.isWindows) ? 'libtdjson.so' : null;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    await TdPlugin.initialize(tdlibPath);
    _clientId = tdCreate();
    _tdReceiveSubscription = _tdReceiveSubject.stream.listen((update) {
      if(!(update == null)){
        switch (jsonDecode(jsonify(raw: update.toString()))["@type"]){
          case "updateAuthorizationState":
            switch (jsonDecode(jsonify(raw: update.toString()))["authorization_state"]["@type"]){
              case "authorizationStateWaitPassword":
                isWaitingPassword = true;
                status = "Waiting for password";
                break;
              case "authorizationStateWaitPhoneNumber":
                isWaitingNumber = true;
                doReadUpdates = false;
                updates.clear();
                break;
              case "authorizationStateWaitTdlibParameters":
                status = "Connecting... (${updates.length})";
                tdSend(_clientId, tdApi.SetTdlibParameters(
                  systemVersion: 'Android ${androidInfo.version.baseOS}',
                  useTestDc: false,
                  useSecretChats: false,
                  useMessageDatabase: true,
                  useFileDatabase: true,
                  useChatInfoDatabase: true,
                  filesDirectory: "${directory.path}/files",
                  databaseDirectory: "${directory.path}/DB",
                  systemLanguageCode: Platform.localeName.split("_")[0],
                  deviceModel: "${androidInfo.brand} ${androidInfo.model}",
                  applicationVersion: '0.69',
                  apiId: 3435077,
                  apiHash: "0369c1a073f7c720ca79508156201f3a",
                  databaseEncryptionKey: '0369c1a073f7c720ca79508156201f3a',
                  enableStorageOptimizer: false,
                  ignoreFileNames: false,
                ));
                break;
              case"authorizationStateWaitCode":
                isWaitingCode = true;
                notifyListeners();
                break;
              case"authorizationStateReady":
                isLoggedIn = true;
                doReadUpdates = false;
                notifyListeners();
                break;
            }
            break;
        }
        updates.insert(0, update);
        notifyListeners();
      }
    });
    tdSend(_clientId, tdApi.SetTdlibParameters(
      systemVersion: 'Android ${androidInfo.version}',
      useTestDc: false,
      useSecretChats: false,
      useMessageDatabase: true,
      useFileDatabase: true,
      useChatInfoDatabase: true,
      filesDirectory: "${directory.path}/files",
      databaseDirectory: "${directory.path}/DB",
      systemLanguageCode: Platform.localeName.split("_")[0],
      deviceModel: "${androidInfo.brand} ${androidInfo.model}",
      applicationVersion: '0.69',
      apiId: 3435077,
      apiHash: "0369c1a073f7c720ca79508156201f3a",
      databaseEncryptionKey: '0369c1a073f7c720ca79508156201f3a',
      enableStorageOptimizer: false,
      ignoreFileNames: false,
    ));

    startTdReceiveUpdates();
  }
  doCodeLogin(){
    tdSend(_clientId, tdApi.CheckAuthenticationCode(
        code: code.text
    ));
    doReadUpdates = true;
    updates.clear();
  }
  doNumberLogin(){
    tdSend(_clientId,tdApi.SetAuthenticationPhoneNumber(
        phoneNumber: number.text,
        settings: tdApi.PhoneNumberAuthenticationSettings(
            allowFlashCall: false,
            allowMissedCall: false,
            isCurrentPhoneNumber: true,
            allowSmsRetrieverApi: true,
            authenticationTokens: ["Test"]
        )
    ));
    doReadUpdates = true;
    updates.clear();
  }
  doPwdLogin(){
    tdSend(_clientId, tdApi.CheckAuthenticationPassword(
        password: password.text
    ));
    doReadUpdates = true;
    updates.clear();
  }

  readChannel(id){
    status ="Attempting to read channel";
    notifyListeners();
    tdSend(_clientId, tdApi.GetMessages(
        chatId: id,
      messageIds: [0,1,2,3,4,5],
    ));
    doReadUpdates = true;
    updates.clear();
  }
}