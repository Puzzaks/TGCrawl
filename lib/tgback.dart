import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tdlib/td_client.dart';
import 'package:tdlib/td_api.dart' as tdApi;
import 'package:tdlib/tdlib.dart';

class tgProvider with ChangeNotifier {
  TextEditingController botkey = TextEditingController();
  bool isAppReady = false;
  bool isLoginReady = false;
  bool isPassLoginReady = false;
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
    await TdPlugin.initialize(tdlibPath);
    _clientId = tdCreate();
    _tdReceiveSubscription = _tdReceiveSubject.stream.listen((update) {
      if(!(update == null)){
        switch (jsonDecode(jsonify(raw: update.toString()))["@type"]){
          case "authorizationStateWaitPassword":
            isPassLoginReady = true;
            isLoginReady = true;
            status = "Waiting for password";
            break;
          case "ok":
            isLoginReady = true;
            status = "Authenticated! (${updates.length})";
        // doReadUpdates = false;
        // readChannel(1001474478067);
        break;
          case "updateAuthorizationState":
            switch (jsonDecode(jsonify(raw: update.toString()))["authorization_state"]["@type"]){
              case "authorizationStateWaitPhoneNumber":
                isAppReady = true;
                // tdSend(_clientId, tdApi.CheckAuthenticationBotToken(token: '6808342978:AAH8iWAX6cntl6-RCZLEF4obO0hx0UYotEQ'));
                tdSend(_clientId,tdApi.SetAuthenticationPhoneNumber(
                    phoneNumber: "380993072873",
                    settings: tdApi.PhoneNumberAuthenticationSettings(
                        allowFlashCall: false,
                        allowMissedCall: false,
                        isCurrentPhoneNumber: true,
                        allowSmsRetrieverApi: true,
                        authenticationTokens: ["Test"]
                    )
                ));
                status = "Ready to Authenticate! (${updates.length})";

                doReadUpdates = true;
                updates.clear();
                break;
              case "authorizationStateWaitTdlibParameters":
                status = "Connecting... (${updates.length})";
                tdSend(_clientId, tdApi.SetTdlibParameters(
                  systemVersion: '',
                  useTestDc: false,
                  useSecretChats: false,
                  useMessageDatabase: true,
                  useFileDatabase: true,
                  useChatInfoDatabase: true,
                  filesDirectory: "${directory.path}/files",
                  databaseDirectory: "${directory.path}/DB",
                  systemLanguageCode: 'en',
                  deviceModel: 'unknown',
                  applicationVersion: '1.0.0',
                  apiId: 3435077,
                  apiHash: "0369c1a073f7c720ca79508156201f3a",
                  databaseEncryptionKey: '0369c1a073f7c720ca79508156201f3a',
                  enableStorageOptimizer: false,
                  ignoreFileNames: false,
                ));
                break;
            }
            break;
        }
        updates.insert(0, update);
        notifyListeners();
      }
    });
    tdSend(_clientId, tdApi.SetTdlibParameters(
      systemVersion: '',
      useTestDc: false,
      useSecretChats: false,
      useMessageDatabase: true,
      useFileDatabase: true,
      useChatInfoDatabase: true,
      filesDirectory: "${directory.path}/files",
      databaseDirectory: "${directory.path}/DB",
      systemLanguageCode: 'en',
      deviceModel: 'unknown',
      applicationVersion: '1.0.0',
      apiId: 3435077,
      apiHash: "0369c1a073f7c720ca79508156201f3a",
      databaseEncryptionKey: '0369c1a073f7c720ca79508156201f3a',
      enableStorageOptimizer: false,
      ignoreFileNames: false,
    ));

    startTdReceiveUpdates();
  }
  doCodeLogin(){
    status ="Attempting to authorize with code...";
    notifyListeners();
    tdSend(_clientId, tdApi.CheckAuthenticationCode(
        code: botkey.text
    ));
    doReadUpdates = true;
    updates.clear();
  }
  doPwdLogin(){
    status ="Attempting to authorize with password...";
    notifyListeners();
    tdSend(_clientId, tdApi.CheckAuthenticationPassword(
        password: botkey.text
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