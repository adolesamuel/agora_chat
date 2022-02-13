// ignore_for_file: unnecessary_null_comparison

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraApp extends StatefulWidget {
  const AgoraApp({Key? key}) : super(key: key);

  @override
  _AgoraAppState createState() => _AgoraAppState();
}

class _AgoraAppState extends State<AgoraApp> {
  final appId = '53f70c1b0eb54e53b74bbca0545cc1d3';

  late RtcEngine rtcEngine;

  bool _localUserJoined = false;

  late int? _remoteUid;

  bool _showStats = true;

  late RtcStats _stats;

  final String token =
      '00653f70c1b0eb54e53b74bbca0545cc1d3IAAEkjUOrYvMzUjTNmD3kf34nQ+/2uouP+Kj6VJ7DXECe4ZTyUcAAAAAEACdNB6VHJYKYgEAAQAblgpi';

  @override
  void initState() {
    super.initState();
    initForAgora();
  }

  void initForAgora() async {
//Ensure valid permissions exist
    await [Permission.microphone, Permission.camera].request();

    //initialize engine
    rtcEngine = await RtcEngine.create(appId);

    rtcEngine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        print('$uid successfully joined channel: $channel');

        setState(() {
          _localUserJoined = true;
        });
      },
      userJoined: (int uid, int elapsed) {
        print('remote user $uid joined channel');

        setState(() {
          _remoteUid = uid;
        });
      },
      userOffline: (int uid, UserOfflineReason reason) {
        print('remote user $uid left channel');
        setState(() {
          _remoteUid = null;
        });
      },
      rtcStats: (stats) {
        //updates every two seconds
        if (_showStats) {
          _stats = stats;
          setState(() {});
        }
      },
    ));

    await rtcEngine.enableVideo();
    await rtcEngine.joinChannel(token, 'firstchannel', null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora App')),
      body: Stack(
        children: [
          Center(
            child: _renderRemoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Center(child: _renderLocalPreview()),
            ),
          )
        ],
      ),
      floatingActionButton: _showStats
          ? _statsView()
          : ElevatedButton(
              onPressed: () {
                setState(() {
                  _showStats = !_showStats;
                });
              },
              child: const Text('Show stats')),
    );
  }

  Widget _statsView() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: _stats.cpuAppUsage == null
          ? const CircularProgressIndicator()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("CPU Usage: " + _stats.cpuAppUsage.toString()),
                Text("Duration (seconds): " + _stats.duration.toString()),
                Text("People on call: " + _stats.userCount.toString()),
                ElevatedButton(
                  onPressed: () {
                    _showStats = false;
                    // _stats.cpuAppUsage = null;
                    setState(() {});
                  },
                  child: const Text("Close"),
                )
              ],
            ),
    );
  }

  // current user video
  Widget _renderLocalPreview() {
    if (_localUserJoined) {
      return RtcLocalView.SurfaceView();
    } else {
      return const Text(
        'Please join channel first',
        textAlign: TextAlign.center,
      );
    }
  }

  // remote user video
  Widget _renderRemoteVideo() {
    if (_remoteUid != null) {
      return RtcRemoteView.SurfaceView(uid: _remoteUid!);
    } else {
      return const Text(
        'Please wait remote user join',
        textAlign: TextAlign.center,
      );
    }
  }
}
