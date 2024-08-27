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
                 return SafeArea(child: SingleChildScrollView(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       provider.isAppReady?Container(
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
                                 controller: provider.botkey,
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
                             )
                           ],
                         ),
                       ),
                     ),
                   ):Container(
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
                                 LinearProgressIndicator(
                                   value: provider.isLoginReady?1:provider.updates.length==null?0:provider.updates.length / 51,
                                   backgroundColor: Colors.transparent,
                                   borderRadius: const BorderRadius.all(Radius.circular(3)),
                                   color: Theme.of(context).colorScheme.primary,
                                 )
                               ],
                             ),
                           ),
                         ),
                       ),
                     ]
                   ),
                 ));
                },
              ),
            );
          },
        ),
      );
    });
  }
}