import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final internetSpeedTest = FlutterInternetSpeedTest()..enableLog();

  bool _testInProgress = false;
  double _speed = 0;
  String _progress = '0';
  int _completionTime = 0;
  bool _isServerSelectionInProgress = false;

  String? _ip;

  String _unitText = 'Mbps';

  double _downloadRate = 0;
  double _uploadRate = 0;

  bool _calculatingDownload = true; // Added variable to track download/upload phase

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Speed Test'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Speed Test',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    height: 200,
                    width: 200,
                    child: SfRadialGauge(
                      axes: <RadialAxis>[
                        RadialAxis(
                          minimum: 0,
                          maximum: 100,
                          showLabels: true,
                          showTicks: true,
                          axisLineStyle: AxisLineStyle(
                            thickness: 0.2,
                            cornerStyle: CornerStyle.bothCurve,
                            color: Colors.blue,
                            thicknessUnit: GaugeSizeUnit.factor,
                          ),
                          pointers: <GaugePointer>[
                            RangePointer(
                              value: _speed,
                              width: 0.2,
                              sizeUnit: GaugeSizeUnit.factor,
                              cornerStyle: CornerStyle.bothCurve,
                              color: Colors.green,
                              enableAnimation: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _calculatingDownload
                        ? 'Calculating Download Rate...'
                        : 'Calculating Upload Rate...',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Progress: $_progress%'),
                  if (_completionTime > 0)
                    Text(
                        'Time taken: ${(_completionTime / 1000).toStringAsFixed(2)} sec(s)'),
                ],
              ),
              const SizedBox(
                height: 32.0,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_isServerSelectionInProgress
                    ? 'Selecting Server...'
                    : 'IP: ${_ip ?? '--'} '),
              ),
              Text(
                'Download Rate: $_downloadRate $_unitText', // Show download rate
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Upload Rate: $_uploadRate $_unitText', // Show upload rate
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 32.0,
              ),
              if (!_testInProgress) ...{
                ElevatedButton(
                  child: const Text('Start Testing'),
                  onPressed: () async {
                    reset();
                    await internetSpeedTest.startTesting(onStarted: () {
                      setState(() => _testInProgress = true);
                    }, onCompleted: (TestResult download, TestResult upload) {
                      if (kDebugMode) {
                        print(
                            'the transfer rate ${download.transferRate}, ${upload.transferRate}');
                      }
                      setState(() {
                        _speed = download.transferRate;
                        _unitText =
                        download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                        _downloadRate = _speed;
                        _calculatingDownload = false; // Switch to upload phase
                      });
                      setState(() {
                        _speed = upload.transferRate;
                        _unitText =
                        upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                        _uploadRate = _speed;
                        _testInProgress = false;
                      });
                    }, onProgress: (double percent, TestResult data) {
                      if (kDebugMode) {
                        print(
                            'the transfer rate $data.transferRate, the percent $percent');
                      }
                      setState(() {
                        _unitText =
                        data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                        _speed = data.transferRate;
                        _progress = percent.toStringAsFixed(2);
                      });
                    }, onError: (String errorMessage, String speedTestError) {
                      if (kDebugMode) {
                        print(
                            'the errorMessage $errorMessage, the speedTestError $speedTestError');
                      }
                      reset();
                    }, onDefaultServerSelectionInProgress: () {
                      setState(() {
                        _isServerSelectionInProgress = true;
                      });
                    }, onDefaultServerSelectionDone: (Client? client) {
                      setState(() {
                        _isServerSelectionInProgress = false;
                        _ip = client?.ip;
                      });
                    }, onDownloadComplete: (TestResult data) {
                      setState(() {
                        _speed = data.transferRate;
                        _unitText =
                        data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                        _downloadRate = _speed;
                        _completionTime = data.durationInMillis;
                      });
                    }, onUploadComplete: (TestResult data) {
                      setState(() {
                        _speed = data.transferRate;
                        _unitText =
                        data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
                        _uploadRate = _speed;
                        _completionTime = data.durationInMillis;
                      });
                    }, onCancel: () {
                      reset();
                    });
                  },
                )
              } else ...{
                const CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    onPressed: () => internetSpeedTest.cancelTest(),
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Cancel'),
                  ),
                )
              },
              const SizedBox(
                height: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void reset() {
    setState(() {
      {
        _testInProgress = false;
        _speed = 0;
        _progress = '0';
        _unitText = 'Mbps';
        _completionTime = 0;
        _downloadRate = 0;
        _uploadRate = 0;
        _calculatingDownload = true; // Reset to download phase
        _ip = null;
      }
    });
  }
}
