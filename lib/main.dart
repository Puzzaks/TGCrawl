import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pretty_json/pretty_json.dart';
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
                              secondChild: provider.introSequence[provider.introPosition].containsKey("selector")
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
                                          provider.dict(provider.introPair[1]["title"]),
                                          style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                            provider.dict(provider.introPair[1]["description"]),
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
                                  : infoCard(scaffoldWidth, provider.dict(provider.introPair[1]["title"]), provider.dict(provider.introPair[1]["description"]), context)
                                  : infoCard(scaffoldWidth, provider.dict(provider.introPair[1]["title"]), provider.dict(provider.introPair[1]["description"]), context),
                              crossFadeState: !provider.switchIntro? CrossFadeState.showFirst : CrossFadeState.showSecond,
                            ),
                            Container(
                              width: scaffoldWidth,
                              child: AnimatedCrossFade(
                                alignment: Alignment.center,
                                duration: Duration(milliseconds: 500),
                                firstChild: Row(
                                  children: [
                                    Card(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      elevation: 5,
                                      clipBehavior: Clip.hardEdge,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: InkWell(
                                        onTap: (){
                                          provider.unprogressIntroSequence();
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons.navigate_before_rounded
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Card(
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
                                    ))
                                  ],
                                ),
                                secondChild: provider.introSequence[provider.introPosition].containsKey("selector")
                                    ? provider.introSequence[provider.introPosition]["selector"]["type"] == "bool"
                                    ? Row(
                                  children: [
                                    Card(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      elevation: 5,
                                      clipBehavior: Clip.hardEdge,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: InkWell(
                                        onTap: (){
                                          provider.unprogressIntroSequence();
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons.navigate_before_rounded
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
                                    : Row(
                                  children: [
                                    Card(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      elevation: 5,
                                      clipBehavior: Clip.hardEdge,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: InkWell(
                                        onTap: (){
                                          provider.unprogressIntroSequence();
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons.navigate_before_rounded
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Card(
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
                                    ))
                                  ],
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
                firstChild: Container(
                  height: scaffoldHeight,
                  width: scaffoldWidth,
                  child: HomePage(),
                ),
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

class HomePage extends StatefulWidget {

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 5,), // shit code
                  AnimatedCrossFade(
                    alignment: Alignment.center,
                    duration: Duration(milliseconds: 500),
                    firstChild: Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        width: scaffoldWidth,
                        height: 72,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          child: Padding(padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.downloading_rounded,
                                  size: 50,
                                ),
                                SizedBox(width: 15,),
                                Container(
                                  height: 64,
                                  width: scaffoldWidth - 103,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.dict("user_loading_title"),
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                          provider.dict("user_loading_desc"),
                                          style: TextStyle(
                                              fontSize: 16
                                          )
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),), // number
                    secondChild: Padding(padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          child: Padding(padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: provider.userPic == "" ? Container() : Image.file(
                                    File(provider.userPic),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.dict("ready"),
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                          "${provider.dict("logged_as")}${provider.userData["first_name"].toString()}${provider.userData["last_name"].toString() == ""?"":" "}${provider.userData["last_name"].toString()}",
                                          style: TextStyle(
                                              fontSize: 16
                                          )
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),),
                    crossFadeState: provider.userPic == "" ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  ), // user info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: AnimatedCrossFade(
                      alignment: Alignment.center,
                      duration: Duration(milliseconds: 500),
                      firstChild: Padding(padding: EdgeInsets.all(5),
                        child: Column(
                          children: [
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
                                        provider.dict("sharing_disabled_title"),
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                          provider.dict("sharing_disabled_desc"),
                                          style: TextStyle(
                                              fontSize: 16
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
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
                                          prefs.setBool("crowdsource", true);
                                          prefs.setBool("crowdsource_final", true);
                                          setState(() {
                                            provider.crowdsource_final = true;
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                provider.dict("crowdsource_yes"),
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
                                          prefs.setBool("crowdsource", false);
                                          prefs.setBool("crowdsource_final", true);
                                          setState(() {
                                            provider.crowdsource_final = true;
                                          });
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                provider.dict("crowdsource_no"),
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
                          ],
                        ),),
                      secondChild: Container(
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
                                  provider.dict("sharing_enabled_title"),
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      crossFadeState: (!provider.crowdsource && !provider.crowdsource_final) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    ),
                  ), // crowdsource request
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
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
                                  provider.readIndexedChannels();
                                  provider.filterIndexedChannels();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(fullscreenDialog: true, builder: (context) => IndexesPage()),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        provider.dict("indexed_channels"),
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
                              color: Theme.of(context).colorScheme.onPrimary,
                              elevation: 5,
                              clipBehavior: Clip.hardEdge,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(fullscreenDialog: true, builder: (context) => NewIndexPage()),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        provider.dict("index_channel"),
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
                    ),
                  ), // indexing options
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      elevation: 5,
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () async {

                        },
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.dict("settings"),
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              Icon(
                                  Icons.settings_rounded
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NewIndexPage extends StatefulWidget {

  @override
  NewIndexPageState createState() => NewIndexPageState();
}

class NewIndexPageState extends State<NewIndexPage> {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 5,),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.navigate_before_rounded,
                                    size: 34,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left:5),
                              child: TextField(
                                onChanged: (text){
                                  provider.searchChannel();
                                },
                                controller: provider.channelSearch,
                                autofocus: true,
                                keyboardType: TextInputType.text,
                                obscureText: false,
                                textAlignVertical: TextAlignVertical.top,
                                scrollPadding: const EdgeInsets.all(0),
                                expands: false,
                                minLines: null,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                                  prefixIcon: Icon(Icons.search_rounded),
                                  labelText: provider.dict("channel_search"),
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                ),
                              ),
                            ))
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    alignment: Alignment.center,
                    duration: Duration(milliseconds: 500),
                    firstChild: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                        child: Padding(padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                provider.dict(provider.channelNotFound?"channel_not_found_title":"channel_search"),
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                  provider.dict(provider.channelNotFound?"channel_not_found_desc":"channel_search_desc"),
                                  style: TextStyle(
                                      fontSize: 16
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                    ), // number
                    secondChild: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Container(
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
                              provider.updateIndexedChannels(provider.candidateChannel["id"].toString(), provider.candidateChannel);
                              provider.currentChannel = provider.candidateChannel;
                              provider.retreiveFullChannelInfo(provider.currentChannel["id"]);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(fullscreenDialog: true, builder: (context) => IndexPage()),
                              );
                              provider.channelSearch.text = "";
                            },
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Row(
                                children: [
                                  provider.candidateChannel.isEmpty?Container():ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: provider.candidateChannel["picfile"] == "NOPIC" ? Container(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          provider.candidateChannel["title"][0],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24
                                          ),
                                        ),
                                      ),
                                    ) : Image.file(
                                      File(provider.candidateChannel["picfile"]),
                                      width: 60,
                                      height: 60,
                                    ),
                                  ),
                                  Container(
                                    width: scaffoldWidth - 88,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider.candidateChannel.isEmpty?"":provider.candidateChannel["title"],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          Text(
                                              provider.candidateChannel.isEmpty?"":"@${provider.candidateChannel["username"]}",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontSize: 16
                                              )
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),),
                    crossFadeState: provider.candidateChannel.isEmpty ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class IndexPage extends StatefulWidget {

  @override
  IndexPageState createState() => IndexPageState();
}

class IndexPageState extends State<IndexPage> {
  @override
  void initState() {
    super.initState();
  }
  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;
  final MaterialStateProperty<Icon?> playicon =
  MaterialStateProperty.resolveWith<Icon?>(
        (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.play_arrow_rounded);
      }
      return const Icon(Icons.pause_rounded);
    },
  );
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 5,),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.navigate_before_rounded,
                                    size: 27,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            child: Card(
                              color: Theme.of(context).colorScheme.onPrimary,
                              elevation: 5,
                              child: Padding(padding: EdgeInsets.all(15),
                                child: Text(
                                  provider.dict("channel_view"),
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            )),
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              provider.isIndexing = false;
                              provider.deleteIndexedChannel(provider.currentChannel["id"].toString());
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 27,
                                  )
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal:5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                        child: Padding(padding: EdgeInsets.all(5),
                          child: Row(
                            children: [
                              provider.currentChannel.isEmpty?Container():ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: provider.currentChannel.isEmpty?Container():ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: provider.currentChannel["picfile"] == "NOPIC" ? Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    width: 60,
                                    height: 60,
                                    child: Center(
                                        child: Text(
                                          provider.currentChannel["title"][0],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24
                                          ),
                                        ),
                                    ),
                                  ) : Image.file(
                                    File(provider.currentChannel["picfile"]),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),
                              Container(
                                width: scaffoldWidth - 88,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.currentChannel.isEmpty?"":provider.currentChannel["title"],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                          provider.currentChannel.isEmpty?"":"@${provider.currentChannel["username"]}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 16
                                          )
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal:5),
                      child: Row(
                          children: [
                            Expanded(
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 5,
                                  child: Padding(padding: EdgeInsets.all(15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.dict("subscribers"),
                                          style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                            provider.currentChannel.containsKey("subs")?provider.currentChannel["subs"].toString():"0",
                                            style: TextStyle(
                                                fontFamily: provider.currentChannel.containsKey("subs")?null:"Flow",
                                                fontSize: 16
                                            )
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                            ),
                            Expanded(child: Card(
                              color: Theme.of(context).colorScheme.onPrimary,
                              elevation: 5,
                              child: Padding(padding: EdgeInsets.all(15),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      provider.dict("messages"),
                                      style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    Text(
                                        provider.currentChannel.containsKey("lastmsgid")?provider.currentChannel["lastmsgid"].toString():"0",
                                        style: TextStyle(
                                            fontFamily: provider.currentChannel.containsKey("lastmsgid")?null:"Flow",
                                            fontSize: 16
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            ))
                          ]
                      )
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal:5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: (){
                            setState(() {
                              provider.isIndexing = !provider.isIndexing;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 15,
                                right: 10,
                                bottom: 10,
                                top: 10
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: scaffoldWidth - 105,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              provider.isIndexing?provider.dict(provider.indexingStatus):provider.dict("indexed_title"),
                                              style: TextStyle(
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            Text(
                                                provider.currentChannel.containsKey("donepercent")?"${provider.currentChannel["donepercent"].toStringAsFixed(2)}%":"0%",
                                                style: TextStyle(
                                                    fontSize: 16
                                                )
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10,),
                                        LinearProgressIndicator(
                                          value: provider.currentChannel.containsKey("donepercent")?provider.currentChannel["donepercent"] / 100:0,
                                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                Switch(
                                  thumbIcon: playicon,
                                  value: provider.isIndexing,
                                  onChanged: (value) {
                                    setState(() {
                                      provider.isIndexing = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                  ),
                  // Padding(
                  //     padding: EdgeInsets.symmetric(horizontal:5),
                  //     child: Card(
                  //       color: Theme.of(context).colorScheme.onPrimary,
                  //       elevation: 5,
                  //       child: Padding(padding: EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                  //         child: Row(
                  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //           children: [
                  //             Column(
                  //               crossAxisAlignment: CrossAxisAlignment.start,
                  //               children: [
                  //                 Text(
                  //                   provider.dict("clear_index_title"),
                  //                   style: TextStyle(
                  //                       fontSize: 19,
                  //                       fontWeight: FontWeight.bold
                  //                   ),
                  //                 ),
                  //                 Text(
                  //                     provider.dict("clear_index_desc"),
                  //                     style: TextStyle(
                  //                         fontSize: 16
                  //                     )
                  //                 ),
                  //               ],
                  //             ),
                  //             FilledButton(
                  //                 onPressed: (){
                  //                   showDialog<String>(
                  //                     context: context,
                  //                     builder: (BuildContext context) => AlertDialog(
                  //                       content: Column(
                  //                         crossAxisAlignment: CrossAxisAlignment.start,
                  //                         mainAxisSize: MainAxisSize.min,
                  //                         children: [
                  //                           Text(provider.dict("clear_index_confirm").replaceAll("(PERCENT)","${
                  //                           (
                  //                               (
                  //                                   (
                  //                                       provider.currentChannel.containsKey("lastindexedid")
                  //                                           ? provider.currentChannel["lastindexedid"]
                  //                                           : 0
                  //                                   )/(
                  //                                       provider.currentChannel.containsKey("lastmsgid")
                  //                                           ? int.parse(provider.currentChannel["lastmsgid"])
                  //                                           : 0
                  //                                   )
                  //                               ) * 100
                  //                           ).toStringAsFixed(2)}")
                  //                           )
                  //                         ],
                  //                       ),
                  //                       actions: [
                  //                         Row(
                  //                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //                           children: [
                  //                             FilledButton(
                  //                                 onPressed: () {
                  //                                   Navigator.pop(context);
                  //                                 },
                  //                                 style: ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Theme.of(context).colorScheme.error)),
                  //                                 child: Text(
                  //                                   provider.dict("cancel"),
                  //                                   style: TextStyle(color: Theme.of(context).colorScheme.background),
                  //                                 )
                  //                             ),
                  //                             FilledButton(
                  //                                 onPressed: () async {
                  //                                   Navigator.pop(context);
                  //                                 },
                  //                                 child: Text(provider.dict("clear_index_action"))
                  //                             ),
                  //                           ],
                  //                         )
                  //                       ],
                  //                     ),
                  //                   );
                  //                 },
                  //                 child: Text(
                  //                     provider.dict("clear_index_action"),
                  //                     style: TextStyle(
                  //                         fontSize: 16
                  //                     )
                  //                 )
                  //             )
                  //           ],
                  //         ),
                  //       ),
                  //     )
                  // ),
                  provider.currentChannel.containsKey("relations")
                      ? Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: provider.currentChannel["relations"].keys.toList().reversed.map((relation) {
                          if(provider.knownChannels.containsKey(relation)){
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Container(
                                width: scaffoldWidth,
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  elevation: 5,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10.0),
                                          child: (provider.knownChannels[relation]["picfile"] == "NOPIC" || !provider.knownChannels[relation].containsKey("picfile")) ? Container(
                                            color: Theme.of(context).colorScheme.primaryContainer,
                                            width: 60,
                                            height: 60,
                                            child: Center(
                                              child: Text(
                                                provider.knownChannels[relation]["title"][0],
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24
                                                ),
                                              ),
                                            ),
                                          ) : Image.file(
                                            File(provider.knownChannels[relation]["picfile"]),
                                            width: 60,
                                            height: 60,
                                          ),
                                        ),
                                        Container(
                                          width: scaffoldWidth - 88,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              children: [
                                                Text(
                                                  provider.knownChannels[relation]["title"],
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 19,
                                                      fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                                Text(
                                                    "${provider.currentChannel["relations"][relation]["reposts"]} reposts",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 16
                                                    )
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),);
                          }
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Container(
                              width: scaffoldWidth,
                              child: Card(
                                color: Theme.of(context).colorScheme.onPrimary,
                                elevation: 5,
                                clipBehavior: Clip.hardEdge,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10.0),
                                        child: Container(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          width: 60,
                                          height: 60,
                                          child: Center(
                                            child: Icon(Icons.downloading_rounded,
                                            size: 24
                                              ,),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Loading...",
                                              style: TextStyle(
                                                  fontFamily: "Flow",
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            Text(
                                                "${provider.currentChannel["relations"][relation]["reposts"]} reposts",
                                                style: TextStyle(
                                                    fontSize: 16
                                                )
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),);
                          return Text("${provider.knownChannels.containsKey(relation)?"${provider.knownChannels[relation]["title"]}":"Unknown"} - ${provider.currentChannel["relations"][relation]["reposts"]} reposts");
                        }).toList().cast<Widget>(),
                      ),
                    ),
                  )
                      : provider.currentChannel.containsKey("lastmsgid")
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal:5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                        child: Padding(padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.dict("no_relations_title"),
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text(
                                      provider.dict("no_relations_desc"),
                                      style: TextStyle(
                                          fontSize: 16
                                      )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                  )
                  : Padding(
                      padding: EdgeInsets.symmetric(horizontal:5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                        child: Padding(padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.dict("no_messages_title"),
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text(
                                      provider.dict("no_messages_desc"),
                                      style: TextStyle(
                                          fontSize: 16
                                      )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class IndexesPage extends StatefulWidget {

  @override
  IndexesPageState createState() => IndexesPageState();
}

class IndexesPageState extends State<IndexesPage> {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 5,),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          elevation: 5,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: (){
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.navigate_before_rounded,
                                    size: 34,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(left:5),
                          child: TextField(
                            onChanged: (text){
                              provider.filterIndexedChannels();
                            },
                            controller: provider.channelFilter,
                            autofocus: false,
                            keyboardType: TextInputType.text,
                            obscureText: false,
                            textAlignVertical: TextAlignVertical.top,
                            scrollPadding: const EdgeInsets.all(0),
                            expands: false,
                            minLines: null,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                              prefixIcon: Icon(Icons.filter_list_rounded),
                              labelText: provider.dict("filter_channels"),
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                            ),
                          ),
                        ))
                      ],
                    ),
                  ),
                  provider.displayIndexes.isEmpty
                      ? Padding(
                      padding: EdgeInsets.symmetric(horizontal:5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        elevation: 5,
                        child: Padding(padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.dict("no_indexed_title"),
                                    style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text(
                                      provider.dict("no_indexed_desc"),
                                      style: TextStyle(
                                          fontSize: 16
                                      )
                                  ),
                                ],
                              ),
                              FilledButton(
                                  onPressed: (){
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(fullscreenDialog: true, builder: (context) => NewIndexPage()),
                                    );
                                  },
                                  child: Text(
                                      provider.dict("add"),
                                      style: TextStyle(
                                          fontSize: 16
                                      )
                                  )
                              )
                            ],
                          ),
                        ),
                      )
                  )
                      : SingleChildScrollView(
                    child: Column(
                      children: provider.displayIndexes.map((channel) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
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
                                  provider.currentChannel = channel;
                                  provider.retreiveFullChannelInfo(provider.currentChannel["id"]);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(fullscreenDialog: true, builder: (context) => IndexPage()),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10.0),
                                        child: channel["picfile"] == "NOPIC" ? Container(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          width: 60,
                                          height: 60,
                                          child: Center(
                                            child: Text(
                                              channel["title"][0],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24
                                              ),
                                            ),
                                          ),
                                        ) : Image.file(
                                          File(channel["picfile"]),
                                          width: 60,
                                          height: 60,
                                        ),
                                      ),
                                      Container(
                                        width: scaffoldWidth - 88,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 15,vertical: 5),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                channel["title"],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 19,
                                                    fontWeight: FontWeight.bold
                                                ),
                                              ),
                                              Text(
                                                  "@${channel["username"]}",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontSize: 16
                                                  )
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),);
                      }).toList().cast<Widget>(),
                    ),
                  )
                ],
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