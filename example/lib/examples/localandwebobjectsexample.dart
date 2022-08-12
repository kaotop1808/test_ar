import 'dart:io';

import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_archive/flutter_archive.dart';

class LocalAndWebObjectsWidget extends StatefulWidget {
  LocalAndWebObjectsWidget({Key key}) : super(key: key);

  @override
  _LocalAndWebObjectsWidgetState createState() => _LocalAndWebObjectsWidgetState();
}

class _LocalAndWebObjectsWidgetState extends State<LocalAndWebObjectsWidget> {
  ARSessionManager arSessionManager;
  ARObjectManager arObjectManager;
  ARAnchorManager arAnchorManager;

  //String localObjectReference;
  ARNode localObjectNode;

  //String webObjectReference;
  ARNode webObjectNode;
  ARNode fileSystemNode;
  HttpClient httpClient;
  String file;

  List<ARAnchor> anchors = [];
  List<ARNode> nodes = [];

  @override
  void dispose() {
    super.dispose();
    arSessionManager.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Local & Web Objects'),
        ),
        body: Container(
            child: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          Align(
              alignment: FractionalOffset.bottomCenter,
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     ElevatedButton(
                //         onPressed: onFileSystemObjectAtOriginButtonPressed,
                //         child: Text("Add/Remove Filesystem\nObject at Origin")),
                //   ],
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     ElevatedButton(
                //         onPressed: onLocalObjectAtOriginButtonPressed,
                //         child: Text("Add/Remove Local\nObject at Origin")),
                //     ElevatedButton(
                //         onPressed: onWebObjectAtOriginButtonPressed,
                //         child: Text("Add/Remove Web\nObject at Origin")),
                //   ],
                // ),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //   children: [
                //     ElevatedButton(
                //         onPressed: onLocalObjectShuffleButtonPressed,
                //         child: Text("Shuffle Local\nobject at Origin")),
                //     ElevatedButton(
                //         onPressed: onWebObjectShuffleButtonPressed,
                //         child: Text("Shuffle Web\nObject at Origin")),
                //   ],
                // )
              ]))
        ])));
  }

  Future<void> onARViewCreated(ARSessionManager arSessionManager, ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager, ARLocationManager arLocationManager) async {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager.onInitialize(
          showAnimatedGuide: false,
          showFeaturePoints: true,
          showPlanes: true,
          customPlaneTexturePath: "Images/triangle.png",
          showWorldOrigin: false,
          handleTaps: true,
          handleRotation: true,
        );
    this.arObjectManager.onInitialize();

    this.arSessionManager.onPlaneOrPointTap = onPlaneOrPointTapped;
    //Download model to file system
    httpClient = new HttpClient();
    // print('Start dpwnload');
    // _downloadFile(
    //     "https://drive.google.com/u/0/uc?id=16sx2j6ovrSjAsu4J63K4RQnlLyrw6A-c&export=download&confirm=t&uuid=e83288b8-38e6-451b-9499-74900c75f189", "House.glb");
    // Alternative to use type fileSystemAppFolderGLTF2:
    //_downloadAndUnpack(
    //    "https://drive.google.com/uc?export=download&id=1fng7yiK0DIR0uem7XkV2nlPSGH9PysUs",
    //    "Chicken_01.zip");
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
            (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    if (singleHitTestResult != null) {
      var newAnchor =
      ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool didAddAnchor = await this.arAnchorManager.addAnchor(newAnchor);
      if (didAddAnchor) {
        this.anchors.clear();
        this.anchors.add(newAnchor);
        // Add note to anchor
        EasyLoading.show(status: 'loading', dismissOnTap: false);
        var newNode = ARNode(
            type: NodeType.fileSystemAppFolderGLB,
            uri: 'Hihi.glb',
            scale: Vector3(0.2, 0.2, 0.2),
            position: Vector3(0.0, 0.0, 0.0),
            rotation: Vector4(1.0, 0.0, 0.0, 0.0));
        bool didAddNodeToAnchor =
        await this.arObjectManager.addNode(newNode, planeAnchor: newAnchor);
        EasyLoading.dismiss();
        if (didAddNodeToAnchor) {
          this.nodes.clear();
          this.nodes.add(newNode);
        } else {
          this.arSessionManager.onError("Adding Node to Anchor failed");
        }
      } else {
        this.arSessionManager.onError("Adding Anchor failed");
      }
    }
  }

  Future<void> _downloadAndUnpack(String url, String filename) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    print("Downloading finished, path: " + '$dir/$filename');

    // To print all files in the directory: print(Directory(dir).listSync());
    try {
      await ZipFile.extractToDirectory(
          zipFile: File('$dir/$filename'), destinationDir: Directory(dir));
      print("Unzipping successful");
    } catch (e) {
      print("Unzipping failed: " + e);
    }
  }

  Future<void> onLocalObjectAtOriginButtonPressed() async {
    if (this.localObjectNode != null) {
      this.arObjectManager.removeNode(this.localObjectNode);
      this.localObjectNode = null;
    } else {
      var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: "Models/house/scene.gltf",
          scale: Vector3(0.2, 0.2, 0.2),
          position: Vector3(0.0, 0.0, 0.0),
          rotation: Vector4(1.0, 0.0, 0.0, 0.0));
      bool didAddLocalNode = await this.arObjectManager.addNode(newNode);
      this.localObjectNode = (didAddLocalNode) ? newNode : null;
    }
  }

  Future<void> onWebObjectAtOriginButtonPressed() async {
    if (this.webObjectNode != null) {
      this.arObjectManager.removeNode(this.webObjectNode);
      this.webObjectNode = null;
    } else {
      var newNode = ARNode(
          type: NodeType.webGLB,
          uri: "https://github.com/kaotop1808/hihitson/blob/testar/shiba.glb?raw=true",
          scale: Vector3(0.2, 0.2, 0.2));
      bool didAddWebNode = await this.arObjectManager.addNode(newNode);
      this.webObjectNode = (didAddWebNode) ? newNode : null;
    }
  }

  Future<void> onFileSystemObjectAtOriginButtonPressed() async {
    if (this.fileSystemNode != null) {
      this.arObjectManager.removeNode(this.fileSystemNode);
      this.fileSystemNode = null;
    } else {
      try {
        var newNode = ARNode(
            type: NodeType.fileSystemAppFolderGLB,
            // uri: 'LowQualityHouse.glb',
            uri: 'Hihi.glb',
            scale: Vector3(0.5, 0.5, 0.5));
        //Alternative to use type fileSystemAppFolderGLTF2:
        //var newNode = ARNode(
        //    type: NodeType.fileSystemAppFolderGLTF2,
        //    uri: "Chicken_01.gltf",
        //    scale: Vector3(0.2, 0.2, 0.2));
        bool didAddFileSystemNode = await this.arObjectManager.addNode(newNode);
        this.fileSystemNode = (didAddFileSystemNode) ? newNode : null;
      } catch (error) {
        print('ERRROR -- $error');
      }
    }
  }

  Future<void> onLocalObjectShuffleButtonPressed() async {
    if (this.localObjectNode != null) {
      var newScale = Random().nextDouble() / 3;
      var newTranslationAxis = Random().nextInt(3);
      var newTranslationAmount = Random().nextDouble() / 3;
      var newTranslation = Vector3(0, 0, 0);
      newTranslation[newTranslationAxis] = newTranslationAmount;
      var newRotationAxisIndex = Random().nextInt(3);
      var newRotationAmount = Random().nextDouble();
      var newRotationAxis = Vector3(0, 0, 0);
      newRotationAxis[newRotationAxisIndex] = 1.0;

      final newTransform = Matrix4.identity();

      newTransform.setTranslation(newTranslation);
      newTransform.rotate(newRotationAxis, newRotationAmount);
      newTransform.scale(newScale);

      this.localObjectNode.transform = newTransform;
    }
  }

  Future<void> onWebObjectShuffleButtonPressed() async {
    if (this.webObjectNode != null) {
      var newScale = Random().nextDouble() / 3;
      var newTranslationAxis = Random().nextInt(3);
      var newTranslationAmount = Random().nextDouble() / 3;
      var newTranslation = Vector3(0, 0, 0);
      newTranslation[newTranslationAxis] = newTranslationAmount;
      var newRotationAxisIndex = Random().nextInt(3);
      var newRotationAmount = Random().nextDouble();
      var newRotationAxis = Vector3(0, 0, 0);
      newRotationAxis[newRotationAxisIndex] = 1.0;

      final newTransform = Matrix4.identity();

      newTransform.setTranslation(newTranslation);
      newTransform.rotate(newRotationAxis, newRotationAmount);
      newTransform.scale(newScale);

      this.webObjectNode.transform = newTransform;
    }
  }
}
