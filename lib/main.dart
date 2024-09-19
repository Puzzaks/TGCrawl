import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tgcrawl/tgback.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => tgProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HomeScreen();
  }
}

class HomeScreen extends StatelessWidget {
  static final _defaultLightColorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.teal);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.teal, brightness: Brightness.dark);
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<tgProvider>(context, listen: false).init();
    });
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
          theme: ThemeData(
            colorScheme: lightColorScheme ?? _defaultLightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: LayoutBuilder(
                builder: (context, constraints) {
                  double scaffoldHeight = constraints.maxHeight;
                  double scaffoldWidth = constraints.maxWidth;
                  return Consumer<tgProvider>(
                    builder: (context, provider, child) {
                      provider.localContext = context;
                      provider.localWidth = scaffoldWidth;
                      provider.localHeight = scaffoldHeight;
                      return provider.langReady?AnimatedCrossFade(
                        alignment: Alignment.center,
                        duration: Duration(milliseconds: 500),
                        firstChild: firstBoot(),
                        secondChild: provider.isFirstBoot ? firstBoot() : tgLogin(),
                        crossFadeState: provider.isFirstBoot ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      ):Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: 350,
                              child: Card(
                                color: Theme.of(context).colorScheme.onPrimary,
                                elevation: 15,
                                child: Padding(padding: EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Loading...",
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 5),
                                        child: Text(
                                          provider.status,
                                        ),
                                      ),
                                      LinearProgressIndicator(
                                        value: provider.langState == 0.0 ? null : provider.langState,
                                        borderRadius: const BorderRadius.all(Radius.circular(3)),
                                      )
                                    ],
                                  ),),
                              ),
                            ),
                          )
                        ],
                      );
                      return provider.isFirstBoot ? firstBoot() : tgLogin();
                    },
                  );
                }
            ),
          )
      );
    });
  }
}

class firstBoot extends StatefulWidget {

  @override
  firstBootState createState() => firstBootState();
}

class firstBootState extends State<firstBoot> {
  Widget infoCard (double width, String title, String desc, context){
    return Container(
      width: width,
      child: Card(
        color: Theme.of(context).colorScheme.onPrimary,
        elevation: 5,
        child: Padding(padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold
                ),
              ),
              Text(
                  desc,
                  style: TextStyle(
                      fontSize: 16
                  )
              ),
            ],
          ),),
      ),
    );
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<tgProvider>(
        builder: (context, provider, child) {
          context = provider.localContext;
          scaffoldWidth = provider.localWidth;
          scaffoldHeight = provider.localHeight;
          return Container(
            height: scaffoldHeight,
            child: Padding(
              padding: EdgeInsets.all(5),
              child: Stack(
                children: [
                  Column(
                    children: [
                      AnimatedCrossFade(
                        alignment: Alignment.center,
                        duration: provider.switchIntro ? Duration(milliseconds: 500) : Duration.zero,
                        firstChild: LinearProgressIndicator(
                          value: (provider.introPosition + 1) / (provider.introSequence.length - 1),
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                        ),
                        secondChild: LinearProgressIndicator(
                          value: (provider.introPosition + (provider.switchIntro?1:2)) / (provider.introSequence.length - 1),
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                        ),
                        crossFadeState: !provider.switchIntro? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      ),
                      provider.isOffline ? Padding(
                        padding: EdgeInsets.only(top:5),
                        child: Container(
                          width: scaffoldWidth,
                          child: Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            elevation: 5,
                            child: Padding(padding: EdgeInsets.all(15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: scaffoldWidth - 84,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            provider.dict("offline_title"),
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          Text(
                                              provider.dict("offline_desc"),
                                              style: TextStyle(
                                                  fontSize: 16
                                              )
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 36,
                                    )
                                  ],
                                )
                            ),
                          ),
                        ),
                      ): Container(),
                    ],
                  ),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(),
                                Container(),
                                AnimatedCrossFade(
                                  alignment: Alignment.center,
                                  duration: provider.switchIntro ? Duration(milliseconds: 500) : Duration.zero,
                                  firstChild: Icon(
                                    IconData(int.parse(provider.introPair[0]["icon"]), fontFamily: 'MaterialIcons'),
                                    size: scaffoldHeight / 4,
                                  ),
                                  secondChild: Icon(
                                    IconData(int.parse(provider.introPair[1]["icon"]), fontFamily: 'MaterialIcons'),
                                    size: scaffoldHeight / 4,
                                  ),
                                  crossFadeState: !provider.switchIntro? CrossFadeState.showFirst : CrossFadeState.showSecond,
                                ),
                                Container()
                              ]
                          ),
                        ),
                        Column(
                          children: [
                            AnimatedCrossFade(
                              alignment: Alignment.center,
                              duration: provider.switchIntro ? Duration(milliseconds: 500) : Duration.zero,
                              firstChild: provider.introSequence[provider.introPosition].containsKey("selector")
                                  ?provider.introSequence[provider.introPosition]["selector"]["type"] == "language"
                                  ? Container(
                                width: scaffoldWidth,
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 5,
                                  child: Padding(padding: EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.dict(provider.introPair[0]["title"]),
                                          style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                            provider.dict(provider.introPair[0]["description"]),
                                            style: TextStyle(
                                                fontSize: 16
                                            )
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(top: 15),
                                          child: DropdownMenu(
                                            controller: provider.languageSelector,
                                            initialSelection: provider.locale,
                                            onSelected: (language) async {
                                              provider.locale = language!;
                                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                                              prefs.setString("language", language!);
                                              setState(() {

                                              });
                                            },
                                            enableSearch: true,
                                            width: scaffoldWidth - 48,
                                            label: Text(provider.dict("language_select")),
                                            leadingIcon: const Icon(Icons.language_rounded),
                                            dropdownMenuEntries: provider.languages.map((language) {
                                              return DropdownMenuEntry(
                                                value: language["id"],
                                                label: language["origin"],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                                  : infoCard(scaffoldWidth, provider.dict(provider.introPair[0]["title"]), provider.dict(provider.introPair[0]["description"]), context)
                                  : infoCard(scaffoldWidth, provider.dict(provider.introPair[0]["title"]), provider.dict(provider.introPair[0]["description"]), context),
                              secondChild: infoCard(scaffoldWidth, provider.dict(provider.introPair[1]["title"]), provider.dict(provider.introPair[1]["description"]), context),
                              crossFadeState: !provider.switchIntro? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            ),
                            Container(
                              width: scaffoldWidth,
                              child: AnimatedCrossFade(
                                alignment: Alignment.center,
                                duration: Duration(milliseconds: 500),
                                firstChild: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 5,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      provider.launch();
                                      provider.isFirstBoot = false;
                                      final SharedPreferences prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('first', false);
                                      setState(() {

                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            provider.dict("done"),
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          Icon(
                                              Icons.done_rounded
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                secondChild: provider.introSequence[provider.introPosition].containsKey("selector")
                                    ? provider.introSequence[provider.introPosition]["selector"]["type"] == "bool"
                                    ? Row(
                                  children: [
                                    Expanded(
                                        child: Card(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          elevation: 5,
                                          clipBehavior: Clip.hardEdge,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: InkWell(
                                            onTap: () async {
                                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                                              prefs.setBool(provider.introSequence[provider.introPosition]["selector"]["name"], true);
                                              provider.progressIntroSequence();
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(15),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    provider.dict(provider.introSequence[provider.introPosition]["selector"]["true"]),
                                                    style: TextStyle(
                                                        fontSize: 19,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Icon(
                                                      Icons.navigate_next_rounded
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                    ),
                                    Expanded(
                                        child: Card(
                                          color: Theme.of(context).colorScheme.errorContainer,
                                          elevation: 5,
                                          clipBehavior: Clip.hardEdge,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: InkWell(
                                            onTap: () async {
                                              final SharedPreferences prefs = await SharedPreferences.getInstance();
                                              prefs.setBool(provider.introSequence[provider.introPosition]["selector"]["name"], false);
                                              provider.progressIntroSequence();
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(15),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    provider.dict(provider.introSequence[provider.introPosition]["selector"]["false"]),
                                                    style: TextStyle(
                                                        fontSize: 19,
                                                        fontWeight: FontWeight.bold
                                                    ),
                                                  ),
                                                  Icon(
                                                      Icons.navigate_next_rounded
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                    ),
                                  ],
                                )
                                    : Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 5,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      provider.progressIntroSequence();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            provider.dict("next"),
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          Icon(
                                              Icons.navigate_next_rounded
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                    : Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 5,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: (){
                                      provider.progressIntroSequence();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            provider.dict("next"),
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          Icon(
                                              Icons.navigate_next_rounded
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                crossFadeState: provider.introPosition > (provider.introSequence.length - 3)? CrossFadeState.showFirst : CrossFadeState.showSecond,
                              ),
                            ),
                          ],
                        )
                        // infoCard(scaffoldWidth, provider.dict("welcome_title"), provider.dict("welcome_desc")),
                        // infoCard(scaffoldWidth, provider.dict("desc_title"), provider.dict("desc_desc")),
                        // infoCard(scaffoldWidth, provider.dict("reason_title"), provider.dict("reason_desc")),
                        // infoCard(scaffoldWidth, provider.dict("safety_title"), provider.dict("safety_desc")),

                      ]
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class tgLogin extends StatefulWidget {

  @override
  tgLoginState createState() => tgLoginState();
}

class tgLoginState extends State<tgLogin> {
  Widget infoCard (double width, String title, String desc, context){
    return Container(
      width: width,
      child: Card(
        color: Theme.of(context).colorScheme.onPrimary,
        elevation: 5,
        child: Padding(padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold
                ),
              ),
              Text(
                  desc,
                  style: TextStyle(
                      fontSize: 16
                  )
              ),
            ],
          ),),
      ),
    );
  }
  @override
  void initState() {
    super.initState();
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<tgProvider>(
          builder: (context, provider, child) {
            context = provider.localContext;
            scaffoldWidth = provider.localWidth;
            scaffoldHeight = provider.localHeight;
            return Container(
              height: scaffoldHeight,
              width: scaffoldWidth,
              child: AnimatedCrossFade(
                alignment: Alignment.center,
                duration: Duration(milliseconds: 500),
                firstChild: Text("LOGGED IN MOTHERFUCKER"),
                secondChild: Container(
                  height: scaffoldHeight,
                  child: AnimatedCrossFade(
                    alignment: Alignment.center,
                    duration: Duration(milliseconds: 500),
                    firstChild: Container(
                      height: scaffoldHeight,
                      width: scaffoldWidth,
                      child: loginPasswordStage(),
                    ), // password
                    secondChild: Container(
                      height: scaffoldHeight,
                      child: AnimatedCrossFade(
                        alignment: Alignment.center,
                        duration: Duration(milliseconds: 500),
                        firstChild: Container(
                          height: scaffoldHeight,
                          child: loginCodeStage(),
                        ), // code
                        secondChild: Container(
                          height: scaffoldHeight,
                          child: AnimatedCrossFade(
                            alignment: Alignment.center,
                            duration: Duration(milliseconds: 500),
                            firstChild: Container(
                              height: scaffoldHeight,
                              width: scaffoldWidth,
                              child: loginPhoneStage(),
                            ), // number
                            secondChild: Container(
                              width: scaffoldWidth,
                              height: scaffoldHeight,
                              child: loginLoadingStage(),
                            ),
                            crossFadeState: provider.isWaitingNumber? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          ),
                        ),
                        crossFadeState: provider.isWaitingCode? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      ),
                    ),
                    crossFadeState: provider.isWaitingPassword? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  ),
                ),
                crossFadeState: provider.isLoggedIn? CrossFadeState.showFirst : CrossFadeState.showSecond,
              ),
            );
          },
        ),
      ),
    );
  }
}

class loginLoadingStage extends StatefulWidget {

  @override
  loginLoadingStageState createState() => loginLoadingStageState();
}

class loginLoadingStageState extends State<loginLoadingStage> {
  @override
  void initState() {
    super.initState();
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<tgProvider>(
          builder: (context, provider, child) {
            context = provider.localContext;
            scaffoldWidth = provider.localWidth;
            scaffoldHeight = provider.localHeight;
            return Container(
              height: scaffoldHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(),
                          Icon(
                            Icons.downloading_rounded,
                            size: scaffoldHeight / 5,
                          ),
                          Container()
                        ]
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(5),
                  child: Container(
                    width: scaffoldWidth,
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      elevation: 5,
                      child: Padding(padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              provider.dict("loading_title"),
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                                provider.dict("loading_desc"),
                                style: TextStyle(
                                    fontSize: 16
                                )
                            ),
                            SizedBox(height: 10,),
                            LinearProgressIndicator(
                              borderRadius: const BorderRadius.all(Radius.circular(3)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class loginPhoneStage extends StatefulWidget {

  @override
  loginPhoneStageState createState() => loginPhoneStageState();
}

class loginPhoneStageState extends State<loginPhoneStage> {
  @override
  void initState() {
    super.initState();
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<tgProvider>(
          builder: (context, provider, child) {
            context = provider.localContext;
            scaffoldWidth = provider.localWidth;
            scaffoldHeight = provider.localHeight;
            return Container(
              height: scaffoldHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(),
                          Icon(
                            Icons.dialpad_rounded,
                            size: scaffoldHeight / 5,
                          ),
                          Container()
                        ]
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: LinearProgressIndicator(
                          value: provider.loginState == 0.0 ? null : provider.loginState,
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                      Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          child: Padding(padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict("login_title"),
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                Text(
                                    provider.dict("login_desc"),
                                    style: TextStyle(
                                        fontSize: 16
                                    )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top:15),
                                  child: TextField(
                                    controller: provider.number,
                                    autofocus: true,
                                    keyboardType: TextInputType.phone,
                                    textAlignVertical: TextAlignVertical.top,
                                    scrollPadding: const EdgeInsets.all(0),
                                    expands: false,
                                    minLines: null,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                                      prefixIcon: Icon(Icons.dialpad_rounded),
                                      labelText: provider.dict("enter_phone"),
                                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              provider.doNumberLogin();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.dict("next"),
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Icon(
                                      Icons.navigate_next_rounded
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,)
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class loginCodeStage extends StatefulWidget {

  @override
  loginCodeStageState createState() => loginCodeStageState();
}

class loginCodeStageState extends State<loginCodeStage> {
  @override
  void initState() {
    super.initState();
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<tgProvider>(
          builder: (context, provider, child) {
            context = provider.localContext;
            scaffoldWidth = provider.localWidth;
            scaffoldHeight = provider.localHeight;
            return Container(
              height: scaffoldHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(),
                          Icon(
                            Icons.pin_rounded,
                            size: scaffoldHeight / 5,
                          ),
                          Container()
                        ]
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: LinearProgressIndicator(
                          value: provider.loginState == 0.0 ? null : provider.loginState,
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                      Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          child: Padding(padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict("code_title"),
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                Text(
                                    provider.dict("code_desc"),
                                    style: TextStyle(
                                        fontSize: 16
                                    )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top:15),
                                  child: TextField(
                                    controller: provider.code,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    textAlignVertical: TextAlignVertical.top,
                                    scrollPadding: const EdgeInsets.all(0),
                                    expands: false,
                                    minLines: null,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                                      prefixIcon: Icon(Icons.pin_rounded),
                                      labelText: provider.dict("code_title"),
                                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              provider.doCodeLogin();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.dict("next"),
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Icon(
                                      Icons.navigate_next_rounded
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,)
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class loginPasswordStage extends StatefulWidget {

  @override
  loginPasswordStageState createState() => loginPasswordStageState();
}

class loginPasswordStageState extends State<loginPasswordStage> {
  @override
  void initState() {
    super.initState();
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<tgProvider>(
          builder: (context, provider, child) {
            context = provider.localContext;
            scaffoldWidth = provider.localWidth;
            scaffoldHeight = provider.localHeight;
            return Container(
              height: scaffoldHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(),
                          Icon(
                            Icons.password_rounded,
                            size: scaffoldHeight / 5,
                          ),
                          Container()
                        ]
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: LinearProgressIndicator(
                          value: provider.loginState == 0.0 ? null : provider.loginState,
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                        ),
                      ),
                      Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          child: Padding(padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict("password_title"),
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                Text(
                                    provider.dict("password_desc"),
                                    style: TextStyle(
                                        fontSize: 16
                                    )
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top:15),
                                  child: TextField(
                                    controller: provider.password,
                                    autofocus: true,
                                    keyboardType: TextInputType.visiblePassword,
                                    obscureText: true,
                                    textAlignVertical: TextAlignVertical.top,
                                    scrollPadding: const EdgeInsets.all(0),
                                    expands: false,
                                    minLines: null,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                                      prefixIcon: Icon(Icons.password_rounded),
                                      labelText: provider.dict("password_title"),
                                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              provider.doPwdLogin();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.dict("login_title"),
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Icon(
                                      Icons.done_rounded
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5,)
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}