import 'dart:io';
import 'dart:async';
import 'package:fhoto_editor/image_crop.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Cropping extends StatefulWidget {
  const Cropping({Key? key}) : super(key: key);

  @override
  State<Cropping> createState() => _CroppingState();
}

class _CroppingState extends State<Cropping> {
  final cropKey = GlobalKey<CropState>();
  late File _file = File("path");
  late File _sample = File("path");
  late File _lastCropped = File("path");
  late File croppedFile = File("path");

  @override
  void dispose() {
    super.dispose();
    _file?.delete();
    _sample?.delete();
    _lastCropped?.delete();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: _sample == null ? _buildOpeningImage() : _buildCroppingImage(),
        ),
      ),
    );
  }

  Widget _buildOpeningImage() {
    return Center(child: _buildOpenImage());
  }

  Widget _buildCroppingImage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(_sample, key: cropKey),
        ),
        Expanded(
          child: Image.file(File(croppedFile.path)),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                child: Text(
                  'Crop Image',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      ?.copyWith(color: Colors.white),
                ),
                onPressed: () async {
                  croppedFile = (await _cropImage())!;
                  setState(() {});
                },
              ),
              _buildOpenImage(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOpenImage() {
    return TextButton(
      child: Text(
        'Open Image',
        style:
            Theme.of(context).textTheme.button?.copyWith(color: Colors.white),
      ),
      onPressed: () => _openImage(),
    );
  }

  Future<void> _openImage() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    final file = File(pickedFile?.path as String);
    final sample = await  ImageCrop.getInstance().sampleImage(file: file, preferredSize: context.size?.longestSide.ceil());
  /*  final sample = await ImageCrop.sampleImage(
      file: file,
      preferredSize: context.size?.longestSide.ceil(),
    );*/

    _sample?.delete();
    _file?.delete();

    setState(() {
      _sample = sample;
      _file = file;
    });
  }

  Future<File?> _cropImage() async {
    final scale = cropKey.currentState?.scale;
    final area = cropKey.currentState?.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return null;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger
    final sample = await ImageCrop.getInstance().sampleImage(
      file: _file,
      preferredSize: (2000 / scale!).round(),
    );

    final file = await ImageCrop.getInstance().cropImage(
      file: sample,
      area: area,
    );

    sample.delete();

    _lastCropped?.delete();
    _lastCropped = file;

    debugPrint('$file');
    return file;
  }
}