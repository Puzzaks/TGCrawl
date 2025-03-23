import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:async/async.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:graphview/GraphView.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool isNumberCorrect = false;
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

  bool isFileSaved = false;
  bool isFileRequested = false;

  Color appBGColor = Colors.transparent;

  Map numberValidation = {"valid": false, "info": "enter_number_empty", "error": ""};
  Map codeValidation = {"valid": false, "info": "enter_code_empty", "error": ""};

  Future<void> setOverlays (Color bcColor) async {
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
          SystemUiOverlay.top, SystemUiOverlay.bottom
        ]);
      }
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: bcColor,
            systemNavigationBarIconBrightness: Brightness.dark
        ),
      );
    }
    notifyListeners();
  }
  void init() async {
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

  validateNumber(number){
    numberValidation = numberValidator(number);
    notifyListeners();
  }

  validateCode(code){
    codeValidation = codeValidator(code);
    notifyListeners();
  }

  Map<String, dynamic> numberValidator(String input) {
    if(input.length == 0){
      return {"valid": false, "info": "enter_number_empty", "error": ""};
    }
    const String countryCodesJson = '''
  [
    {"name": "Afghanistan", "dial_code": "+93", "code": "AF"},
    {"name": "Aland Islands", "dial_code": "+358", "code": "AX"},
    {"name": "Albania", "dial_code": "+355", "code": "AL"},
    {"name": "Algeria", "dial_code": "+213", "code": "DZ"},
    {"name": "AmericanSamoa", "dial_code": "+1684", "code": "AS"},
    {"name": "Andorra", "dial_code": "+376", "code": "AD"},
    {"name": "Angola", "dial_code": "+244", "code": "AO"},
    {"name": "Anguilla", "dial_code": "+1264", "code": "AI"},
    {"name": "Antigua and Barbuda", "dial_code": "+1268", "code": "AG"},
    {"name": "Argentina", "dial_code": "+54", "code": "AR"},
    {"name": "Armenia", "dial_code": "+374", "code": "AM"},
    {"name": "Aruba", "dial_code": "+297", "code": "AW"},
    {"name": "Australia", "dial_code": "+61", "code": "AU"},
    {"name": "Austria", "dial_code": "+43", "code": "AT"},
    {"name": "Azerbaijan", "dial_code": "+994", "code": "AZ"},
    {"name": "Bahrain", "dial_code": "+973", "code": "BH"},
    {"name": "Bangladesh", "dial_code": "+880", "code": "BD"},
    {"name": "Belarus", "dial_code": "+375", "code": "BY"},
    {"name": "Belgium", "dial_code": "+32", "code": "BE"},
    {"name": "Belize", "dial_code": "+501", "code": "BZ"},
    {"name": "Benin", "dial_code": "+229", "code": "BJ"},
    {"name": "Bhutan", "dial_code": "+975", "code": "BT"},
    {"name": "Bolivia", "dial_code": "+591", "code": "BO"},
    {"name": "Bosnia and Herzegovina", "dial_code": "+387", "code": "BA"},
    {"name": "Botswana", "dial_code": "+267", "code": "BW"},
    {"name": "Brazil", "dial_code": "+55", "code": "BR"},
    {"name": "British Indian Ocean Territory", "dial_code": "+246", "code": "IO"},
    {"name": "Brunei Darussalam", "dial_code": "+673", "code": "BN"},
    {"name": "Bulgaria", "dial_code": "+359", "code": "BG"},
    {"name": "Burkina Faso", "dial_code": "+226", "code": "BF"},
    {"name": "Burundi", "dial_code": "+257", "code": "BI"},
    {"name": "Cambodia", "dial_code": "+855", "code": "KH"},
    {"name": "Cameroon", "dial_code": "+237", "code": "CM"},
    {"name": "Canada", "dial_code": "+1", "code": "CA"},
    {"name": "Cape Verde", "dial_code": "+238", "code": "CV"},
    {"name": "Cayman Islands", "dial_code": "+1345", "code": "KY"},
    {"name": "Central African Republic", "dial_code": "+236", "code": "CF"},
    {"name": "Chad", "dial_code": "+235", "code": "TD"},
    {"name": "Chile", "dial_code": "+56", "code": "CL"},
    {"name": "China", "dial_code": "+86", "code": "CN"},
    {"name": "Colombia", "dial_code": "+57", "code": "CO"},
    {"name": "Comoros", "dial_code": "+269", "code": "KM"},
    {"name": "Congo", "dial_code": "+242", "code": "CG"},
    {"name": "Congo, The Democratic Republic of the", "dial_code": "+243", "code": "CD"},
    {"name": "Cook Islands", "dial_code": "+682", "code": "CK"},
    {"name": "Costa Rica", "dial_code": "+506", "code": "CR"},
    {"name": "Cote d'Ivoire", "dial_code": "+225", "code": "CI"},
    {"name": "Croatia", "dial_code": "+385", "code": "HR"},
    {"name": "Cuba", "dial_code": "+53", "code": "CU"},
    {"name": "Curacao", "dial_code": "+599", "code": "CW"},
    {"name": "Cyprus", "dial_code": "+357", "code": "CY"},
    {"name": "Czech Republic", "dial_code": "+420", "code": "CZ"},
    {"name": "Denmark", "dial_code": "+45", "code": "DK"},
    {"name": "Djibouti", "dial_code": "+253", "code": "DJ"},
    {"name": "Dominica", "dial_code": "+1767", "code": "DM"},
    {"name": "Dominican Republic", "dial_code": "+1809", "code": "DO"},
    {"name": "Ecuador", "dial_code": "+593", "code": "EC"},
    {"name": "Egypt", "dial_code": "+20", "code": "EG"},
    {"name": "El Salvador", "dial_code": "+503", "code": "SV"},
    {"name": "Equatorial Guinea", "dial_code": "+240", "code": "GQ"},
    {"name": "Eritrea", "dial_code": "+291", "code": "ER"},
    {"name": "Estonia", "dial_code": "+372", "code": "EE"},
    {"name": "Ethiopia", "dial_code": "+251", "code": "ET"},
    {"name": "Faroe Islands", "dial_code": "+298", "code": "FO"},
    {"name": "Fiji", "dial_code": "+679", "code": "FJ"},
    {"name": "Finland", "dial_code": "+358", "code": "FI"},
    {"name": "France", "dial_code": "+33", "code": "FR"},
    {"name": "French Guiana", "dial_code": "+594", "code": "GF"},
    {"name": "French Polynesia", "dial_code": "+689", "code": "PF"},
    {"name": "Gabon", "dial_code": "+241", "code": "GA"},
    {"name": "Gambia", "dial_code": "+220", "code": "GM"},
    {"name": "Georgia", "dial_code": "+995", "code": "GE"},
    {"name": "Germany", "dial_code": "+49", "code": "DE"},
    {"name": "Ghana", "dial_code": "+233", "code": "GH"},
    {"name": "Gibraltar", "dial_code": "+350", "code": "GI"},
    {"name": "Greece", "dial_code": "+30", "code": "GR"},
    {"name": "Greenland", "dial_code": "+299", "code": "GL"},
    {"name": "Grenada", "dial_code": "+1473", "code": "GD"},
    {"name": "Guadeloupe", "dial_code": "+590", "code": "GP"},
    {"name": "Guam", "dial_code": "+1671", "code": "GU"},
    {"name": "Guatemala", "dial_code": "+502", "code": "GT"},
    {"name": "Guernsey", "dial_code": "+44", "code": "GG"},
    {"name": "Guinea", "dial_code": "+224", "code": "GN"},
    {"name": "Guinea-Bissau", "dial_code": "+245", "code": "GW"},
    {"name": "Guyana", "dial_code": "+592", "code": "GY"},
    {"name": "Haiti", "dial_code": "+509", "code": "HT"},
    {"name": "Honduras", "dial_code": "+504", "code": "HN"},
    {"name": "Hong Kong", "dial_code": "+852", "code": "HK"},
    {"name": "Hungary", "dial_code": "+36", "code": "HU"},
    {"name": "Iceland", "dial_code": "+354", "code": "IS"},
    {"name": "India", "dial_code": "+91", "code": "IN"},
    {"name": "Indonesia", "dial_code": "+62", "code": "ID"},
    {"name": "Iran, Islamic Republic of", "dial_code": "+98", "code": "IR"},
    {"name": "Iraq", "dial_code": "+964", "code": "IQ"},
    {"name": "Ireland", "dial_code": "+353", "code": "IE"},
    {"name": "Isle of Man", "dial_code": "+44", "code": "IM"},
    {"name": "Israel", "dial_code": "+972", "code": "IL"},
    {"name": "Italy", "dial_code": "+39", "code": "IT"},
    {"name": "Jamaica", "dial_code": "+1876", "code": "JM"},
    {"name": "Japan", "dial_code": "+81", "code": "JP"},
    {"name": "Jersey", "dial_code": "+44", "code": "JE"},
    {"name": "Jordan", "dial_code": "+962", "code": "JO"},
    {"name": "Kazakhstan", "dial_code": "+7", "code": "KZ"},
    {"name": "Kenya", "dial_code": "+254", "code": "KE"},
    {"name": "Kiribati", "dial_code": "+686", "code": "KI"},
    {"name": "Korea, Democratic People\'s Republic of", "dial_code": "+850", "code": "KP"},
    {"name": "Korea, Republic of", "dial_code": "+82", "code": "KR"},
    {"name": "Kuwait", "dial_code": "+965", "code": "KW"},
    {"name": "Kyrgyzstan", "dial_code": "+996", "code": "KG"},
    {"name": "Lao People\'s Democratic Republic", "dial_code": "+856", "code": "LA"},
    {"name": "Latvia", "dial_code": "+371", "code": "LV"},
    {"name": "Lebanon", "dial_code": "+961", "code": "LB"},
    {"name": "Lesotho", "dial_code": "+266", "code": "LS"},
    {"name": "Liberia", "dial_code": "+231", "code": "LR"},
    {"name": "Libyan Arab Jamahiriya", "dial_code": "+218", "code": "LY"},
    {"name": "Liechtenstein", "dial_code": "+423", "code": "LI"},
    {"name": "Lithuania", "dial_code": "+370", "code": "LT"},
    {"name": "Luxembourg", "dial_code": "+352", "code": "LU"},
    {"name": "Macao", "dial_code": "+853", "code": "MO"},
    {"name": "Macedonia, The former Yugoslav Republic of", "dial_code": "+389", "code": "MK"},
    {"name": "Madagascar", "dial_code": "+261", "code": "MG"},
    {"name": "Malawi", "dial_code": "+265", "code": "MW"},
    {"name": "Malaysia", "dial_code": "+60", "code": "MY"},
    {"name": "Maldives", "dial_code": "+960", "code": "MV"},
    {"name": "Mali", "dial_code": "+223", "code": "ML"},
    {"name": "Malta", "dial_code": "+356", "code": "MT"},
    {"name": "Marshall Islands", "dial_code": "+692", "code": "MH"},
    {"name": "Martinique", "dial_code": "+596", "code": "MQ"},
    {"name": "Mauritania", "dial_code": "+222", "code": "MR"},
    {"name": "Mauritius", "dial_code": "+230", "code": "MU"},
    {"name": "Mayotte", "dial_code": "+262", "code": "YT"},
    {"name": "Mexico", "dial_code": "+52", "code": "MX"},
    {"name": "Micronesia, Federated States of", "dial_code": "+691", "code": "FM"},
    {"name": "Moldova, Republic of", "dial_code": "+373", "code": "MD"},
    {"name": "Monaco", "dial_code": "+377", "code": "MC"},
    {"name": "Mongolia", "dial_code": "+976", "code": "MN"},
    {"name": "Montenegro", "dial_code": "+382", "code": "ME"},
    {"name": "Montserrat", "dial_code": "+1664", "code": "MS"},
    {"name": "Morocco", "dial_code": "+212", "code": "MA"},
    {"name": "Mozambique", "dial_code": "+258", "code": "MZ"},
    {"name": "Myanmar", "dial_code": "+95", "code": "MM"},
    {"name": "Namibia", "dial_code": "+264", "code": "NA"},
    {"name": "Nauru", "dial_code": "+674", "code": "NR"},
    {"name": "Nepal", "dial_code": "+977", "code": "NP"},
    {"name": "Netherlands", "dial_code": "+31", "code": "NL"},
    {"name": "Netherlands Antilles", "dial_code": "+599", "code": "AN"},
    {"name": "New Caledonia", "dial_code": "+687", "code": "NC"},
    {"name": "New Zealand", "dial_code": "+64", "code": "NZ"},
    {"name": "Nicaragua", "dial_code": "+505", "code": "NI"},
    {"name": "Niger", "dial_code": "+227", "code": "NE"},
    {"name": "Nigeria", "dial_code": "+234", "code": "NG"},
    {"name": "Niue", "dial_code": "+683", "code": "NU"},
    {"name": "Norfolk Island", "dial_code": "+672", "code": "NF"},
    {"name": "Northern Mariana Islands", "dial_code": "+1670", "code": "MP"},
    {"name": "Norway", "dial_code": "+47", "code": "NO"},
    {"name": "Oman", "dial_code": "+968", "code": "OM"},
    {"name": "Pakistan", "dial_code": "+92", "code": "PK"},
    {"name": "Palau", "dial_code": "+680", "code": "PW"},
    {"name": "Panama", "dial_code": "+507", "code": "PA"},
    {"name": "Papua New Guinea", "dial_code": "+675", "code": "PG"},
    {"name": "Paraguay", "dial_code": "+595", "code": "PY"},
    {"name": "Peru", "dial_code": "+51", "code": "PE"},
    {"name": "Philippines", "dial_code": "+63", "code": "PH"},
    {"name": "Poland", "dial_code": "+48", "code": "PL"},
    {"name": "Portugal", "dial_code": "+351", "code": "PT"},
    {"name": "Puerto Rico", "dial_code": "+1787", "code": "PR"},
    {"name": "Qatar", "dial_code": "+974", "code": "QA"},
    {"name": "Romania", "dial_code": "+40", "code": "RO"},
    {"name": "Russian Federation", "dial_code": "+7", "code": "RU"},
    {"name": "Rwanda", "dial_code": "+250", "code": "RW"},
    {"name": "Saint Kitts and Nevis", "dial_code": "+1869", "code": "KN"},
    {"name": "Saint Lucia", "dial_code": "+1758", "code": "LC"},
    {"name": "Saint Vincent and the Grenadines", "dial_code": "+1784", "code": "VC"},
    {"name": "Samoa", "dial_code": "+685", "code": "WS"},
    {"name": "San Marino", "dial_code": "+378", "code": "SM"},
    {"name": "Sao Tome and Principe", "dial_code": "+239", "code": "ST"},
    {"name": "Saudi Arabia", "dial_code": "+966", "code": "SA"},
    {"name": "Senegal", "dial_code": "+221", "code": "SN"},
    {"name": "Serbia", "dial_code": "+381", "code": "RS"},
    {"name": "Seychelles", "dial_code": "+248", "code": "SC"},
    {"name": "Sierra Leone", "dial_code": "+232", "code": "SL"},
    {"name": "Singapore", "dial_code": "+65", "code": "SG"},
    {"name": "Slovakia", "dial_code": "+421", "code": "SK"},
    {"name": "Slovenia", "dial_code": "+386", "code": "SI"},
    {"name": "Solomon Islands", "dial_code": "+677", "code": "SB"},
    {"name": "Somalia", "dial_code": "+252", "code": "SO"},
    {"name": "South Africa", "dial_code": "+27", "code": "ZA"},
    {"name": "South Sudan", "dial_code": "+211", "code": "SS"},
    {"name": "Spain", "dial_code": "+34", "code": "ES"},
    {"name": "Sri Lanka", "dial_code": "+94", "code": "LK"},
    {"name": "Sudan", "dial_code": "+249", "code": "SD"},
    {"name": "Suriname", "dial_code": "+597", "code": "SR"},
    {"name": "Swaziland", "dial_code": "+268", "code": "SZ"},
    {"name": "Sweden", "dial_code": "+46", "code": "SE"},
    {"name": "Switzerland", "dial_code": "+41", "code": "CH"},
    {"name": "Syrian Arab Republic", "dial_code": "+963", "code": "SY"},
    {"name": "Taiwan, Province of China", "dial_code": "+886", "code": "TW"},
    {"name": "Tajikistan", "dial_code": "+992", "code": "TJ"},
    {"name": "Tanzania, United Republic of", "dial_code": "+255", "code": "TZ"},
    {"name": "Thailand", "dial_code": "+66", "code": "TH"},
    {"name": "Timor-Leste", "dial_code": "+670", "code": "TL"},
    {"name": "Togo", "dial_code": "+228", "code": "TG"},
    {"name": "Tokelau", "dial_code": "+690", "code": "TK"},
    {"name": "Tonga", "dial_code": "+676", "code": "TO"},
    {"name": "Trinidad and Tobago", "dial_code": "+1868", "code": "TT"},
    {"name": "Tunisia", "dial_code": "+216", "code": "TN"},
    {"name": "Turkey", "dial_code": "+90", "code": "TR"},
    {"name": "Turkmenistan", "dial_code": "+993", "code": "TM"},
    {"name": "Turks and Caicos Islands", "dial_code": "+1649", "code": "TC"},
    {"name": "Tuvalu", "dial_code": "+688", "code": "TV"},
    {"name": "Uganda", "dial_code": "+256", "code": "UG"},
    {"name": "Ukraine", "dial_code": "+380", "code": "UA"},
    {"name": "United Arab Emirates", "dial_code": "+971", "code": "AE"},
    {"name": "United Kingdom", "dial_code": "+44", "code": "GB"},
    {"name": "United States", "dial_code": "+1", "code": "US"},
    {"name": "Uruguay", "dial_code": "+598", "code": "UY"},
    {"name": "Uzbekistan", "dial_code": "+998", "code": "UZ"},
    {"name": "Vanuatu", "dial_code": "+678", "code": "VU"},
    {"name": "Venezuela", "dial_code": "+58", "code": "VE"},
    {"name": "Viet Nam", "dial_code": "+84", "code": "VN"},
    {"name": "Wallis and Futuna", "dial_code": "+681", "code": "WF"},
    {"name": "Yemen", "dial_code": "+967", "code": "YE"},
    {"name": "Zambia", "dial_code": "+260", "code": "ZM"},
    {"name": "Zimbabwe", "dial_code": "+263", "code": "ZW"}
  ]
  ''';

    List<dynamic> countryData = jsonDecode(countryCodesJson);
    List<String> validDialCodes = countryData.map((item) => item['dial_code'] as String).toList();

    String normalizedInput = input.startsWith('+') ? input : '+' + input;

    List<String> invalidChars = [];
    for (int i = 0; i < normalizedInput.length; i++) {
      if (!RegExp(r'[0-9+]').hasMatch(normalizedInput[i])) {
        invalidChars.add('"${normalizedInput[i]}"');
      }
    }

    if (invalidChars.isNotEmpty) {
      if(invalidChars.length == 1){
        return {"valid": false, "info": "enter_number_invalid_single", "error": invalidChars[0]};
      }else{
        return {"valid": false, "info": "enter_number_invalid_multiple", "error": invalidChars.join(', ')};
      }
    }

    String cleanedInput = normalizedInput.replaceAll(RegExp(r'[^0-9]'), '');

    bool startsWithValidCode = false;
    String matchedDialCode = "";
    for (String code in validDialCodes) {
      if (normalizedInput.startsWith(code)) {
        startsWithValidCode = true;
        matchedDialCode = code;
        break;
      }
    }

    String numberWithoutCode = cleanedInput.substring(matchedDialCode.length);
    if (numberWithoutCode.length < 7) {
      return {"valid": false, "info": "enter_number_invalid_too_short", "error":"${numberWithoutCode.length}"};
    }
    if (numberWithoutCode.length > 15) {
      return {"valid": false, "info": "enter_number_invalid_too_long", "error":"${numberWithoutCode.length}"};
    }
    if (!startsWithValidCode) {
      return {"valid": false, "info": "enter_number_invalid_countrycode", "error":""};
    }
    return {"valid": true, "info": "enter_number_valid", "error":""};
  }

  Map<String, dynamic> codeValidator(String input) {
    if (input.length == 0) {
      return {"valid": false, "info": "enter_code_empty", "error": ""};
    }
    if (input.length == 5) {
      return {"valid": true, "info": "enter_code_valid", "error":""};
    }
    if (input.length < 5) {
      return {"valid": false, "info": "enter_code_invalid_too_short", "error":""};
    }
    if (input.length > 5) {
      return {"valid": false, "info": "enter_code_invalid_too_long", "error":""};
    }

    if (!RegExp(r'^+$').hasMatch(input)) {
      for (int i = 0; i < input.length; i++) {
        if (!RegExp(r'').hasMatch(input[i])) {
          return {"valid": false, "info": 'enter_code_invalid_single', "error": input[i]};
        }
      }
      return {"valid": false, "info": "enter_code_invalid_wtf", "error":""};
    }
    return {"valid": true, "info": "enter_code_valid", "error":""};
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

  saveJSON(name, data) async {
    notifyListeners();
    if (!await FlutterFileDialog.isPickDirectorySupported()) {
      throw Exception("Picking directory not supported");
    }
    final pickedDirectory = await FlutterFileDialog.pickDirectory();
    if (pickedDirectory != null) {
      await FlutterFileDialog.saveFileToDirectory(
        directory: pickedDirectory,
        data: Uint8List.fromList(utf8.encode(prettyJson(data, indent: 2))),
        mimeType: "application/json",
        fileName: "$name.json",
        replace: true,
      );
    }
  }


  getConfigOnline() async {
    var remoteAssets = "https://raw.githubusercontent.com/Puzzaks/tgcrawl/master/assets/config";
    status = "Loading configuration...";
    notifyListeners();
    final intros = await http.get(
      Uri.parse("$remoteAssets/intro.json"),
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
        Uri.parse("$remoteAssets/languages.json"),
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
            Uri.parse("$remoteAssets/${languages[i]["id"]}.json"),
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