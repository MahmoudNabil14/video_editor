import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapioca/tapioca.dart';
import 'package:video_editor/sticker.dart';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as IMG;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent)),
      home: const VideoEditorApp(),
    );
  }
}

class VideoEditorApp extends StatefulWidget {
  const VideoEditorApp({Key? key}) : super(key: key);

  @override
  _VideoEditorAppState createState() => _VideoEditorAppState();
}

class _VideoEditorAppState extends State<VideoEditorApp> {
  final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
  VideoPlayerController? _controller;
  late XFile _video;
  ImagePicker picker = ImagePicker();
  bool showDeleteStickerButton = false;
  String selectedSticker = "";
  var scaffoldKey = GlobalKey<ScaffoldState>();
  static const EventChannel _channel = EventChannel('video_editor_progress');
  late StreamSubscription _streamSubscription;
  Offset stickerPosition = const Offset(100, 100);
  bool _showDeleteButton = false;
  double _stickerScale = 1.0;
  double _stickerRotation = 0.0;
  bool _isDeleteButtonActive = false;
  final List<Widget> stickers = [];
  bool isLoading = false;
  bool videoIsPlaying = false;
  List<String> stickersList = [
    'assets/stickers/sticker1.png',
    'assets/stickers/sticker2.png',
    'assets/stickers/sticker3.png',
    'assets/stickers/sticker4.png',
    'assets/stickers/sticker5.png',
    'assets/stickers/sticker6.png',
    'assets/stickers/sticker7.png',
    'assets/stickers/sticker8.png',
    'assets/stickers/sticker9.png',
    'assets/stickers/sticker10.png',
    'assets/stickers/sticker11.png',
    'assets/stickers/sticker12.png',
    'assets/stickers/tapioca_drink.png',
  ];

  @override
  void initState() {
    super.initState();
    _enableEventReceiver();
  }

  @override
  void dispose() {
    super.dispose();
    _disableEventReceiver();
    if (_controller != null) {
      _controller!.removeListener(() {});
    }
  }

  void _enableEventReceiver() {
    _streamSubscription = _channel.receiveBroadcastStream().listen((dynamic event) {
      setState(() {});
    }, onError: (dynamic error) {}, cancelOnError: true);
  }

  void _disableEventReceiver() {
    _streamSubscription.cancel();
  }

  Future getVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        _controller = VideoPlayerController.file(File(video.path));
        await _controller!.initialize();
        _controller!.addListener(() {
          if (_controller!.value.position.compareTo(_controller!.value.duration) == 0) {
            if (_controller!.value.position.inMicroseconds > 0) {
              setState(() {
                videoIsPlaying = false;
              });
            }
          } else {
            setState(() {
              videoIsPlaying = true;
            });
          }
        });
        setState(() {
          _video = video;
        });
      }
    } catch (error) {
      print(error);
    }
  }

  Future saveVideo() async {
    setState(() {
      isLoading = true;
    });
    var tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}result.mp4';

    //To Save sticker with its scaled size
    final imageBitmap = (await rootBundle.load(selectedSticker)).buffer.asUint8List();
    IMG.Image? img = IMG.decodeImage(imageBitmap);
    IMG.Image resizedSticker = IMG.copyResize(img!, width: 120 * _stickerScale.toInt(), height: 120 * _stickerScale.toInt());
    IMG.Image rotatedSticker = IMG.copyRotate(resizedSticker, angle: _stickerRotation*90);
    Uint8List resizedImg = Uint8List.fromList(IMG.encodePng(rotatedSticker));

    //to save the video
    try {
      //to save sticker on the video
      final tapiocaBalls = [
        TapiocaBall.imageOverlay(resizedImg, stickerPosition.dx.toInt(), stickerPosition.dy.toInt()),
      ];
      final cup = Cup(Content(_video.path), tapiocaBalls);
      cup.suckUp(path).then((_) async {
        setState(() {});
        GallerySaver.saveVideo(path).then((bool? success) {});
        setState(() {
          isLoading = false;
          stickers.removeAt(0);
          _controller = VideoPlayerController.file(File(path));
          _controller!.initialize().then((value) {
            _controller!.play();
          });
        });
      }).catchError((e) {});
    } on PlatformException catch (e) {
        print(e.message);

    }
  }

  // Future saveStickerOnVideo() async {
  //   final inputFile = selectedSticker;
  //   final outputFile = "${(await getTemporaryDirectory()).path}/output.mp4";
  //   await FFmpegKit.execute("-i $inputFile -i assets/sticker.png -filter_complex \"[0:v][1:v]overlay=10:10\" -codec:a copy $outputFile");
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      key: scaffoldKey,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                if (_controller != null)
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        if (_controller!.dataSource.isNotEmpty)
                          Align(
                            alignment: Alignment.center,
                            child: Center(
                              child: InkWell(
                                  onTap: () {
                                    if (videoIsPlaying) {
                                      _controller!.pause();
                                      setState(() {
                                        videoIsPlaying = false;
                                      });
                                    } else {
                                      _controller!.play();
                                      setState(() {
                                        videoIsPlaying = true;
                                      });
                                    }
                                  },
                                  child: Icon(
                                    videoIsPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white70.withOpacity(0.4),
                                    size: 100,
                                  )),
                            ),
                          ),
                        if (stickers.isNotEmpty)
                          stickers[0],
                        if (_showDeleteButton)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(60.0),
                              child: Icon(
                                Icons.delete,
                                size: _isDeleteButtonActive ? 35 : 28,
                                color: _isDeleteButtonActive ? Colors.red : Colors.white70,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      scaffoldKey.currentState!.showBottomSheet((context) {
                                        return Container(
                                          padding: const EdgeInsets.all(10.0),
                                          color: Colors.grey[400]!.withOpacity(0.8),
                                          height: MediaQuery.of(context).size.height / 2,
                                          child: GridView.count(
                                            physics: const BouncingScrollPhysics(),
                                            crossAxisCount: 4,
                                            crossAxisSpacing: 20.0,
                                            mainAxisSpacing: 20.0,
                                            children: stickersList.map((stickerPath) {
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    stickers.add(Sticker(
                                                      stickerPath: stickerPath,
                                                      onDragStart: () {
                                                        if (!_showDeleteButton) {
                                                          setState(() {
                                                            _showDeleteButton = true;
                                                          });
                                                        }
                                                      },
                                                      onDragEnd: (offset) {
                                                        if (_showDeleteButton) {
                                                          setState(() {
                                                            _showDeleteButton = false;
                                                          });
                                                        }
                                                        if (offset.dy > 600) {
                                                          stickers.removeAt(0);
                                                        }
                                                        stickerPosition = offset;
                                                      },
                                                      onDragUpdate: (offset) {
                                                        if (offset.dy > 600) {
                                                          if (!_isDeleteButtonActive) {
                                                            setState(() {
                                                              _isDeleteButtonActive = true;
                                                            });
                                                          } else {
                                                            if (_isDeleteButtonActive) {
                                                              setState(() {
                                                                _isDeleteButtonActive = false;
                                                              });
                                                            }
                                                          }
                                                        }
                                                      },
                                                      onScaleUpdate: (ScaleUpdateDetails details) {
                                                        print(details.rotation);
                                                        if (details.scale > 1 || details.scale < 1) {
                                                          _stickerScale = details.scale;
                                                        }
                                                        _stickerRotation = details.rotation;
                                                      },
                                                    ));
                                                    selectedSticker = stickerPath;
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                child: Image.asset(
                                                  stickerPath,
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Text(
                                        'Add Sticker',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: TextButton(
                                      child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                                      onPressed: () async {
                                        await saveVideo();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: getVideo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
