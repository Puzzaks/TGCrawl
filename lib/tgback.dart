import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:async/async.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tdlib/td_client.dart';
import 'package:tdlib/td_api.dart' as tdApi;
import 'package:tdlib/tdlib.dart';
import 'package:http/http.dart' as http;

class tgProvider with ChangeNotifier {
  TextEditingController languageSelector = TextEditingController();
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
  bool isFirstBoot = true;
  List languages = [];
  Map dictionary = {};
  String locale = "en";
  bool langReady = false;
  double langState = 0.0;
  double loginState = 0.0;
  List introSequence = [];
  List introPair = [];
  int introPosition = 0;
  bool switchIntro = false;
  bool isOffline = false;
  late BuildContext localContext;
  late double localWidth;
  late double localHeight;

  void init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String tempLocale = "";
    String deviceLocale = Platform.localeName.split("_")[0];
    for(int a = 0; a < languages.length;a++){
      if(languages[a]["id"] == deviceLocale){
        tempLocale = deviceLocale;
      }
    }
    isFirstBoot = await prefs.getBool('first') ?? true;
    locale = prefs.getString("language")??tempLocale;
    notifyListeners();
    if(kReleaseMode){
      getConfigOnline();
    }else{
      getConfigOffline();
    }
    if(!isFirstBoot){
      launch();
    }
  }


  String dict (String entry){
    if(!dictionary[locale].containsKey(entry)){
      return "[EN] ${dictionary["en"][entry].toString()}";
    }
    return dictionary[locale][entry].toString();
  }

  progressIntroSequence() async {
    introPosition = introPosition + 1;
    switchIntro = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    switchIntro = false;
    introPair.clear();
    introPair.add(introSequence[introPosition]);
    introPair.add(introSequence[introPosition + 1]);
    notifyListeners();
  }

  getConfigOnline() async {
    status = "Loading configuration...";
    langState = 1 / (languages.length + 2);
    notifyListeners();
    final intros = await http.get(
      Uri.parse("https://raw.githubusercontent.com/Puzzak/tgcrawl/master/assets/config/intro.json"),
    );
    if(intros.statusCode == 200){
      notifyListeners();
      introSequence = jsonDecode(intros.body);
      introPair.add(introSequence[introPosition]);
      introPair.add(introSequence[introPosition + 1]);
    }else{
      getConfigOffline();
    }
    status = "Loading dictionaries...";
    notifyListeners();
      final response = await http.get(
        Uri.parse("https://raw.githubusercontent.com/Puzzak/tgcrawl/master/assets/config/languages.json"),
      );
      if(response.statusCode == 200){
        langState = 2 / (languages.length + 2);
        notifyListeners();
        languages = jsonDecode(response.body);
        for(int i=0; i < languages.length; i++){
          status = "Downloading ${languages[i]["name"]}";
          langState = (languages.length + 2) / (i+2);
          notifyListeners();
          final languageGet = await http.get(
            Uri.parse("https://raw.githubusercontent.com/Puzzak/tgcrawl/master/assets/config/${languages[i]["id"]}.json"),
          );
          if(response.statusCode == 200){
            dictionary[languages[i]["id"]] = jsonDecode(languageGet.body);
          }else{
            getConfigOffline();
          }
        }
      }else{
        getConfigOffline();
      }
    await Future.delayed(const Duration(milliseconds: 500));
    status = "Dictionary loaded!";
    langReady = true;
    notifyListeners();
  }
  getConfigOffline() async {
    isOffline = true;
    status = "Loading configuration...";
    langState = 1 / (languages.length + 2);
    notifyListeners();
    await rootBundle.loadString('assets/config/intro.json').then((introlist) async {
      introSequence = jsonDecode(introlist);
      introPair.add(introSequence[introPosition]);
      introPair.add(introSequence[introPosition + 1]);
      langState = 2 / (languages.length + 2);
      notifyListeners();
      for(int i=0; i < languages.length; i++){
        await rootBundle.loadString('assets/config/${languages[i]["id"]}.json').then((langentry) async {
          status = "Reading ${languages[i]["name"]}";
          langState = (languages.length + 2) / (i+2);
          notifyListeners();
          dictionary[languages[i]["id"]] = jsonDecode(langentry);
        });
      }
    });
    status = "Loading dictionaries...";
    notifyListeners();
      await rootBundle.loadString('assets/config/languages.json').then((langlist) async {
        languages = jsonDecode(langlist);
        langState = 1 / (languages.length + 1);
        notifyListeners();
        for(int i=0; i < languages.length; i++){
          await rootBundle.loadString('assets/config/${languages[i]["id"]}.json').then((langentry) async {
            status = "Reading ${languages[i]["name"]}";
            langState = (languages.length + 1) / (i+1);
            notifyListeners();
            dictionary[languages[i]["id"]] = jsonDecode(langentry);
          });
        }
      });
    await Future.delayed(const Duration(milliseconds: 500));
    status = "Dictionary loaded!";
    langReady = true;
    notifyListeners();
  }

  void startTdReceiveUpdates() async {
    while (true) {
      if(doReadUpdates){
        var result = await tdReceive(1);
        _tdReceiveSubject.add(result?.toJson().cast<dynamic, dynamic>());
        await Future.delayed(Duration(milliseconds: 100));
      }else{
        await Future.delayed(Duration(milliseconds: 100));
      }
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

    /// fix very fucked bug that was hurting me
    jsonString = jsonString.replaceAll('}}"}', '}}}');

    return jsonString;
  }

  Future<void> launch () async {
    final directory = await getApplicationDocumentsDirectory();
    directory.deleteSync(recursive: true);
    final tdlibPath = (Platform.isAndroid || Platform.isLinux || Platform.isWindows) ? 'libtdjson.so' : null;
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    await TdPlugin.initialize(tdlibPath);
    _clientId = tdCreate();
    _tdReceiveSubscription = _tdReceiveSubject.stream.listen((update) {
      if(!(update == null)){
        switch (jsonDecode(jsonify(raw: update.toString()))["@type"]){
          case "authorizationStateWaitCode":
            loginState = 0.5;
            isWaitingCode = true;
            isWaitingNumber = false;
            doReadUpdates = false;
            notifyListeners();
            break;
          case "updateAuthorizationState":
            switch (jsonDecode(jsonify(raw: update.toString()))["authorization_state"]["@type"]){
              case "authorizationStateWaitPassword":
                loginState = 0.75;
                isWaitingPassword = true;
                isWaitingCode = false;
                doReadUpdates = false;
                notifyListeners();
                break;
              case "authorizationStateWaitPhoneNumber":
                loginState = 0.25;
                isWaitingNumber = true;
                doReadUpdates = false;
                notifyListeners();
                break;
              case "authorizationStateWaitCode":
                loginState = 0.5;
                isWaitingCode = true;
                isWaitingNumber = false;
                doReadUpdates = false;
                notifyListeners();
                break;
              case "authorizationStateWaitTdlibParameters":
                loginState = 0.0;
                status = "Connecting... (${updates.length})";
                tdSend(_clientId, tdApi.SetTdlibParameters(
                  systemVersion: '${androidInfo.version.baseOS} ${androidInfo.version.release}',
                  useTestDc: false,
                  useSecretChats: false,
                  useMessageDatabase: true,
                  useFileDatabase: true,
                  useChatInfoDatabase: true,
                  filesDirectory: "${directory.path}/files",
                  databaseDirectory: "${directory.path}/DB",
                  systemLanguageCode: Platform.localeName.split("_")[0],
                  deviceModel: "${androidInfo.manufacturer} ${androidInfo.model}",
                  applicationVersion: '0.69',
                  apiId: 3435077,
                  apiHash: "0369c1a073f7c720ca79508156201f3a",
                  databaseEncryptionKey: '0369c1a073f7c720ca79508156201f3a',
                  enableStorageOptimizer: false,
                  ignoreFileNames: false,
                ));
                break;
              case"authorizationStateReady":
                loginState = 1;
                isWaitingPassword = false;
                isWaitingCode = false;
                isWaitingNumber = false;
                doReadUpdates = false;
                isLoggedIn = true;
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
      systemVersion: '${androidInfo.version.baseOS} ${androidInfo.version.release}',
      useTestDc: false,
      useSecretChats: false,
      useMessageDatabase: true,
      useFileDatabase: true,
      useChatInfoDatabase: true,
      filesDirectory: "${directory.path}/files",
      databaseDirectory: "${directory.path}/DB",
      systemLanguageCode: Platform.localeName.split("_")[0],
      deviceModel: "${androidInfo.manufacturer} ${androidInfo.model}",
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
    loginState = 0.0;
    notifyListeners();
    doReadUpdates = true;
    tdSend(_clientId, tdApi.CheckAuthenticationCode(
        code: code.text
    ));
  }
  doNumberLogin(){
    loginState = 0.0;
    notifyListeners();
    doReadUpdates = true;
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
  }
  doPwdLogin(){
    loginState = 0.0;
    notifyListeners();
    doReadUpdates = true;
    tdSend(_clientId, tdApi.CheckAuthenticationPassword(
        password: password.text
    ));
  }

  readChannel(id){
    doReadUpdates = true;
    status ="Attempting to read channel";
    notifyListeners();
    tdSend(_clientId, tdApi.GetMessages(
        chatId: id,
      messageIds: [0,1,2,3,4,5],
    ));
  }
}