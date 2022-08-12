import 'dart:io';

import 'package:ar_flutter_plugin_example/examples/externalmodelmanagementexample.dart';
import 'package:ar_flutter_plugin_example/examples/objectsonplanesexample.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

import 'package:ar_flutter_plugin_example/examples/cloudanchorexample.dart';
import 'package:ar_flutter_plugin_example/examples/localandwebobjectsexample.dart';
import 'package:ar_flutter_plugin_example/examples/debugoptionsexample.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';

import 'examples/objectgesturesexample.dart';
import 'examples/screenshotexample.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = true;

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  static const String _title = 'AR Demo';
  HttpClient httpClient;

  @override
  void initState() {
    super.initState();
    httpClient = new HttpClient();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ArFlutterPlugin.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Column(children: [
          Text('Running on: $_platformVersion\n'),
          Expanded(
            child: ExampleList(httpClient: this.httpClient),
          ),
        ]),
      ),
    );
  }
}

class ExampleList extends StatelessWidget {
  ExampleList({Key key, this.httpClient}) : super(key: key);
  HttpClient httpClient;


  @override
  Widget build(BuildContext context) {
    final examples = [
      // Example(
      //     'Debug Options',
      //     'Visualize feature points, planes and world coordinate system',
      //     () => Navigator.push(context,
      //         MaterialPageRoute(builder: (context) => DebugOptionsWidget()))),
      Example(
          'Downloaded Objects',
          'Place 3D objects into the scene',
          () async {
            bool fileExist = await checkFileExist();
            if(fileExist) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LocalAndWebObjectsWidget()));
            } else {
              EasyLoading.show(status: 'loading', dismissOnTap: false);
              await _downloadFile(
                  "https://drive.google.com/u/0/uc?id=1ZBtRRm4tQXieGiGRy0C2o_h-4k2EJJiB&export=download&confirm=t&uuid=2831408d-15d3-4c7c-bdb1-8ea183cddc9a", "Hihi.glb");
              EasyLoading.dismiss();
            }
          }),
      // Example(
      //     'Online Objects',
      //     'Place 3D objects on detected planes using anchors',
      //     () => Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //             builder: (context) => ObjectsOnPlanesWidget()))),
      Example(
          'Online Objects',
          'Rotate and Pan Objects',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => ObjectGesturesWidget()))),
      // Example(
      //     'Screenshots',
      //     'Place 3D objects on planes and take screenshots',
      //     () => Navigator.push(context,
      //         MaterialPageRoute(builder: (context) => ScreenshotWidget()))),
      // Example(
      //     'Cloud Anchors',
      //     'Place and retrieve 3D objects using the Google Cloud Anchor API',
      //     () => Navigator.push(context,
      //         MaterialPageRoute(builder: (context) => CloudAnchorWidget()))),
      // Example(
      //     'External Model Management',
      //     'Similar to Cloud Anchors example, but uses external database to choose from available 3D models',
      //     () => Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //             builder: (context) => ExternalModelManagementWidget())))
    ];
    return ListView(
      children:
          examples.map((example) => ExampleCard(example: example)).toList(),
    );
  }


  Future<bool> checkFileExist() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    bool exist = await File('$dir/Hihi.glb').exists();
    print("EXIST === $exist");
    return exist;
  }

  Future<String> _downloadFile(String url, String filename) async {
    print('START DOWNLOAD');
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response, onBytesReceived: (a, b) {
      print('ONDOWNLOAD -- $a / $b');
    });
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    print("DOWNLOAD FINISH, path: " + '$dir/$filename');
    return '$dir/$filename';
  }
}

class ExampleCard extends StatelessWidget {
  ExampleCard({Key key, this.example}) : super(key: key);
  final Example example;

  @override
  build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Colors.blue.withAlpha(30),
        onTap: () {
          example.onTap();
        },
        child: ListTile(
          title: Text(example.name),
          subtitle: Text(example.description),
        ),
      ),
    );
  }
}

class Example {
  const Example(this.name, this.description, this.onTap);
  final String name;
  final String description;
  final Function onTap;
}
