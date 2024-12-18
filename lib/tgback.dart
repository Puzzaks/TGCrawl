import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:async/async.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:graphview/GraphView.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:restart_app/restart_app.dart';
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
  TextEditingController channelSearch = TextEditingController();
  TextEditingController channelFilter = TextEditingController();
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
  bool systemLanguage = false;
  Map dictionary = {};
  String locale = "en";
  bool langReady = false;
  double loginState = 0.0;
  List introSequence = [];
  List introPair = [];
  int introPosition = 0;
  bool switchIntro = false;
  bool isOffline = false;
  bool crowdsource = false;
  late BuildContext localContext;
  late double localWidth;
  late double localHeight;
  String loginInfo = "";
  int userID = 0;
  String userPic = "";
  Map userData = {};
  bool channelNotFound = false;
  bool searchingChannels = false;
  bool loadingSearch = false;


  bool isIndexing = false;
  Map candidateChannel = {};
  Map currentChannel = {};
  Map addedIndexes = {};
  List displayIndexes = [];
  Map indexedChannels = {};
  List unresolvedRelations = [];
  Map knownChannels = {};
  int maxFailsBeforeRetry = 10;
  String indexingStatus = "ready_to_index";
  int autoSaveSeconds = 30;
  int messageBatchSize = 50; //per TDLib limits it should be in the range of [1-50]
  DateTime nextAutoSave = DateTime.now();
  bool isAutoSaving = false;
  bool confirmDelete = false;
  bool loadingChannelData = false;
  Map authors = {};

  int totalIndexed = 0;
  int totalReposts = 0;
  int totalRelations = 0;

  Graph graph = Graph();

  Map graphData = {
    'vertexes': [],
    'edges': [],
  };
  List graphConnections = [];
  Map graphPairs = {};
  List graphDone = [];
  List graphTotal = [];
  bool graphConstructed = false;

  Map displayChannel = {};

  bool isTablet = false;


  void init() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      var sdkInt = androidInfo.version.sdkInt;
      if(sdkInt < 31){
        SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual, overlays: [
          SystemUiOverlay.top, SystemUiOverlay.bottom
        ]);
      }else{
        SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual, overlays: [
          SystemUiOverlay.top
        ]);
      }
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    }
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    getConfigOnline();
    isFirstBoot = await prefs.getBool('first') ?? true;
    notifyListeners();
    if(!isFirstBoot){
      readIndexedChannels();
      crowdsource = await prefs.getBool('crowdsource') ?? false;
      autoSaveSeconds = await prefs.getInt('autoSaveSeconds') ?? 30;
      messageBatchSize = await prefs.getInt('messageBatchSize') ?? 50;
      systemLanguage = await prefs.getBool('systemLanguage') ?? false;
      totalIndexed = await prefs.getInt('totalIndexed') ?? 0;
      totalReposts = await prefs.getInt('totalReposts') ?? 0;
      totalRelations = await prefs.getInt('totalRelations') ?? 0;
      launch();
    }
  }


  decideLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey("language")){
      locale = await prefs.getString("language")??"en";
    }else{
      setSystemLanguage();
    }
  }
  setSystemLanguage() async {
    String deviceLocale = Platform.localeName.split("_")[0];
    for(int a = 0; a < languages.length;a++){
      if(languages[a]["id"] == deviceLocale){
        locale = deviceLocale;
      }
    }
  }

  String dict (String entry){
    if(!dictionary.containsKey(locale)){
      return "Localisation engine FAILED [Default locale not initialized]";
    }
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

  unprogressIntroSequence() async {
    introPosition = introPosition - 1;
        introPair.clear();
        introPair.add(introSequence[introPosition + 1]);
        introPair.add(introSequence[introPosition]);
        switchIntro = false;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 500));
        switchIntro = true;
        introPair.add(introSequence[introPosition]);
        notifyListeners();
  }


  getConfigOnline() async {
    status = "Loading configuration...";
    notifyListeners();
    final intros = await http.get(
      Uri.parse("https://raw.githubusercontent.com/Puzzaks/tgcrawl/master/assets/config/intro.json"),
    );
    if(intros.statusCode == 200){
      introSequence = jsonDecode(intros.body);
      introPair.add(introSequence[introPosition]);
      introPair.add(introSequence[introPosition + 1]);
    }else{
      getConfigOffline();
    }
    status = "Loading dictionaries...";
    notifyListeners();
      final response = await http.get(
        Uri.parse("https://raw.githubusercontent.com/Puzzaks/tgcrawl/master/assets/config/languages.json"),
      );
      if(response.statusCode == 200){
        try {
          languages = jsonDecode(response.body);
        }catch(e){
          getConfigOffline();
        }
        decideLanguage();
        for(int i=0; i < languages.length; i++){
          status = "Downloading ${languages[i]["name"]}";
          notifyListeners();
          final languageGet = await http.get(
            Uri.parse("https://raw.githubusercontent.com/Puzzaks/tgcrawl/master/assets/config/${languages[i]["id"]}.json"),
          );
          if(response.statusCode == 200){
            try{
            dictionary[languages[i]["id"]] = jsonDecode(languageGet.body);
            }catch(e){
              getConfigOffline();
            }
          }else{
            getConfigOffline();
          }
        }
      }else{
        getConfigOffline();
      }
    status = "Loading authors...";
    notifyListeners();
    final authResponse = await http.get(
      Uri.parse("https://raw.githubusercontent.com/Puzzaks/tgcrawl/master/assets/config/authors.json"),
    );
    if(authResponse.statusCode == 200){
      try{
      authors = jsonDecode(authResponse.body);
      }catch(e){
        getConfigOffline();
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
    notifyListeners();
    await rootBundle.loadString('assets/config/intro.json').then((introlist) async {
      introSequence = jsonDecode(introlist);
      introPair.add(introSequence[introPosition]);
      introPair.add(introSequence[introPosition + 1]);
      for(int i=0; i < languages.length; i++){
        await rootBundle.loadString('assets/config/${languages[i]["id"]}.json').then((langentry) async {
          status = "Reading ${languages[i]["name"]}";
          notifyListeners();
          dictionary[languages[i]["id"]] = jsonDecode(langentry);
        });
      }
    });
    status = "Loading dictionaries...";
    notifyListeners();
    await rootBundle.loadString('assets/config/languages.json').then((langlist) async {
        languages = jsonDecode(langlist);
        decideLanguage();
        notifyListeners();
        for(int i=0; i < languages.length; i++){
          await rootBundle.loadString('assets/config/${languages[i]["id"]}.json').then((langentry) async {
            status = "Reading ${languages[i]["name"]}";
            notifyListeners();
            dictionary[languages[i]["id"]] = jsonDecode(langentry);
          });
        }
      });
    await rootBundle.loadString('assets/config/authors.json').then((authlist) async {
      authors = jsonDecode(authlist);
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
        _tdReceiveSubject.add(result);
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

  sendTdLibParams() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    final directory = await getApplicationDocumentsDirectory();
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
  }

  Future <String> getPic(file) async {
    tdSend(_clientId, tdApi.DownloadFile(fileId: file, priority: 1, offset: 0, limit: 0, synchronous: true));
    bool gotPic = false;
    while (!gotPic) {
      var update = await tdReceive(1)?.toJson()??{};
      if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
        PANIC();
      }
      if(update["@type"] == "file"){
        gotPic = true;
        return update["local"]["path"];
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
    return "";
  }

  getLastMessage (channelID, lastMessageID) async {
    bool gotMsgData = false;
    tdSend(_clientId, tdApi.GetMessageLink(chatId: channelID,messageId: lastMessageID, mediaTimestamp: 0, forAlbum: true, inMessageThread: false));
    while (!gotMsgData) {
      var update = (await tdReceive(1)?.toJson())!;
      if(!(update == null)){
        if(update["@type"] == "messageLink"){
          gotMsgData = true;
          currentChannel["lastmsgid"] =  update["link"].replaceAll("https://t.me/","").split("/")[1];
          notifyListeners();
        }
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  refresh(){
    notifyListeners();
  }
  getIndexing() async {
    while (true) {
      bool gotNext = false;
      if(isIndexing && unresolvedRelations.isEmpty && !isAutoSaving && !loadingChannelData){
        indexingStatus = "reading_channel";
        notifyListeners();
        gotNext = false;
        tdSend(_clientId, tdApi.GetChatHistory(chatId: currentChannel["id"], fromMessageId: currentChannel.containsKey("lastindexed")?currentChannel["lastindexed"]:0, offset: 0, limit: messageBatchSize, onlyLocal: false));
        while (!gotNext) {
          var update = await tdReceive(1)?.toJson()??{};
          if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
            PANIC();
          }
          if(update["@type"] == "messages"){
            if(update["total_count"] == 0){
              isIndexing = false;
              gotNext = true;
              currentChannel["isDone"] = true;
              currentChannel["donepercent"] = 100;
              notifyListeners();
            }else{
              for(int m = 0;m < update["messages"].length;m++){
                totalIndexed ++;
                currentChannel["donepercent"] = (((currentChannel.containsKey("lastindexedid") ? currentChannel["lastindexedid"] : 0)/(currentChannel.containsKey("lastmsgid") ? int.parse(currentChannel["lastmsgid"]) : 0)) * 100);
                currentChannel["isDone"] = false;
                currentChannel["lastindexedid"] = currentChannel.containsKey("lastindexedid")?currentChannel["lastindexedid"]+1:1;
                currentChannel["lastindexed"] = update["messages"][m]["id"];
                if(update["messages"][m]["forward_info"] == null){}else{
                  if(update["messages"][m]["forward_info"]["origin"]["chat_id"] == null){}else{
                    totalReposts ++;
                    addRelationToChannel(currentChannel["id"], update["messages"][m]["forward_info"]["origin"]["chat_id"], update["messages"][m]);
                    graphConnections.add(currentChannel["id"].toString());
                  }
                }
                notifyListeners();
              }
              gotNext = true;
              notifyListeners();
            }
          }
          await Future.delayed(Duration(milliseconds: 100));
        }
        await Future.delayed(Duration(milliseconds: 100));
      }else{
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }
  resolveRelations() async {
    bool saved = false;
    while(true){
      if(unresolvedRelations.isNotEmpty){
        indexingStatus = "resolving_related_channel";
        notifyListeners();
        if(knownChannels.containsKey(unresolvedRelations[0])){
          if(knownChannels[unresolvedRelations[0]].containsKey("title") && knownChannels[unresolvedRelations[0]].containsKey("id")){
            unresolvedRelations.removeAt(0);
          }
        }else{
          saved = false;
          await retreiveFullRelatedChannelInfo(unresolvedRelations[0]);
          unresolvedRelations.removeAt(0);
        }
      }else{
        if(!saved){
          saveAll();
          saved = true;
        }
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  saveAll() async {
    print("========= STATE: SAVING =========");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(currentChannel.isNotEmpty){
      await updateIndexedChannels(currentChannel["id"].toString(), currentChannel);
    }

    prefs.setInt("totalIndexed", totalIndexed);
    prefs.setInt("totalReposts", totalReposts);
    prefs.setInt("totalRelations", totalRelations);
    prefs.setBool("crowdsource", crowdsource);
    prefs.setString("language", locale);
    prefs.setBool("systemLanguage", systemLanguage);
    prefs.setInt("autoSaveSeconds", autoSaveSeconds);
    prefs.setInt("messageBatchSize", messageBatchSize);
    prefs.setString("addedIndexes", jsonEncode(addedIndexes));
    prefs.setString("knownChannels", jsonEncode(knownChannels));
  }
  autoSave() async {
    while(true){
      if(DateTime.now().isAfter(nextAutoSave) && isIndexing){
        isAutoSaving = true;
        indexingStatus = "saving";
        notifyListeners();
        await saveAll();
        nextAutoSave = DateTime.now().add(Duration(seconds: autoSaveSeconds));
        isAutoSaving = false;
        notifyListeners();
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  createGraph() async {
    graph = Graph();
    graphConstructed = false;
    graphDone.clear();
    graphTotal.clear();
    graphPairs.clear();
    if(addedIndexes.isNotEmpty){
      graphConnections.add(addedIndexes.keys.toList()[0].toString());
      graphTotal.add(addedIndexes.keys.toList()[0].toString());
    }
    notifyListeners();
  }
  buildEdge(from, to){
    graph.addEdge(Node.Id(from), Node.Id(to),paint: Paint()..strokeWidth = 0.1..color = Theme.of(localContext).colorScheme.primary..strokeCap = StrokeCap.round);
  }

  iterateConnections() async {
      while(true){
        if(!isIndexing){
          if(graphConnections.isNotEmpty) {
            addConnections(graphConnections[0]);
            graphConstructed = false;
            notifyListeners();
            if(!addedIndexes.containsKey(graphConnections[0].toString()) && !knownChannels.containsKey(graphConnections[0].toString())){
              unresolvedRelations.add(graphConnections[0].toString());
            }
            graphConnections.removeAt(0);
          }else{
            if(graphConstructed == false){
              graphConstructed = true;
              notifyListeners();
              await Future.delayed(Duration(milliseconds: 100));
            }
          }
        }else{
          await Future.delayed(Duration(milliseconds: 100));
        }
        await Future.delayed(Duration(milliseconds: 100));
      }
  }

  addConnections(channelRaw) async {
    String channel = channelRaw.toString();
    if(!graph.contains(node: Node.Id(channel)) && !graphDone.contains(channel)){
      graph.addNode(Node.Id(channel)..size = Size(5,5));
      if(!graphPairs.containsKey(channel)){
        graphPairs[channel] = [];
      }
    }
    if(addedIndexes.containsKey(channel)){
      if(addedIndexes[channel].containsKey("relations")){
        for(int i = 0; i < addedIndexes[channel]["relations"].length; i++){
          String addedIndex = addedIndexes[channel]["relations"].keys.toList()[i].toString();
            if(!(graph.contains(edge: Edge(Node.Id(channel), Node.Id(addedIndex))) && graph.contains(edge: Edge(Node.Id(addedIndex), Node.Id(channel))))){
              buildEdge(channel, addedIndex);
              graphTotal.add(addedIndex);
              graphConnections.add(addedIndex);
              if(!graphPairs.containsKey(channel)){
                graphPairs[channel] = [];
              }
              graphPairs[channel].add(addedIndex);
            }
        }
      }
    }
    graphDone.add(channel);
    notifyListeners();
  }


  addRelationToChannel(channelID, relatedChannelID, message) async {
    if(!currentChannel.containsKey("reposts")) {
      currentChannel["reposts"] = 1;
    }else{
      currentChannel["reposts"] ++;
    }
    if(!currentChannel.containsKey("relations")) {
      currentChannel["relations"] = {};
    }
    if(currentChannel["relations"].containsKey(relatedChannelID.toString())){
      currentChannel["relations"][relatedChannelID.toString()]["firstrepost"] = message["date"];
      currentChannel["relations"][relatedChannelID.toString()]["reposts"] ++;
    }else{
      totalRelations ++;
      currentChannel["relations"][relatedChannelID.toString()] = {};
      currentChannel["relations"][relatedChannelID.toString()]["lastrepost"] = message["date"];
      currentChannel["relations"][relatedChannelID.toString()]["reposts"] = 1;
      if(!knownChannels.containsKey(message["forward_info"]["origin"]["chat_id"].toString())) {
        unresolvedRelations.add(message["forward_info"]["origin"]["chat_id"].toString());
      }else{
        Map relation = knownChannels[message["forward_info"]["origin"]["chat_id"].toString()];
      }
    }
    await updateIndexedChannels(currentChannel["id"], currentChannel);
  }

  getUsernameAndSubs(superID) async {
    tdSend(_clientId, tdApi.GetSupergroup(supergroupId: superID));
    bool gotMsgs = false;
    while (!gotMsgs) {
      var update = await tdReceive(1)?.toJson()??{};
      if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
        PANIC();
      }
      if(update["@type"] == "supergroup"){
        gotMsgs = true;
        currentChannel["username"] = update["usernames"]["editable_username"];
        currentChannel["subs"] =  update["member_count"];
        notifyListeners();
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
  getRelatedUsernameAndSubs(superID, relationID) async {
    tdSend(_clientId, tdApi.GetSupergroup(supergroupId: superID));
    int failCounter = 0;
    bool gotMsgs = false;
    while (!gotMsgs) {
      if(failCounter > maxFailsBeforeRetry){
        gotMsgs = true;
        unresolvedRelations.add(relationID.toString());
      }
      var update = await tdReceive(1)?.toJson()??{};
      if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
        PANIC();
      }
      if(update["@type"] == "supergroup"){
        gotMsgs = true;
        if(update["usernames"] == null){
          knownChannels[relationID.toString()]["username"] = "deleted";
        }else{
          knownChannels[relationID.toString()]["username"] = update["usernames"]["editable_username"];
        }
        knownChannels[relationID.toString()]["subs"] =  update["member_count"];
        notifyListeners();
      }else{
        failCounter++;
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  retreiveFullRelatedChannelInfo (id) async {
    bool gotChat = false;
    int failCounter = 0;
    tdSend(_clientId, tdApi.GetChat(chatId: int.parse(id)));
    while (!gotChat) {
      if(failCounter > maxFailsBeforeRetry){
        unresolvedRelations.add(id);
        gotChat = true;
      }
      var update = await tdReceive(1)?.toJson()??{};
      if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
        PANIC();
      }
      if(update["@type"] == "chat"){
        gotChat = true;
        if(!knownChannels.containsKey(update["id"].toString())){
          knownChannels[update["id"].toString()] = {};
        }
        knownChannels[update["id"].toString()]["id"] = update["id"];
        knownChannels[update["id"].toString()]["title"] = update["title"];
        knownChannels[update["id"].toString()]["supergroupid"] = update["type"]["supergroup_id"];
        if(update["photo"]==null){
          knownChannels[update["id"].toString()]["picfile"] = "NOPIC";
        }else{
          await getPic(update["photo"]["big"]["id"]).then((file){
            knownChannels[update["id"].toString()]["picfile"] = file;
          });
        }
        await getRelatedUsernameAndSubs(update["type"]["supergroup_id"], update["id"]);
      }else{
        failCounter ++;
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  retreiveFullChannelInfo (id) async {
    loadingChannelData = true;
    tdSend(_clientId, tdApi.GetChat(chatId: id));
    bool gotChat = false;
    while (!gotChat) {
      var update = await tdReceive(1)?.toJson()??{};
      if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
        PANIC();
      }
      if(update["@type"] == "chat"){
        currentChannel["supergroupid"] = update["type"]["supergroup_id"];
        gotChat = true;
        await getLastMessage(id, update["last_message"]["id"]);
        await getUsernameAndSubs(update["type"]["supergroup_id"]);
        updateIndexedChannels(id.toString(), currentChannel);
        loadingChannelData = false;
        notifyListeners();
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  updateIndexedChannels (channelID, Map channelData) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    addedIndexes[channelID.toString()] = channelData;
    prefs.setString("addedIndexes", jsonEncode(addedIndexes));
  }
  deleteIndexedChannel (channelID) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    addedIndexes.remove(channelID.toString());
    prefs.setString("addedIndexes", jsonEncode(addedIndexes));
    filterIndexedChannels();
  }
  readIndexedChannels () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.containsKey("addedIndexes")){
      addedIndexes = await jsonDecode(prefs.getString("addedIndexes")??"{}");
    }
    if(prefs.containsKey("knownChannels")){
      knownChannels = await jsonDecode(prefs.getString("knownChannels")??"{}");
    }
    filterIndexedChannels();
  }

  checkFilter (key, channelData){
    if(key.trim() == ""){
      return true;
    }
    if(channelData["id"].toString().contains(key)){
      return true;
    }
    if(channelData["title"].toLowerCase().contains(key.toLowerCase().replaceAll("@", "").replaceAll("https://t.me/", ""))){
      return true;
    }
    return false;
  }
  filterIndexedChannels (){
    String searchTerm = channelFilter.text;
    displayIndexes.clear();
    for(int i = 0; i < addedIndexes.length; i++){
      if(checkFilter(searchTerm, addedIndexes[addedIndexes.keys.toList()[i]])){
        displayIndexes.add(addedIndexes[addedIndexes.keys.toList()[i]]);
      }
    }
    notifyListeners();
  }

  searchChannel() async {
    if(channelSearch.text.length >= 5){
      candidateChannel = {};
      loadingSearch = true;
      channelNotFound = true;
      notifyListeners();
      bool gotChannel = false;
      tdSend(_clientId, tdApi.SearchPublicChat(username: channelSearch.text.replaceAll("@", "").replaceAll("https://t.me/", "").trim()));
      while (!gotChannel) {
        var update = (await tdReceive(1)?.toJson())!;
        if(update["@type"] == "error"){
          candidateChannel = {};
          gotChannel = true;
          loadingSearch = false;
          channelNotFound = true;
          notifyListeners();
        }
        if(update["@type"] == "chat"){
          if(update["type"]["is_channel"]){
            candidateChannel["title"] = update["title"];
            candidateChannel["id"] = update["id"];
            candidateChannel["username"] = channelSearch.text.replaceAll("@", "").replaceAll("https://t.me/", "").trim();
            if(update["photo"] == null){
              candidateChannel["picfile"] = "NOPIC";
            }else{
              await getPic(update["photo"]["big"]["id"]).then((file){
                candidateChannel["picfile"] = file;
              });
            }
            gotChannel = true;
            loadingSearch = false;
            channelNotFound = false;
            notifyListeners();
          }
        }
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  handleLoggedIn() async {
    doReadUpdates = false;
    tdSend(_clientId,tdApi.GetMe());
    bool gotUser = false;
    while (!gotUser) {
      var update = await tdReceive(1)?.toJson()??{};
      if (update.toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
        PANIC();
      }
      if(update["@type"] == "user"){
        userData = update;
        if(update["profile_photo"] == null){
          userPic = "NOPIC";
        }else{
          await getPic(update["profile_photo"]["big"]["id"]).then((file){
            userPic = file;
          });
        }
        notifyListeners();
        gotUser = true;

        createGraph();
        getIndexing();
        resolveRelations();
        autoSave();
        iterateConnections();
      }
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  PANIC() async {
    await Fluttertoast.showToast(
      msg: "Fatal TDLib error, open the app again please.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
    exit(0);
  }

  Future<void> launch () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final tdlibPath = (Platform.isAndroid || Platform.isLinux || Platform.isWindows) ? 'libtdjson.so' : null;
    await TdPlugin.initialize(tdlibPath);
    _clientId = tdCreate();
    TdPlugin.instance.removeLogMessageCallback();
    _tdReceiveSubscription = _tdReceiveSubject.stream.listen((updateRaw) async {
      var update = updateRaw?.toJson().cast<dynamic, dynamic>();
      if(!(update == null)) {
        if (updateRaw.toJson().toString().contains('{@type: error, code: 400, message: Can\'t lock file')) {
          PANIC();
        }
        switch (jsonDecode(jsonify(raw: update.toString()))["@type"]) {
          case "updateOption":
            if (jsonDecode(jsonify(raw: update.toString()))["name"].toString() == "my_id") {
              userID = int.parse(jsonDecode(jsonify(raw: update.toString()))["value"]["value"]);
              notifyListeners();
            }
            break;
          case "authorizationStateWaitCode":
            loginState = 0.5;
            isWaitingCode = true;
            isWaitingNumber = false;
            doReadUpdates = false;
            notifyListeners();
            break;
          case "updateAuthorizationState":
            switch (jsonDecode(jsonify(raw: update.toString()))["authorization_state"]["@type"]) {
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
                sendTdLibParams();
                break;
              case"authorizationStateReady":
                prefs.setBool('LoggedIn', true);
                loginState = 1;
                isWaitingPassword = false;
                isWaitingCode = false;
                isWaitingNumber = false;
                doReadUpdates = false;
                isLoggedIn = true;
                notifyListeners();
                handleLoggedIn();
                break;
            }
            break;
      }
        updates.insert(0, update);
        notifyListeners();
      }
    });
    sendTdLibParams();
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