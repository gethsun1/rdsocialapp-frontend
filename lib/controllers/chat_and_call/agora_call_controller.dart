import 'dart:io';
import 'package:foap/controllers/chat_and_call/voip_controller.dart';
import 'package:foap/helper/imports/call_imports.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/helper/imports/dashboard_imports.dart';
import 'package:foap/screens/calling/not_answerd_call.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../helper/permission_utils.dart';
import '../../main.dart';
import '../../manager/socket_manager.dart';
import '../../screens/calling/accept_call.dart';
import '../../screens/settings_menu/settings_controller.dart';
import '../../util/ad_helper.dart';
import '../../util/constant_util.dart';
import '../../util/shared_prefs.dart';
import 'call_history_controller.dart';

class AgoraCallController extends GetxController {
  final UserProfileManager _userProfileManager = Get.find();

  RxInt remoteUserId = 0.obs;

  RtcEngine? engine;

  RxBool isFront = false.obs;
  RxBool reConnectingRemoteView = false.obs;
  RxBool videoPaused = false.obs;

  RxBool mutedAudio = false.obs;
  RxBool mutedVideo = false.obs;
  RxBool switchMainView = false.obs;
  RxBool remoteJoined = false.obs;

  final SettingsController _settingsController = Get.find();

  // int callId = 0;
  final player = AudioPlayer();

  late String localCallId;
  UserModel? opponent;
  Call? activeCall;

  String get _resolvedAgoraAppId {
    final String? key = _settingsController.setting.value?.agoraApiKey?.trim();
    if (key != null && key.isNotEmpty) {
      return key;
    }
    return AppConfigConstants.fallbackAgoraAppId;
  }

  //Initialize All The Setup For Agora Video Call

  void setIncomingCallId(int id) {
    // callId = id;
  }

  void clear() {
    isFront.value = false;
    reConnectingRemoteView.value = false;
    videoPaused.value = false;

    mutedAudio.value = false;
    mutedVideo.value = false;
    switchMainView.value = false;
    remoteJoined.value = false;
  }

  Future<void> makeCallRequest({required Call call}) async {
    opponent = call.opponent;
    localCallId = randomId();

    getIt<SocketManager>().emit(
        SocketConstants.callCreate,
        ({
          CallArgParams.senderId: _userProfileManager.user.value!.id,
          CallArgParams.receiverId: call.opponent.id,
          'receiverId': call.opponent.id,
          CallArgParams.callType: call.callType,
          CallArgParams.localCallId: localCallId,
          // CallArgParams.channelName: channelName
        }));
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readString(dynamic value) => value?.toString() ?? '';

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  UserModel _readCaller(Map<String, dynamic> data) {
    final callerNode = data['callerDetail'] ??
        data['caller'] ??
        data['user'] ??
        data['sender'];
    if (callerNode is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(callerNode));
    }

    final user = UserModel();
    user.id = _readInt(data['callerId'] ??
        data['caller_id'] ??
        data['userId'] ??
        data['created_by']);
    user.userName = _readString(data['callerName'] ??
        data['caller_name'] ??
        data['username'] ??
        data['userName'] ??
        data['name']);
    user.picture = _readString(data['callerImage'] ??
        data['caller_image'] ??
        data['userImageUrl'] ??
        data['image']);
    return user;
  }

  void incomingCallReceived(dynamic response) async {
    final data = _asMap(response);
    if (data.isEmpty) return;

    final caller = _readCaller(data);
    if (caller.id == _userProfileManager.user.value!.id) return;

    final call = Call(
      uuid: _readString(data['uuid'] ?? data['callUuid'] ?? data['call_uuid']),
      callId: _readInt(data['id'] ?? data['callId'] ?? data['call_id']),
      channelName: _readString(
          data['channelName'] ?? data['channel_name'] ?? data['channel']),
      isOutGoing: false,
      token: _readString(
          data['token'] ?? data['agoraToken'] ?? data['agora_token']),
      callType: _readInt(data['callType'] ?? data['call_type']),
      opponent: caller,
    );

    if (call.uuid.isEmpty ||
        call.callId == 0 ||
        call.channelName.isEmpty ||
        call.token.isEmpty ||
        call.callType == 0) {
      debugPrint('[AgoraCallController] Invalid incoming call payload: $data');
      return;
    }

    final voipController = Get.find<VoipController>();
    final didShowSystemCallUi = await voipController.incomingCall(call);
    if (didShowSystemCallUi) return;

    await player.stop();
    await player.setAsset('assets/ringtone.mp3');
    await player.play();

    if (Get.context != null) {
      Get.to(() => AcceptCallScreen(call: call),
          transition: Transition.noTransition);
    }
  }

  Future<void> initializeCalling({
    required Call call,
  }) async {
    activeCall = call;
    await player.stop();
    // logFile.writeAsStringSync('initializeCalling \n', mode: FileMode.append);
    if (_resolvedAgoraAppId.isEmpty) {
      // logFile.writeAsStringSync('initializeCalling agora key empty\n', mode: FileMode.append);
      update();
      return;
    }

    // logFile.writeAsStringSync('initializeCalling  agora key found1\n', mode: FileMode.append);
    Future.delayed(Duration.zero, () async {
      try {
        await _initAgoraRtcEngine(
            callType:
                call.callType == 1 ? AgoraCallType.audio : AgoraCallType.video);

        if (engine == null) {
          debugPrint(
              '[AgoraCallController] Engine init skipped or failed. Call screen will not open.');
          return;
        }

        _addAgoraEventHandlers();
        var configuration = const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 1920, height: 1080),
            orientationMode: OrientationMode.orientationModeAdaptive);

        await engine!.setVideoEncoderConfiguration(configuration);
        await engine!.leaveChannel();

        await engine!.joinChannel(
          token: call.token,
          channelId: call.channelName,
          uid: _userProfileManager.user.value!.id,
          options: const ChannelMediaOptions(),
        );

        if (call.callType == 1) {
          Get.to(() => AudioCallingScreen(call: call),
              transition: Transition.noTransition);
        } else {
          Get.to(() => VideoCallingScreen(call: call),
              transition: Transition.noTransition);
        }
      } catch (e, st) {
        debugPrint('[AgoraCallController] Call initialization failed: $e');
        debugPrint(st.toString());
      }
      update();
    });
  }

  //Initialize Agora RTC Engine
  Future<void> _initAgoraRtcEngine({required AgoraCallType callType}) async {
    // _engine = await RtcEngine.create(_settingsController.setting.value!.agoraApiKey!);
    try {
      engine = createAgoraRtcEngine();

      await engine!.initialize(RtcEngineContext(
        appId: _resolvedAgoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      if (callType == AgoraCallType.video) {
        await engine!.enableVideo();
        await engine!.startPreview();
      }
    } catch (e, st) {
      debugPrint('[AgoraCallController] Agora engine init failed: $e');
      debugPrint(st.toString());
      engine = null;
      rethrow;
    }
  }

  //Switch Camera
  void onToggleCamera() {
    engine!.switchCamera().then((value) {
      isFront.value = !isFront.value;
    }).catchError((err) {});
  }

  void toggleMainView() {
    switchMainView.value = !switchMainView.value;
    update();
  }

  //Audio On / Off
  void onToggleMuteAudio() {
    mutedAudio.value = !mutedAudio.value;
    engine!.muteLocalAudioStream(mutedAudio.value);
  }

  //Video On / Off
  void onToggleMuteVideo() {
    mutedVideo.value = !mutedVideo.value;
    engine!.muteLocalVideoStream(mutedVideo.value);
  }

  //Agora Events Handler To Implement Ui/UX Based On Your Requirements
  void _addAgoraEventHandlers() {
    engine!.registerEventHandler(
      RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("local user ${connection.localUid} joined");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("remote user $remoteUid joined");
            remoteJoined.value = true;
            remoteUserId.value = remoteUid;
            debugPrint('remoteJoined ${remoteJoined.value}');
            update();
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("remote user $remoteUid left channel");

            remoteUserId.value = 0;
            update();
            final call = activeCall;
            if (call != null) {
              receivedEndCallNotification(call);
            }
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint(
                '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason) async {
            if (state == ConnectionStateType.connectionStateConnected) {
              reConnectingRemoteView.value = false;
            } else if (state ==
                ConnectionStateType.connectionStateReconnecting) {
              reConnectingRemoteView.value = true;
            }
          },
          onRemoteVideoStateChanged: (RtcConnection connection,
              int remoteUid,
              RemoteVideoState state,
              RemoteVideoStateReason reason,
              int elapsed) async {}),
    );
  }

  // call
  void callStatusUpdateReceived(dynamic response) {
    final updatedData = _asMap(response);
    if (updatedData.isEmpty) return;

    final VoipController voipController = Get.find();
    int callId = _readInt(
        updatedData['id'] ?? updatedData['callId'] ?? updatedData['call_id']);
    int status = _readInt(updatedData['status']);
    int callerId = _readInt(updatedData['callerId'] ??
        updatedData['caller_id'] ??
        updatedData['userId']);
    int myUserId = _userProfileManager.user.value!.id;
    final call = activeCall ??
        Call(
            uuid: _readString(
                updatedData['uuid'] ?? updatedData['callUuid'] ?? ''),
            channelName: '',
            isOutGoing: myUserId == callerId,
            opponent: opponent ?? UserModel(),
            token: '',
            callType: _readInt(updatedData['callType'] ??
                updatedData['call_type'] ??
                activeCall?.callType),
            callId: callId);

    if (status == 4) {
      player.stop();
      voipController.callConnected(call);
      return;
    }

    if (status == 5) {
      if (Platform.isIOS) {
        voipController.endCallByOpponent(call);
      }
      receivedEndCallNotification(call);
      return;
    }

    if (status == 2 || status == 3) {
      player.stop();
      if (Platform.isIOS) {
        voipController.declinedByOpponent(call);
      }
      if (myUserId == callerId) {
        receivedDeclinedCallNotification(call);
      } else {
        clearCall();
        if (Get.isOverlaysOpen || Get.key.currentState?.canPop() == true) {
          Get.back();
        }
      }
      return;
    }

    final CallHistoryController callHistoryController = CallHistoryController();
    callHistoryController.callDetail(
        callId: callId,
        resultCallback: (result) {
          Call call = Call(
              uuid: updatedData['uuid'],
              channelName: '',
              isOutGoing: myUserId == callerId,
              opponent: myUserId == callerId
                  ? result.receiverDetail
                  : result.callerDetail,
              token: '',
              callType: result.callType,
              callId: updatedData['id']);

          if (status == 5 || status == 2) {
            // always called when action is performed by the opponent
            if (status == 2) {
              if (Platform.isIOS) {
                voipController.declinedByOpponent(call);
              }
              if (myUserId == callerId) {
                //show callback screen only if i am the caller
                receivedDeclinedCallNotification(call);
              }
            } else {
              if (Platform.isIOS) {
                voipController.endCallByOpponent(call);
              }
              receivedEndCallNotification(call);
            }
          } else if (status == 4) {
            player.stop();
          }
        });
  }

  Future<void> outgoingCallConfirmationReceived(
      Map<String, dynamic> updatedData) async {
    final VoipController voipController = Get.find();

    String uuid = updatedData['uuid'];
    int id = updatedData['id'];
    String localCallId = updatedData['localCallId'];
    var agoraToken = updatedData['token'];
    var channelName = updatedData['channelName'];
    int callType = updatedData['callType'];

    Call call = Call(
        uuid: uuid,
        channelName: channelName!,
        isOutGoing: true,
        opponent: opponent!,
        token: agoraToken!,
        callType: callType,
        callId: id);

    if (this.localCallId == localCallId) {
      initializeCalling(call: call);
      if (Platform.isIOS) {
        voipController.outGoingCall(call);
      }
      await player.setAsset('assets/ringtone.mp3');
      player.play();
    }
  }

  void acceptCall({required Call call}) {
    activeCall = call;
    player.stop();
    Get.find<VoipController>().callConnected(call);
    getIt<SocketManager>().emit(SocketConstants.onAcceptCall, {
      'uuid': call.uuid,
      'userId': _userProfileManager.user.value!.id,
      'status': 4,
    });

    remoteUserId.value = call.opponent.id;
    remoteJoined.value = true;
    initializeCalling(
      call: call,
    );
  }

  void initiateAcceptCall({required Call call}) async {
    askForPermissionsForCall(call: call);
  }

  void askForPermissionsForCall({required Call call}) {
    // logFile.writeAsStringSync('askForPermissionsForCall 1\n', mode: FileMode.append);
    PermissionUtils.requestPermission(
        call.callType == 1
            ? [Permission.microphone]
            : [Permission.camera, Permission.microphone],
        isOpenSettings: false, permissionGrant: () async {
      // logFile.writeAsStringSync('permissionGranted 1\n', mode: FileMode.append);
      acceptCall(call: call);
    }, permissionDenied: () {
      declineIncomingCall(call: call);
      AppUtil.showToast(
          message: pleaseAllowAccessToMicrophoneForAudioCallString,
          isSuccess: false);
    }, permissionNotAskAgain: () {
      declineIncomingCall(call: call);
      AppUtil.showToast(
          message: pleaseAllowAccessToMicrophoneForAudioCallString,
          isSuccess: false);
    });
  }

  void clearCall() {
    player.stop();
    activeCall = null;
    engine?.leaveChannel();

    if (remoteJoined.value == true) {
      clear();
    }
    // callId = 0;
    remoteJoined.value = false;
  }

  void receivedDeclinedCallNotification(Call call) async {
    player.stop();
    Get.back();
    Get.to(
        () => NotAnsweredCall(
              call: call,
            ),
        transition: Transition.noTransition);
    update();
  }

  //Use This Method To End Call
  void receivedEndCallNotification(Call call) async {
    clearCall();
    Get.back();

    InterstitialAds().show();

    if (isLaunchedFromCallNotification) {
      Get.offAll(() => const DashboardScreen());
    }
    SharedPrefs().setCallNotificationData(null);
  }

  void onCallEnd(Call call) async {
    final VoipController voipController = Get.find();

    if (remoteJoined.value == true) {
      getIt<SocketManager>().emit(SocketConstants.onCompleteCall, {
        'uuid': call.uuid,
        'userId': _userProfileManager.user.value!.id,
        'status': 5,
        // 'channelName': call.channelName
      });
    } else {
      getIt<SocketManager>().emit(SocketConstants.onRejectCall, {
        'uuid': call.uuid,
        'userId': _userProfileManager.user.value!.id,
        'status': 2
      });
    }
    if (Platform.isIOS) {
      voipController.endCall(call);
    }
    clearCall();
    Get.back();

    if (isLaunchedFromCallNotification) {
      Get.offAll(() => const DashboardScreen());
    }
    SharedPrefs().setCallNotificationData(null);
  }

  void declineIncomingCall({required Call call}) async {
    getIt<SocketManager>().emit(SocketConstants.onRejectCall, {
      'uuid': call.uuid,
      'userId': _userProfileManager.user.value!.id,
      'status': 2
    });

    remoteJoined.value = false;

    if (isLaunchedFromCallNotification) {
      Get.offAll(() => const DashboardScreen());
    }
    SharedPrefs().setCallNotificationData(null);
  }

// void timeOutCall(Call call) async {
//   getIt<SocketManager>().emit(SocketConstants.onNotAnswered, {
//     'uuid': call.uuid,
//     'userId': _userProfileManager.user.value!.id,
//     'status': 3
//   });
//   if (Platform.isIOS) {
//     getIt<VoipController>().endCall(call);
//   }
//   // callId = 0;
//   remoteJoined.value = false;
//   Get.back();
// }
}
