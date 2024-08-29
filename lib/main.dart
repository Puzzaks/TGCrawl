import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<tgProvider>(context, listen: false).launch();
    });
    return HomeScreen();
  }
}

class HomeScreen extends StatelessWidget {
  static final _defaultLightColorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.teal);
  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(primarySwatch: Colors.teal, brightness: Brightness.dark);
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
        home: Consumer<tgProvider>(
          builder: (context, provider, child) {
            return Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  double scaffoldHeight = constraints.maxHeight;
                  double scaffoldWidth = constraints.maxWidth;
                 return SafeArea(
                     child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        Builder(
                          builder: (context) {
                            if(provider.isWaitingPassword){
                              return Container(
                                width: scaffoldWidth,
                                child: Card(
                                  elevation: 5,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Please enter your password:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold
                                          ),
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
                                            maxLines: null,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                                              prefixIcon: Icon(Icons.password_rounded),
                                              labelText: 'Enter password',
                                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(),
                                              ElevatedButton(
                                                onPressed: (){
                                                  provider.doPwdLogin();
                                                },
                                                child: Text(
                                                    "Send"
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            if(provider.isWaitingCode){
                              return Container(
                                width: scaffoldWidth,
                                child: Card(
                                  elevation: 5,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Please enter your phone number:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold
                                          ),
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
                                              labelText: 'Enter Code',
                                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(),
                                              ElevatedButton(
                                                onPressed: (){
                                                  provider.doCodeLogin();
                                                },
                                                child: Text(
                                                    "Send"
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            if(provider.isWaitingNumber){
                              return Container(
                                width: scaffoldWidth,
                                child: Card(
                                  elevation: 5,
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Please enter your phone number:",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold
                                          ),
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
                                              labelText: 'Enter number',
                                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(),
                                              ElevatedButton(
                                                onPressed: (){
                                                  provider.doNumberLogin();
                                                },
                                                child: Text(
                                                    "Send"
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              height: scaffoldHeight,
                              child: SingleChildScrollView(
                                child: Column(
                                    children: provider.updates.map((update) {
                                      return Card(
                                        elevation: 5,
                                        child: Padding(
                                          padding: EdgeInsets.all(15),
                                          child: Text(update.toString()),
                                        ),
                                      );
                                    }).toList()
                                ),
                              ),
                            );
                          }
                        ),
                       Container(
                         width: scaffoldWidth,
                         child: Card(
                           elevation: 5,
                           child: Padding(
                             padding: EdgeInsets.all(15),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   provider.status,
                                   style: TextStyle(
                                       fontWeight: FontWeight.bold
                                   ),
                                 ),
                                 Text("${provider.updates.isEmpty?"":provider.updates[0]["@type"]}"),
                                 Padding(
                                   padding: const EdgeInsets.only(top:15),
                                   child: TextField(
                                     controller: provider.password,
                                     autofocus: true,
                                     keyboardType: TextInputType.text,
                                     textAlignVertical: TextAlignVertical.top,
                                     scrollPadding: const EdgeInsets.all(0),
                                     expands: false,
                                     minLines: null,
                                     maxLines: null,
                                     decoration: InputDecoration(
                                       contentPadding: const EdgeInsets.only(top:15, bottom: 0,left: 10, right: 10),
                                       prefixIcon: const Icon(Icons.lock_person_rounded),
                                       labelText: 'Enter Bot Key',
                                       border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Colors.grey)),
                                     ),
                                   ),
                                 ),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                   children: [
                                     ElevatedButton(
                                       onPressed: (){
                                         provider.doPwdLogin();
                                       },
                                       child: Text(
                                           "Password"
                                       ),
                                     ),
                                     ElevatedButton(
                                       onPressed: (){
                                         provider.doReadUpdates = !provider.doReadUpdates;
                                       },
                                       child: Text(
                                           "loader?"
                                       ),
                                     ),
                                     ElevatedButton(
                                       onPressed: (){
                                         provider.doCodeLogin();
                                       },
                                       child: Text(
                                           "Code"
                                       ),
                                     )
                                   ],
                                 )
                               ],
                             ),
                           ),
                         ),
                       ),
                     ]
                 )
                 );
                },
              ),
            );
          },
        ),
      );
    });
  }
}