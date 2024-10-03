import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graphview/GraphView.dart';
import 'package:pretty_json/pretty_json.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tgcrawl/tgback.dart';
import 'package:url_launcher/url_launcher.dart';

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
            body: LayoutBuilder(builder: (context, constraints) {
              double scaffoldHeight = constraints.maxHeight;
              double scaffoldWidth = constraints.maxWidth;
              return Consumer<tgProvider>(
                builder: (context, provider, child) {
                  provider.localContext = context;
                  provider.localWidth = scaffoldWidth;
                  provider.localHeight = scaffoldHeight;
                  return provider.langReady
                      ? AnimatedCrossFade(
                          alignment: Alignment.center,
                          duration: Duration(milliseconds: 500),
                          firstChild: firstBoot(),
                          secondChild: provider.isFirstBoot ? firstBoot() : tgLogin(),
                          crossFadeState: provider.isFirstBoot ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        )
                      : Container(
                    height: scaffoldHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Container(),
                            Icon(
                              Icons.downloading_rounded,
                              size: scaffoldHeight / 5,
                            ),
                            Container()
                          ]),
                        ),
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: Container(
                            width: scaffoldWidth,
                            child: Card(
                              color: Theme.of(context).colorScheme.onPrimary,
                              child: Padding(
                                padding: EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Loading...",
                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                    ),
                                    Text(provider.status, style: TextStyle(fontSize: 16)),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    LinearProgressIndicator(
                                      borderRadius: const BorderRadius.all(Radius.circular(3)),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  return provider.isFirstBoot ? firstBoot() : tgLogin();
                },
              );
            }),
          ));
    });
  }
}

class firstBoot extends StatefulWidget {
  @override
  firstBootState createState() => firstBootState();
}

class firstBootState extends State<firstBoot> {
  Widget infoCard(double width, String title, String desc, context) {
    return Container(
      width: width,
      child: Card(
        color: Theme.of(context).colorScheme.onPrimary,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              Text(desc, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
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
                          value: (provider.introPosition + (provider.switchIntro ? 1 : 2)) / (provider.introSequence.length - 1),
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                        ),
                        crossFadeState: !provider.switchIntro ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      ),
                      provider.isOffline
                          ? Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Container(
                                width: scaffoldWidth,
                                child: Card(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  child: Padding(
                                      padding: EdgeInsets.all(15),
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
                                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                ),
                                                Text(provider.dict("offline_desc"), style: TextStyle(fontSize: 16)),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.error_outline_rounded,
                                            size: 36,
                                          )
                                        ],
                                      )),
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                          crossFadeState: !provider.switchIntro ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        ),
                        Container()
                      ]),
                    ),
                    Column(
                      children: [
                        AnimatedCrossFade(
                          alignment: Alignment.center,
                          duration: provider.switchIntro ? Duration(milliseconds: 500) : Duration.zero,
                          firstChild: provider.introSequence[provider.introPosition].containsKey("selector")
                              ? provider.introSequence[provider.introPosition]["selector"]["type"] == "language"
                                  ? Container(
                                      width: scaffoldWidth,
                                      child: Card(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                provider.dict(provider.introPair[0]["title"]),
                                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                              ),
                                              Text(provider.dict(provider.introPair[0]["description"]), style: TextStyle(fontSize: 16)),
                                              Padding(
                                                padding: EdgeInsets.only(top: 15),
                                                child: DropdownMenu(
                                                  controller: provider.languageSelector,
                                                  initialSelection: provider.locale,
                                                  onSelected: (language) async {
                                                    provider.locale = language!;
                                                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                                                    prefs.setString("language", language!);
                                                    setState(() {});
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
                              ? provider.introSequence[provider.introPosition]["selector"]["type"] == "language"
                                  ? Container(
                                      width: scaffoldWidth,
                                      child: Card(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                provider.dict(provider.introPair[1]["title"]),
                                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                              ),
                                              Text(provider.dict(provider.introPair[1]["description"]), style: TextStyle(fontSize: 16)),
                                              Padding(
                                                padding: EdgeInsets.only(top: 15),
                                                child: DropdownMenu(
                                                  controller: provider.languageSelector,
                                                  initialSelection: provider.locale,
                                                  onSelected: (language) async {
                                                    provider.locale = language!;
                                                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                                                    prefs.setString("language", language!);
                                                    setState(() {});
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
                          crossFadeState: !provider.switchIntro ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      provider.unprogressIntroSequence();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [Icon(Icons.navigate_before_rounded)],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                    child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
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
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            provider.dict("done"),
                                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                          ),
                                          Icon(Icons.done_rounded)
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
                                            clipBehavior: Clip.hardEdge,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                provider.unprogressIntroSequence();
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [Icon(Icons.navigate_before_rounded)],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                              child: Card(
                                            color: Theme.of(context).colorScheme.onPrimary,
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
                                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                    ),
                                                    Icon(Icons.navigate_next_rounded)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )),
                                          Expanded(
                                              child: Card(
                                            color: Theme.of(context).colorScheme.errorContainer,
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
                                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                    ),
                                                    Icon(Icons.navigate_next_rounded)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )),
                                        ],
                                      )
                                    : Card(
                                        color: Theme.of(context).colorScheme.onPrimary,
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
                                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                ),
                                                Icon(Icons.navigate_next_rounded)
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                : Row(
                                    children: [
                                      Card(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        clipBehavior: Clip.hardEdge,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            provider.unprogressIntroSequence();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [Icon(Icons.navigate_before_rounded)],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Card(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        clipBehavior: Clip.hardEdge,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            provider.progressIntroSequence();
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.all(15),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  provider.dict("next"),
                                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                ),
                                                Icon(Icons.navigate_next_rounded)
                                              ],
                                            ),
                                          ),
                                        ),
                                      ))
                                    ],
                                  ),
                            crossFadeState: provider.introPosition > (provider.introSequence.length - 3) ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          ),
                        ),
                      ],
                    )
                    // infoCard(scaffoldWidth, provider.dict("welcome_title"), provider.dict("welcome_desc")),
                    // infoCard(scaffoldWidth, provider.dict("desc_title"), provider.dict("desc_desc")),
                    // infoCard(scaffoldWidth, provider.dict("reason_title"), provider.dict("reason_desc")),
                    // infoCard(scaffoldWidth, provider.dict("safety_title"), provider.dict("safety_desc")),
                  ])
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
  Widget infoCard(double width, String title, String desc, context) {
    return Container(
      width: width,
      child: Card(
        color: Theme.of(context).colorScheme.onPrimary,
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              Text(desc, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
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
                  child: Container(
                    height: scaffoldHeight,
                    width: scaffoldWidth,
                    child: AnimatedCrossFade(
                      alignment: Alignment.center,
                      duration: Duration(milliseconds: 500),
                      firstChild: Container(
                        height: scaffoldHeight,
                        width: scaffoldWidth,
                        child: appLoadingStage(),
                      ),
                      secondChild: Container(
                        height: scaffoldHeight,
                        width: scaffoldWidth,
                        child: HomePage(),
                      ),
                      crossFadeState: provider.userPic == "" ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    ),
                  ),
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
                            crossFadeState: provider.isWaitingNumber ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          ),
                        ),
                        crossFadeState: provider.isWaitingCode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      ),
                    ),
                    crossFadeState: provider.isWaitingPassword ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  ),
                ),
                crossFadeState: provider.isLoggedIn ? CrossFadeState.showFirst : CrossFadeState.showSecond,
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
                  SizedBox(
                    height: 5,
                  ), // shit code
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: provider.userData.containsKey("usernames")?(){

                          }:null,
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: provider.userPic == "NOPIC"
                                      ? Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    width: 60,
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        provider.userData["first_name"].toString()[0],
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                      ),
                                    ),
                                  )
                                      : Image.file(
                                    File(provider.userPic),
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${provider.userData["first_name"].toString()}${provider.userData["last_name"].toString() == "" ? "" : " "}${provider.userData["last_name"].toString()}",
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                      ),
                                      Text(provider.userData.containsKey("usernames") ? "@${provider.userData["usernames"]["editable_username"]}" : provider.dict("no_username"), style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )), // user info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.dict("indexed_channels"),
                                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                  ),
                                  Text("${provider.dict("channels")} ${provider.addedIndexes.length.toString()}", style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(fullscreenDialog: true, builder: (context) => NewIndexPage()),
                                  );
                                },
                                child: Text(
                                  provider.dict("add"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ), // indexing options
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.dict("indexed_messages"),
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(provider.totalIndexed.toString(), style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.dict("indexed_reposts"),
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(provider.totalReposts.toString(), style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.dict("indexed_relations"),
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(provider.totalRelations.toString(), style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider.dict("indexed_related"),
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(provider.knownChannels.length.toString(), style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(fullscreenDialog: true, builder: (context) => relationsMap()),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      provider.graphConstructed?provider.dict("constructed_graph"):provider.dict("constructing_graph"),
                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 5),
                                      child: Text(
                                          "${provider.graphDone.length.toString()} / ${provider.graphTotal.length.toString()}", style: TextStyle(fontSize: 16)
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                LinearProgressIndicator(
                                  value: provider.graphDone.length == 0?1:provider.graphDone.length/provider.graphTotal.length,
                                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                                )
                              ],
                            ),
                          ),
                        ),
                      )),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(fullscreenDialog: true, builder: (context) => SettingsPage()),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                provider.dict("settings"),
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              Icon(Icons.settings_rounded)
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

class SettingsPage extends StatefulWidget {
  @override
  SettingsPageState createState() => SettingsPageState();
}

class EdgeToEdgeTrackShape extends RoundedRectSliderTrackShape {
  // Override getPreferredRect to adjust the track's dimensions
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackWidth = parentBox.size.width;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, trackWidth, trackHeight);
  }
}

class RoundedThumbShape extends RoundSliderThumbShape {
  @override
  final double enabledThumbRadius;

  RoundedThumbShape({
    this.enabledThumbRadius = 10.0,
  }) : super(
          enabledThumbRadius: enabledThumbRadius,
        );

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    super.paint(
      context,
      center,
      activationAnimation: activationAnimation,
      enableAnimation: enableAnimation,
      isDiscrete: isDiscrete,
      labelPainter: labelPainter,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      textDirection: textDirection,
      value: value,
      textScaleFactor: textScaleFactor,
      sizeWithOverflow: sizeWithOverflow,
    );
  }
}

class SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  late BuildContext context;
  late double scaffoldWidth;
  late double scaffoldHeight;
  final MaterialStateProperty<Icon?> langicon = MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.android_rounded);
      }
      return const Icon(Icons.language_rounded);
    },
  );
  final MaterialStateProperty<Icon?> shareicon = MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.cloud_queue_rounded);
      }
      return const Icon(Icons.cloud_off_rounded);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.saveAll();
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
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Text(
                              provider.dict("settings"),
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.dict("settings_autosave_duration_title"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                        Text(provider.dict("settings_autosave_duration_desc").replaceAll("(SECONDS)", provider.autoSaveSeconds.toString()), style: TextStyle(fontSize: 16)),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        SliderTheme(
                                          data: SliderThemeData(
                                            overlayShape: SliderComponentShape.noOverlay,
                                            trackShape: EdgeToEdgeTrackShape(),
                                            thumbShape: RoundedThumbShape(enabledThumbRadius: 8.0),
                                          ),
                                          child: Slider(
                                            value: provider.autoSaveSeconds.toDouble(),
                                            min: 10,
                                            max: 100,
                                            divisions: 9,
                                            label: provider.dict("settings_autosave_duration_tip").replaceAll("(SECONDS)", provider.autoSaveSeconds.toString()),
                                            onChangeEnd: (value) {
                                              provider.saveAll();
                                              setState(() {
                                                provider.autoSaveSeconds = value.toInt();
                                              });
                                            },
                                            onChanged: (double value) {},
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  provider.dict("settings_language_title"),
                                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                ),
                                                Text(provider.dict(provider.systemLanguage ? "settings_language_system_desc" : "settings_language_desc"), style: TextStyle(fontSize: 16)),
                                              ],
                                            ),
                                            Switch(
                                              thumbIcon: langicon,
                                              value: provider.systemLanguage,
                                              onChanged: (value) {
                                                setState(() {
                                                  provider.systemLanguage = value;
                                                });
                                                if (value) {
                                                  provider.setSystemLanguage();
                                                }
                                                provider.saveAll();
                                              },
                                            ),
                                          ],
                                        ),
                                        provider.systemLanguage
                                            ? Container()
                                            : Padding(
                                                padding: EdgeInsets.only(top: 15),
                                                child: DropdownMenu(
                                                  controller: provider.languageSelector,
                                                  initialSelection: provider.locale,
                                                  onSelected: (language) async {
                                                    provider.locale = language!;
                                                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                                                    prefs.setString("language", language!);
                                                    provider.refresh();
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
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  provider.dict(provider.crowdsource ? "sharing_enabled_title" : "sharing_disabled_title"),
                                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                ),
                                                Text(provider.dict("sharing_title"), style: TextStyle(fontSize: 16)),
                                              ],
                                            ),
                                            Switch(
                                              thumbIcon: shareicon,
                                              value: provider.crowdsource,
                                              onChanged: (value) {
                                                setState(() {
                                                  provider.crowdsource = value;
                                                });
                                                provider.saveAll();
                                              },
                                            ),
                                          ],
                                        ),
                                        provider.crowdsource
                                            ? Container()
                                            : Padding(
                                                padding: EdgeInsets.only(top: 10),
                                                child: Text(provider.dict("sharing_disabled_desc"), style: TextStyle(fontSize: 16)),
                                              ),
                                      ],
                                    ),
                                  ),
                                )),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Card(
                                color: Theme.of(context).colorScheme.onPrimary,
                                clipBehavior: Clip.hardEdge,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                      EdgeInsets.only(left: 15, top: 15, right: 15),
                                      child: Text(
                                        provider.dict("developer_contact"),
                                        style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            fontFeatures: [
                                              FontFeature.proportionalFigures(),
                                            ]),
                                      ),
                                    ),
                                    Padding(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Wrap(
                                              spacing: 5.0,
                                              runSpacing: 0.0,
                                              alignment: WrapAlignment.start,
                                              runAlignment: WrapAlignment.start,
                                              verticalDirection: VerticalDirection.up,
                                              children: provider.authors["Authors"][0]["Links"]
                                                  .map((option) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                      right: provider.authors["Authors"][0]["Links"][provider.authors["Authors"][0]["Links"].length - 1] == option ? 10 : 0,
                                                      left: provider.authors["Authors"][0]["Links"][0] == option ? 10 : 0
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      launchUrl(Uri.parse(option["Link"]), mode: LaunchMode.externalApplication);
                                                    },
                                                    child: Chip(
                                                      label: Text(
                                                        option["Title"],
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      elevation: 5.0,
                                                    ),
                                                  ),
                                                );
                                              })
                                                  .toList()
                                                  .cast<Widget>(),
                                            )
                                        )
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
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
                          padding: EdgeInsets.only(left: 5),
                          child: TextField(
                            onChanged: (text) {
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
                              contentPadding: const EdgeInsets.only(top: 15, bottom: 0, left: 10, right: 10),
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
                    firstChild: Container(
                      width: scaffoldWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict(provider.loadingSearch
                                      ? "channel_searching_title"
                                      : provider.channelNotFound
                                          ? "channel_not_found_title"
                                          : "channel_search"),
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    provider.dict(provider.loadingSearch
                                        ? "channel_searching_desc"
                                        : provider.channelNotFound
                                            ? "channel_not_found_desc"
                                            : "channel_search_desc"),
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
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
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.updateIndexedChannels(provider.candidateChannel["id"].toString(), provider.candidateChannel);
                              provider.currentChannel = provider.candidateChannel;
                              provider.retreiveFullChannelInfo(provider.currentChannel["id"]);
                              provider.graphConnections.add(provider.currentChannel["id"]);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(fullscreenDialog: true, builder: (context) => IndexPage()),
                              );
                              provider.channelSearch.text = "";
                              provider.candidateChannel = {};
                            },
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Row(
                                children: [
                                  provider.candidateChannel.isEmpty
                                      ? Container()
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(10.0),
                                          child: provider.candidateChannel["picfile"] == "NOPIC"
                                              ? Container(
                                                  color: Theme.of(context).colorScheme.primaryContainer,
                                                  width: 60,
                                                  height: 60,
                                                  child: Center(
                                                    child: Text(
                                                      provider.candidateChannel["title"][0],
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                                    ),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(provider.candidateChannel["picfile"]),
                                                  width: 60,
                                                  height: 60,
                                                ),
                                        ),
                                  Container(
                                    width: scaffoldWidth - 88,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider.candidateChannel.isEmpty ? "" : provider.candidateChannel["title"],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                          ),
                                          Text(provider.candidateChannel.isEmpty ? "" : "@${provider.candidateChannel["username"]}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
  final MaterialStateProperty<Icon?> playicon = MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.play_arrow_rounded);
      }
      return const Icon(Icons.pause_rounded);
    },
  );
  bool showChannel = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.push(
            context,
            MaterialPageRoute(fullscreenDialog: true, builder: (context) => relationsMap()),
          );
        },
        child: Icon(Icons.query_stats_rounded),
      ),
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
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.isIndexing = false;
                              provider.confirmDelete = false;
                              provider.saveAll();
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
                          child: AnimatedCrossFade(
                            alignment: Alignment.center,
                            duration: Duration(milliseconds: 500),
                            firstChild: Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    clipBehavior: Clip.hardEdge,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          provider.confirmDelete = false;
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(15),
                                        child: Center(
                                          child: Text(
                                            provider.dict("cancel"),
                                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Card(
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    clipBehavior: Clip.hardEdge,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        provider.isIndexing = false;
                                        provider.deleteIndexedChannel(provider.currentChannel["id"].toString());
                                        provider.currentChannel = {};
                                        provider.confirmDelete = false;
                                        provider.saveAll();
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(15),
                                        child: Center(
                                          child: Text(
                                            provider.dict("confirm"),
                                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            secondChild: Row(
                              children: [
                                Expanded(
                                    child: Card(
                                  color: showChannel ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onPrimary.withOpacity(0.25),
                                  elevation: showChannel ? 5 : 0,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        showChannel = true;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Center(
                                        child: Text(
                                          provider.dict("channel_view"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                                Expanded(
                                    child: Card(
                                  color: showChannel ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.25) : Theme.of(context).colorScheme.onPrimary,
                                  elevation: showChannel ? 0 : 5,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        showChannel = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Center(
                                        child: Text(
                                          provider.dict("reposts_view"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                                Card(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        provider.confirmDelete = true;
                                      });
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
                            crossFadeState: provider.confirmDelete ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          ),
                        ),
                      ],
                    ),
                  ), // navigation
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: (){
                            if(provider.currentChannel.isNotEmpty){
                              launchUrl(Uri.parse("https://t.me/${provider.currentChannel["username"]}"), mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Row(
                              children: [
                                provider.currentChannel.isEmpty
                                    ? Container()
                                    : ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: provider.currentChannel.isEmpty
                                      ? Container()
                                      : ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: provider.currentChannel["picfile"] == "NOPIC"
                                        ? Container(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          provider.currentChannel["title"][0],
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                        ),
                                      ),
                                    )
                                        : Image.file(
                                      File(provider.currentChannel["picfile"]),
                                      width: 60,
                                      height: 60,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: scaffoldWidth - 88,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.currentChannel.isEmpty ? "" : provider.currentChannel["title"],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                        Text(provider.currentChannel.isEmpty ? "" : "@${provider.currentChannel["username"]}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )), // channel
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              provider.isIndexing = !provider.isIndexing;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(left: 15, right: 10, bottom: 10, top: 10),
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
                                              provider.isIndexing ? provider.dict(provider.indexingStatus) : provider.dict("indexed_title"),
                                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                            ),
                                            Text(provider.currentChannel.containsKey("donepercent") ? "${provider.currentChannel["donepercent"].toStringAsFixed(2)}%" : "0%", style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        LinearProgressIndicator(
                                          value: provider.currentChannel.containsKey("donepercent") ? provider.currentChannel["donepercent"] / 100 : 0,
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
                      )), // status
                  Container(
                    height: scaffoldHeight - 290,
                    child: AnimatedCrossFade(
                      alignment: Alignment.center,
                      duration: Duration(milliseconds: 100),
                      firstChild: SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.dict("subscribers"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                        Text(provider.currentChannel.containsKey("subs") ? provider.currentChannel["subs"].toString() : "0", style: TextStyle(fontFamily: provider.currentChannel.containsKey("subs") ? null : "Flow", fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.dict("messages"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                        Text(provider.currentChannel.containsKey("lastmsgid") ? provider.currentChannel["lastmsgid"].toString() : "0",
                                            style: TextStyle(fontFamily: provider.currentChannel.containsKey("lastmsgid") ? null : "Flow", fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.dict("reposts_view"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                        Text(provider.currentChannel.containsKey("reposts") ? provider.currentChannel["reposts"].toString() : "0", style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Card(
                                color: Theme.of(context).colorScheme.onPrimary,
                                child: Padding(
                                  padding: EdgeInsets.all(15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        provider.dict("indexed_relations"),
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                      ),
                                      Text(provider.currentChannel.containsKey("relations") ? provider.currentChannel["relations"].length.toString():"0", style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          provider.dict("indexed_messages"),
                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                        ),
                                        Text(provider.currentChannel.containsKey("lastindexedid") ? provider.currentChannel["lastindexedid"].toString() : "0", style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Card(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              provider.dict("reposts_ratio"),
                                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                                "${(provider.currentChannel.containsKey("donepercent") && provider.currentChannel.containsKey("reposts") && provider.currentChannel.containsKey("lastindexedid")) ? (((provider.currentChannel.containsKey("reposts") ? provider.currentChannel["reposts"] : 0) / (provider.currentChannel.containsKey("lastindexedid") ? provider.currentChannel["lastindexedid"] : 0)) * 100).toStringAsFixed(2) : 0}%",
                                                style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        LinearProgressIndicator(
                                          value: (provider.currentChannel.containsKey("donepercent") && provider.currentChannel.containsKey("reposts") && provider.currentChannel.containsKey("lastindexedid"))
                                              ? ((provider.currentChannel.containsKey("reposts") ? provider.currentChannel["reposts"] : 0) / (provider.currentChannel.containsKey("lastindexedid") ? provider.currentChannel["lastindexedid"] : 0))
                                              : 0,
                                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                                        )
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                      secondChild: provider.currentChannel.containsKey("relations")
                          ? SingleChildScrollView(
                              child: Column(
                                children: provider.currentChannel["relations"].keys
                                    .toList()
                                    .reversed
                                    .map((relation) {
                                      if (provider.knownChannels.containsKey(relation.toString())) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 5),
                                          child: Container(
                                            width: scaffoldWidth,
                                            child: Card(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              clipBehavior: Clip.hardEdge,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  if(provider.addedIndexes.containsKey(provider.knownChannels[relation.toString()]["id"].toString())){
                                                    provider.currentChannel = provider.addedIndexes[provider.knownChannels[relation.toString()]["id"].toString()];
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(fullscreenDialog: true, builder: (context) => IndexPage()),
                                                    );
                                                  }else{
                                                    if(!(provider.knownChannels[relation.toString()]["username"]=="deleted")){
                                                      provider.channelSearch.text = provider.knownChannels[relation.toString()]["username"];
                                                      provider.searchChannel();
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(fullscreenDialog: true, builder: (context) => NewIndexPage()),
                                                      );
                                                    }
                                                  }
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(5),
                                                  child: Row(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        child: (provider.knownChannels[relation.toString()]["picfile"] == "NOPIC" || !provider.knownChannels[relation.toString()].containsKey("picfile"))
                                                            ? Container(
                                                          color: Theme.of(context).colorScheme.primaryContainer,
                                                          width: 60,
                                                          height: 60,
                                                          child: Center(
                                                            child: Text(
                                                              provider.knownChannels[relation.toString()]["title"][0],
                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                                            ),
                                                          ),
                                                        )
                                                            : Image.file(
                                                          File(provider.knownChannels[relation.toString()]["picfile"]),
                                                          width: 60,
                                                          height: 60,
                                                        ),
                                                      ),
                                                      Container(
                                                        width: scaffoldWidth - 88,
                                                        child: Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                provider.knownChannels[relation.toString()]["title"],
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                              ),
                                                              Text("${provider.dict("reposts")} ${provider.currentChannel["relations"][relation]["reposts"]}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16)),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 5),
                                        child: Container(
                                          width: scaffoldWidth,
                                          child: Card(
                                            color: Theme.of(context).colorScheme.onPrimary,
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
                                                        child: Icon(
                                                          Icons.downloading_rounded,
                                                          size: 24,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Loading...",
                                                          style: TextStyle(fontFamily: "Flow", fontSize: 19, fontWeight: FontWeight.bold),
                                                        ),
                                                        Text("${provider.dict("reposts")} ${provider.currentChannel["relations"][relation]["reposts"]}", style: TextStyle(fontSize: 16)),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                      return Text("${provider.knownChannels.containsKey(relation) ? "${provider.knownChannels[relation]["title"]}" : "Unknown"} - ${provider.currentChannel["relations"][relation]["reposts"]} reposts");
                                    })
                                    .toList()
                                    .cast<Widget>(),
                              ),
                            )
                          : provider.currentChannel.containsKey("lastmsgid")
                              ? Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Card(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Container(
                                        width: scaffoldWidth,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              provider.dict("no_relations_title"),
                                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                            ),
                                            Text(provider.dict("no_relations_desc"), style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))
                              : Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Card(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    child: Padding(
                                      padding: EdgeInsets.all(15),
                                      child: Container(
                                        width: scaffoldWidth,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              provider.dict("no_messages_title"),
                                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                            ),
                                            Text(provider.dict("no_messages_desc"), style: TextStyle(fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )),
                      crossFadeState: showChannel ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    ),
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
                  SizedBox(
                    height: 5,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
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
                          padding: EdgeInsets.only(left: 5),
                          child: TextField(
                            onChanged: (text) {
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
                              contentPadding: const EdgeInsets.only(top: 15, bottom: 0, left: 10, right: 10),
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
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Card(
                            color: Theme.of(context).colorScheme.onPrimary,
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.dict("no_indexed_title"),
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                      ),
                                      Text(provider.dict("no_indexed_desc"), style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  FilledButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(fullscreenDialog: true, builder: (context) => NewIndexPage()),
                                        );
                                      },
                                      child: Text(provider.dict("add"), style: TextStyle(fontSize: 16)))
                                ],
                              ),
                            ),
                          ))
                      : SingleChildScrollView(
                          child: Column(
                            children: provider.displayIndexes
                                .map((channel) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 5),
                                    child: Container(
                                      width: scaffoldWidth,
                                      child: Card(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        clipBehavior: Clip.hardEdge,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            provider.currentChannel = provider.addedIndexes[channel["id"].toString()];
                                            // provider.createGraph();
                                            provider.retreiveFullChannelInfo(channel["id"]);
                                            provider.confirmDelete = false;
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
                                                  child: channel["picfile"] == "NOPIC"
                                                      ? Container(
                                                          color: Theme.of(context).colorScheme.primaryContainer,
                                                          width: 60,
                                                          height: 60,
                                                          child: Center(
                                                            child: Text(
                                                              channel["title"][0],
                                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                                            ),
                                                          ),
                                                        )
                                                      : Image.file(
                                                          File(channel["picfile"]),
                                                          width: 60,
                                                          height: 60,
                                                        ),
                                                ),
                                                Container(
                                                  width: scaffoldWidth - 88,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(top: 0, left: 15, right: 5, bottom: 5),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          channel["title"],
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                                        ),
                                                        Text("@${channel["username"]}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(height: 0.9, fontSize: 16)),
                                                        channel.containsKey("donepercent")
                                                            ? Padding(
                                                                padding: EdgeInsets.only(top: 10),
                                                                child: LinearProgressIndicator(
                                                                  value: channel.containsKey("donepercent") ? channel["donepercent"] / 100 : 0,
                                                                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                                                                ),
                                                              )
                                                            : Container()
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .toList()
                                .cast<Widget>(),
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(),
                      Icon(
                        Icons.downloading_rounded,
                        size: scaffoldHeight / 5,
                      ),
                      Container()
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Container(
                      width: scaffoldWidth,
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                provider.dict("loading_title"),
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              Text(provider.dict("loading_desc"), style: TextStyle(fontSize: 16)),
                              SizedBox(
                                height: 10,
                              ),
                              LinearProgressIndicator(
                                borderRadius: const BorderRadius.all(Radius.circular(3)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
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

class relationsMap extends StatefulWidget {
  @override
  relationsMapState createState() => relationsMapState();
}

class relationsMapState extends State<relationsMap> {
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
            FruchtermanReingoldAlgorithm builder = FruchtermanReingoldAlgorithm(repulsionRate: 0.02, attractionRate: 0.005, renderer: ArrowEdgeRenderer()..trianglePath = Path());
            if(!provider.graphConstructed){
              return Container(
                height: scaffoldHeight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(),
                        Icon(
                          Icons.query_stats_rounded,
                          size: scaffoldHeight / 5,
                        ),
                        Container()
                      ]),
                    ),
                    Padding(
                      padding: EdgeInsets.all(5),
                      child: Container(
                        width: scaffoldWidth,
                        child: Card(
                          color: Theme.of(context).colorScheme.onPrimary,
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      provider.graphConstructed?provider.dict("constructed_graph"):provider.dict("constructing_graph"),
                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 5),
                                      child: Text(
                                          "${provider.graphDone.length.toString()} / ${provider.graphTotal.length.toString()}", style: TextStyle(fontSize: 16)
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                LinearProgressIndicator(
                                  value: provider.graphDone.length == 0?1:provider.graphDone.length/provider.graphTotal.length,
                                  borderRadius: const BorderRadius.all(Radius.circular(3)),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Stack(
              children: [
                Expanded(
                  child: InteractiveViewer(
                      constrained: false,
                      minScale: 0.0001,
                      maxScale: 100000,
                      child: GraphView(
                        graph: provider.graph,
                        algorithm: builder,
                        builder: (Node node) {
                          var a = node.key?.value;
                          double nodeSize = 5;
                          Offset nodeOffset = Offset.zero;
                          if(provider.currentChannel.isNotEmpty){
                            if(provider.currentChannel["id"].toString() == a.toString()){
                              nodeSize = 10;
                              nodeOffset = Offset(1,1);
                            }
                          }
                          return Transform.translate(
                              offset: nodeOffset,
                              child: ClipRRect(
                                clipBehavior: Clip.hardEdge,
                                borderRadius: BorderRadius.circular(nodeSize / 2),
                                child: InkWell(
                                  onTap: () {
                                    if(provider.addedIndexes.containsKey(a.toString())){
                                      provider.displayChannel = provider.addedIndexes[a.toString()];
                                    }else{
                                      if(provider.knownChannels.containsKey(a.toString())){
                                        provider.displayChannel = provider.knownChannels[a.toString()];
                                      }
                                    }
                                    setState(() {

                                    });
                                  },
                                  child: (provider.knownChannels[a]["picfile"] == "NOPIC" || provider.knownChannels[a]["picfile"] == null)
                                      ? Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    width: nodeSize,
                                    height: nodeSize,
                                    child: Center(
                                      child: Text(
                                        provider.knownChannels[a]["title"].toString()[0],
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: nodeSize / 2),
                                      ),
                                    ),
                                  )
                                      : Image.file(
                                    File(provider.knownChannels[a]["picfile"]),
                                    width: nodeSize,
                                    height: nodeSize,
                                  ),
                                ),
                              )
                          );
                        },
                      )),
                ),
                Positioned(
                  top:5,
                    left: 5,
                    child: Card(
                  color: Theme.of(context).colorScheme.onPrimary,
                  clipBehavior: Clip.hardEdge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () {
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
                )
                ),
                provider.displayChannel.isEmpty?Container()
                    : Positioned(
                    bottom: 10,
                    right: 5,
                    left: 5,
                    child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Container(
                    width: scaffoldWidth,
                    child: Card(
                      color: Theme.of(context).colorScheme.onPrimary,
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        onTap: () {
                          if(provider.addedIndexes.containsKey(provider.displayChannel["id"].toString())){
                            provider.currentChannel = provider.addedIndexes[provider.displayChannel["id"].toString()];
                            Navigator.push(
                              context,
                              MaterialPageRoute(fullscreenDialog: true, builder: (context) => IndexPage()),
                            );
                          }else{
                            if(!(provider.displayChannel["username"]=="deleted")){
                              provider.channelSearch.text = provider.displayChannel["username"];
                              provider.searchChannel();
                              Navigator.push(
                                context,
                                MaterialPageRoute(fullscreenDialog: true, builder: (context) => NewIndexPage()),
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.all(5),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: provider.displayChannel["picfile"] == "NOPIC"
                                    ? Container(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  width: 60,
                                  height: 60,
                                  child: Center(
                                    child: Text(
                                      provider.displayChannel["title"][0],
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                    ),
                                  ),
                                )
                                    : Image.file(
                                  File(provider.displayChannel["picfile"]),
                                  width: 60,
                                  height: 60,
                                ),
                              ),
                              Container(
                                width: scaffoldWidth - 98,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 0, left: 15, right: 5, bottom: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.displayChannel["title"],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                      ),
                                      Text("@${provider.displayChannel["username"]}", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(height: 0.9, fontSize: 16)),
                                      provider.displayChannel.containsKey("donepercent")
                                          ? Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: LinearProgressIndicator(
                                          value: provider.displayChannel.containsKey("donepercent") ? provider.displayChannel["donepercent"] / 100 : 0,
                                          borderRadius: const BorderRadius.all(Radius.circular(3)),
                                        ),
                                      )
                                          : Container()
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ))
              ],
            );
          },
        ),
      ),
    );
  }
}

class appLoadingStage extends StatefulWidget {
  @override
  appLoadingStageState createState() => appLoadingStageState();
}

class appLoadingStageState extends State<appLoadingStage> {
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(),
                      Icon(
                        Icons.downloading_rounded,
                        size: scaffoldHeight / 5,
                      ),
                      Container()
                    ]),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Container(
                      width: scaffoldWidth,
                      child: Card(
                        color: Theme.of(context).colorScheme.onPrimary,
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                provider.dict("user_loading_title"),
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                              ),
                              Text(provider.dict("user_loading_desc"), style: TextStyle(fontSize: 16)),
                              SizedBox(
                                height: 10,
                              ),
                              LinearProgressIndicator(
                                borderRadius: const BorderRadius.all(Radius.circular(3)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(),
                      Icon(
                        Icons.dialpad_rounded,
                        size: scaffoldHeight / 5,
                      ),
                      Container()
                    ]),
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
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict("login_title"),
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                                Text(provider.dict("login_desc"), style: TextStyle(fontSize: 16)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
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
                                      contentPadding: const EdgeInsets.only(top: 15, bottom: 0, left: 10, right: 10),
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
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.doNumberLogin();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.dict("next"),
                                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                  ),
                                  Icon(Icons.navigate_next_rounded)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      )
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(),
                      Icon(
                        Icons.pin_rounded,
                        size: scaffoldHeight / 5,
                      ),
                      Container()
                    ]),
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
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict("code_title"),
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                                Text(provider.dict("code_desc"), style: TextStyle(fontSize: 16)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
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
                                      contentPadding: const EdgeInsets.only(top: 15, bottom: 0, left: 10, right: 10),
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
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.doCodeLogin();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.dict("next"),
                                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                  ),
                                  Icon(Icons.navigate_next_rounded)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      )
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
                    child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(),
                      Icon(
                        Icons.password_rounded,
                        size: scaffoldHeight / 5,
                      ),
                      Container()
                    ]),
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
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  provider.dict("password_title"),
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                ),
                                Text(provider.dict("password_desc"), style: TextStyle(fontSize: 16)),
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
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
                                      contentPadding: const EdgeInsets.only(top: 15, bottom: 0, left: 10, right: 10),
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
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              provider.doPwdLogin();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    provider.dict("login_title"),
                                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                                  ),
                                  Icon(Icons.done_rounded)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      )
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
