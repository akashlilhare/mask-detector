import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage imgCamera;
  CameraController cameraController;
  bool isWorking = false;
  String result = "";

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((imageFromStream) {
          if (!isWorking) {
            setState(() {
              isWorking = true;
              imgCamera = imageFromStream;
              runModelOnFrame();
            });
          }
        });
      });
    });
  }

  runModelOnFrame() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: imgCamera.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: imgCamera.height,
          imageWidth: imgCamera.width,
          imageStd: 127.5,
          imageMean: 127.5,
          rotation: 90,
          numResults: 1,
          threshold: 0.1,
          asynch: true);
      result = "";
      recognitions.forEach((element) {
        result += element["label"] + "\n";
      });

      setState(() {
        result = result;
      });
      isWorking = false;
    }
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void initState() {
    initCamera();
    loadModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: true,
            title: Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Text(
                result,
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
            ),
            backgroundColor: Colors.black,
          ),
          body: Column(
            children: [
              Positioned(
                  top: 0,
                  left: 0,
                  width: width,
                  // height: height,
                  child: (!cameraController.value.isInitialized)
                      ? Container()
                      : Container(
                          color: Colors.black,
                          height: height - 83,
                          child: AspectRatio(
                            aspectRatio: cameraController.value.aspectRatio,
                            child: CameraPreview(cameraController),
                          ),
                        )),
            ],
          ),
        ),
      ),
    );
  }
}
