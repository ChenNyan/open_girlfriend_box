import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:open_girlfriend_box/storage.dart';
import 'package:open_girlfriend_box/volcenSign.dart';
import 'package:volc_engine_rtc/volc_engine_rtc.dart';

import 'getRtcToken.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {
    super.initState();
  }



  RTCVideo? _rtcVideo;
  RTCRoom? _rtcRoom;
  late RTCVideoEventHandler _videoHandler;
  late RTCRoomEventHandler _roomHandler;


  RTCViewContext? _localRenderContext;
  RTCViewContext? _firstRemoteRenderContext;
  RTCViewContext? _secondRemoteRenderContext;
  RTCViewContext? _thirdRemoteRenderContext;
  String roomId = "";
  String userId = "";
  String rtcToken = "";
  int nowUserId = 0;
  // Example usage
  String rtcAppId = '';
  String rtcAppKey = '';
  String asrAppId = '';
  String prompt = "";


  final rtcAppIdController = TextEditingController();
  final rtcAppKeyController = TextEditingController();
  final asrAppIdController = TextEditingController();
  final promptController = TextEditingController();

  getToken() async {
    _videoHandler = RTCVideoEventHandler();
    _roomHandler = RTCRoomEventHandler();
    nowUserId = DateTime.now().millisecondsSinceEpoch;
    if(await Storage().hasKey("rtcTokenData")){
      int nowE = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var data = await Storage().getStorage("rtcTokenData");
      print(data);
      print(nowE);
      print("nowE");
      if(data["expireTime"] - nowE <= 60){
        String roomId = 'rtc_${nowUserId}_device';
        String userId = 'rtc_${nowUserId}_device';


        // int now = 1733035134;
        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final token = AccessToken(rtcAppId, rtcAppKey, roomId, userId);
        token.addPrivilege(Privileges.PrivPublishStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.privPublishAudioStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.privPublishDataStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.privPublishVideoStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.PrivSubscribeStream, now + 7200);  // Add privilege with expiration timestamp
        token.expireTime(now + 7200);  // Set the expiration time for the token

        // Serialize and get the token string
        String generatedToken = token.serialize();

        rtcToken = generatedToken;

        await Storage().setStorage("rtcTokenData", {
          "rtcToken": rtcToken,
          "expireTime": now + 7200
        });
      } else {
        String roomID = 'rtc_${nowUserId}_device';
        String userID = 'rtc_${nowUserId}_device';
        roomId = roomID;
        userId = userID;
        rtcToken = data["rtcToken"];
      }
    } else {
      // Example usage
      String roomId = 'rtc_${nowUserId}_device';
      String userId = 'rtc_${nowUserId}_device';

      // int now = 1733035134;
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final token = AccessToken(rtcAppId, rtcAppKey, roomId, userId);
      token.addPrivilege(Privileges.PrivPublishStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.privPublishAudioStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.privPublishDataStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.privPublishVideoStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.PrivSubscribeStream, now + 7200);  // Add privilege with expiration timestamp
      token.expireTime(now + 7200);  // Set the expiration time for the token

      // Serialize and get the token string
      String generatedToken = token.serialize();

      rtcToken = generatedToken;

      await Storage().setStorage("rtcTokenData", {
        "rtcToken": rtcToken,
        "expireTime": now + 7200
      });
    }


    // 验证 Token（可选）

    _initRoomEventHandler();
    _initVideoAndJoinRoom();
  }



  void _initRoomEventHandler() {
    /// 远端主播角色用户加入房间回调。
    _roomHandler.onUserJoined = (UserInfo userInfo, int elapsed) {
      debugPrint('onUserJoined: ${userInfo.uid}');
    };

    /// 远端用户离开房间回调。
    _roomHandler.onUserLeave = (String uid, UserOfflineReason reason) {
      debugPrint('onUserLeave: $uid reason: $reason');
      if (_firstRemoteRenderContext?.uid == uid) {
        setState(() {
          _firstRemoteRenderContext = null;
        });
        _rtcVideo?.removeRemoteVideo(uid: uid, roomId: roomId);
      } else if (_secondRemoteRenderContext?.uid == uid) {
        setState(() {
          _secondRemoteRenderContext = null;
        });
        _rtcVideo?.removeRemoteVideo(uid: uid, roomId: roomId);
      } else if (_thirdRemoteRenderContext?.uid == uid) {
        setState(() {
          _thirdRemoteRenderContext = null;
        });
        _rtcVideo?.removeRemoteVideo(uid: uid, roomId: roomId);
      }
    };
    _roomHandler.onSubtitleMessageReceived = (e){

    };
    _roomHandler.onRoomStateChanged = (r, u, e, f) async {
      print("进房回调$r");
      print("进房回调$u");
      print("进房回调$e");
      print("进房回调$f");
      if(e == -1000){
        await Storage().removeStorage("rtcTokenData");
        // Example usage

        String roomId = 'rtc_${nowUserId}_device';
        String userId = 'rtc_${nowUserId}_device';

        // int now = 1733035134;
        int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final token = AccessToken(rtcAppId, rtcAppKey, roomId, userId);
        token.addPrivilege(Privileges.PrivPublishStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.privPublishAudioStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.privPublishDataStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.privPublishVideoStream, now + 7200);  // Add privilege with expiration timestamp
        token.addPrivilege(Privileges.PrivSubscribeStream, now + 7200);  // Add privilege with expiration timestamp
        token.expireTime(now + 7200);  // Set the expiration time for the token

        // Serialize and get the token string
        String generatedToken = token.serialize();

        rtcToken = generatedToken;

        await Storage().setStorage("rtcTokenData", {
          "rtcToken": rtcToken,
          "expireTime": now + 7200
        });
        await _rtcRoom?.updateToken(rtcToken);
        Timer(Duration(milliseconds: 200), () async {
          await _rtcRoom?.startSubtitle(SubtitleConfig(
              mode: SubtitleMode.recognition
          ));
        });
      } else if(e == 0){
        Timer(Duration(milliseconds: 200), () async {
          await _rtcRoom?.startSubtitle(SubtitleConfig(
              mode: SubtitleMode.recognition
          ));
        });
      }

    };
    _roomHandler.onTokenWillExpire = () async {
      // Example usage

      String roomId = 'rtc_${nowUserId}_device';
      String userId = 'rtc_${nowUserId}_device';

      // int now = 1733035134;
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final token = AccessToken(rtcAppId, rtcAppKey, roomId, userId);
      token.addPrivilege(Privileges.PrivPublishStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.privPublishAudioStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.privPublishDataStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.privPublishVideoStream, now + 7200);  // Add privilege with expiration timestamp
      token.addPrivilege(Privileges.PrivSubscribeStream, now + 7200);  // Add privilege with expiration timestamp
      token.expireTime(now + 7200);  // Set the expiration time for the token

      // Serialize and get the token string
      String generatedToken = token.serialize();

      rtcToken = generatedToken;

      await Storage().setStorage("rtcTokenData", {
        "rtcToken": rtcToken,
        "expireTime": now + 7200
      });
      _rtcRoom?.updateToken(rtcToken);
    };
  }



  void _initVideoAndJoinRoom() async {
    /// 创建引擎
    _rtcVideo = await RTCVideo.createRTCVideo(
        RTCVideoContext(rtcAppId, eventHandler: _videoHandler));

    if (_rtcVideo == null) {
      return;
    }


    /// 开启本地音频采集
    _rtcVideo?.startAudioCapture();

    /// 创建房间
    _rtcRoom = await _rtcVideo?.createRTCRoom(roomId);

    /// 设置房间事件回调处理
    _rtcRoom?.setRTCRoomEventHandler(_roomHandler);

    /// 加入房间
    UserInfo userInfo = UserInfo(uid: userId);
    RoomConfig roomConfig = RoomConfig(
        isAutoPublish: true,
        isAutoSubscribeAudio: true,
        isAutoSubscribeVideo: true);
    var res = await _rtcRoom?.joinRoom(
      token: rtcToken, userInfo: userInfo, roomConfig: roomConfig,);
    print(res);
    print("joinRoom");
    _initVideoEventHandler();
    initBot();

  }


  void _initVideoEventHandler() {
    /// SDK收到第一帧远端视频解码数据后，用户收到此回调。
    _videoHandler.onFirstRemoteVideoFrameDecoded =
        (RemoteStreamKey streamKey, VideoFrameInfo videoFrameInfo) {
      debugPrint('onFirstRemoteVideoFrameDecoded: ${streamKey.uid}');
      String? uid = streamKey.uid;
      if (_firstRemoteRenderContext?.uid == uid ||
          _secondRemoteRenderContext?.uid == uid ||
          _thirdRemoteRenderContext?.uid == uid) {
        return;
      }

      /// 设置远端用户视频渲染视图
      if (_firstRemoteRenderContext == null) {
        setState(() {
          _firstRemoteRenderContext =
              RTCViewContext.remoteContext(roomId: roomId, uid: uid);
        });
      } else if (_secondRemoteRenderContext == null) {
        setState(() {
          _secondRemoteRenderContext =
              RTCViewContext.remoteContext(roomId: roomId, uid: uid);
        });
      } else if (_thirdRemoteRenderContext == null) {
        setState(() {
          _thirdRemoteRenderContext =
              RTCViewContext.remoteContext(roomId: roomId, uid: uid);
        });
      } else {}
    };

    /// 警告回调，详细可以看 {https://pub.dev/documentation/volc_engine_rtc/latest/api_bytertc_common_defines/WarningCode.html}
    _videoHandler.onWarning = (WarningCode code) {
      debugPrint('warningCode: $code');
    };

    /// 错误回调，详细可以看 {https://pub.dev/documentation/volc_engine_rtc/latest/api_bytertc_common_defines/ErrorCode.html}
    _videoHandler.onError = (ErrorCode code) {
      debugPrint('errorCode: $code');
    };
    _videoHandler.onRemoteAudioPropertiesReport = (e, f) async {

    };
    _videoHandler.onLocalAudioPropertiesReport = (e) async {
      if((e[0].audioPropertiesInfo?.linearVolume ?? 0) > 0){

      } else {

      }
    };
  }



  initBot() async {


    List mData = await Storage().getStorage("messages_$nowUserId") ?? [];
    String messageStr = "";


    mData = truncateListFromEnd(mData, 20);
    mData = mData.map((item){
      String role = item["type"] == 2 ? "user" : "assistant";
      String mes = item["info"];
      return "$role: \"$mes\"";
    }).toList();


    Map data = {
      "AppId": rtcAppId,
      "RoomId": roomId,
      "TaskId": userId,
      "Config": {
        "ASRConfig": {
          "Provider": "volcano",
          "VolumeGain": 0.3,
          "ProviderParams": {
            "Mode": "smallmodel",
            "AppId": asrAppId,
            "Cluster": "volcengine_streaming_common"
          }
        },
        "TTSConfig": {
          "IgnoreBracketText": [1,2],
          "Provider": "volcano",
          "ProviderParams": {
            "app": {
              "appid": asrAppId,
              "cluster": "volcano_tts"
            },
            "audio": {
              "voice_type": "ICL_zh_female_huoponvhai_tob",
              "speed_ratio": 1.0,
            }
          }
        },
        "LLMConfig": {
          "Mode": "ArkV3",
          // "EndPointId": offlineUser != "hongling" ? userToData[offlineUser]["ep-h"] : userToData[offlineUser]["bt"],
          // "BotId": "bot-20241206102018-7nnft",
          "SystemMessages": [prompt],
          "EndPointId": "",
          "BotId": "",
          "UserMessages": mData,
          "Temperature": 0.8
        },
        "SubtitleConfig": {
          "DisableRTSSubtitle": false
        },
        "InterruptMode": 0
      },
      "AgentConfig": {
        "TargetUserId": [userId],
        "WelcomeMessage": "你好呀！我是你的陪伴女友！",
        "UserId": "RtcBot$nowUserId"
      }
    };








    print(data);
    print(data["Config"]["LLMConfig"]["EndPointId"]);
    print(data["Config"]["LLMConfig"]["BotId"]);

    await sendRequest('StartVoiceChat', '2024-12-01', jsonEncode(data));
    _rtcVideo?.enableAudioPropertiesReport(AudioPropertiesConfig());

  }

  List<T> truncateListFromEnd<T>(List<T> list, int length) {
    int startIndex = list.length - length;

    // 确保起始索引不会小于0
    startIndex = startIndex.clamp(0, list.length);

    // 如果起始索引为0，则返回整个列表
    if (startIndex == 0) {
      return list;
    } else {
      // 否则，截取从起始索引到列表末尾的子列表
      return list.sublist(startIndex);
    }
  }


  closeCb() async {


    await closeBot();

    /// 销毁房间
    _rtcRoom?.destroy();

    /// 销毁引擎
    _rtcVideo?.destroy();
  }



  closeBot() async {
    Map data = {
      "AppId": rtcAppId,
      "RoomId": roomId,
      "TaskId": userId,
    };
    await sendRequest('StopVoiceChat', '2024-12-01', jsonEncode(data));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("配置项"),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: rtcAppIdController,
                decoration: InputDecoration(
                  labelText: "rtcAppId",
                  hintText: "rtcAppId",
                ),
                onChanged: (e){
                  rtcAppId = e;
                  setState(() {

                  });
                },
              ),
              TextField(
                controller: rtcAppKeyController,
                decoration: InputDecoration(
                  labelText: "rtcAppKey",
                  hintText: "rtcAppKey",
                ),
                onChanged: (e){
                  rtcAppKey = e;
                  setState(() {

                  });
                },
              ),
              TextField(
                controller: asrAppIdController,
                decoration: InputDecoration(
                  labelText: "asrAppId",
                  hintText: "asrAppId",
                ),
                onChanged: (e){
                  asrAppId = e;
                  setState(() {

                  });
                },
              ),
              TextField(
                controller: promptController,
                decoration: InputDecoration(
                  labelText: "asrAppId",
                  hintText: "asrAppId",
                ),
                onChanged: (e){
                  prompt = e;
                  setState(() {

                  });
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            ElevatedButton(
                onPressed: (){
                  getToken();
                },
                child: Text("开始聊天")
            ),
            ElevatedButton(
                onPressed: (){
                  closeCb();
                },
                child: Text("结束聊天")
            ),
          ],
        ),
      ),
    );
  }
}
