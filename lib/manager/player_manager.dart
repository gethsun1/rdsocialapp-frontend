import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:foap/manager/progress_notifier.dart';

import '../screens/add_on/model/reel_music_model.dart';

class Audio {
  String id;
  String url;

  Audio({
    required this.id,
    required this.url,
  });
}

class PlayerManager extends GetxController {
  final player = AudioPlayer();

  Duration totalDuration = const Duration(seconds: 0);
  Duration currentPosition = const Duration(seconds: 0);

  Rx<Audio?> currentlyPlayingAudio = Rx<Audio?>(null);
  Rx<ProgressBarState?> progress = Rx<ProgressBarState?>(null);
  RxBool isPlaying = false.obs;

  Future<void> playNetworkAudio(Audio audio) async {
    if (currentlyPlayingAudio.value?.id != audio.id) {
      currentlyPlayingAudio.value = audio;
      await player.setUrl(audio.url);

      listenToStates();
    }
    isPlaying.value = true;
    player.play();
  }

  Future<void> playLocalAudio(Audio audio) async {
    if (currentlyPlayingAudio.value?.id != audio.id) {
      currentlyPlayingAudio.value = audio;
      await player.setFilePath(audio.url);
      listenToStates();
    }
    isPlaying.value = true;
    player.play();
  }

  void listenToStates() {
    player.positionStream.listen((event) {
      currentPosition = event;
      progress.value =
          ProgressBarState(current: currentPosition, total: totalDuration);
    });

    player.durationStream.listen((event) {
      totalDuration = event ?? const Duration(seconds: 0);
    });

    player.playerStateStream.listen((state) {
      if (state.playing) {
      } else {}
      switch (state.processingState) {
        case ProcessingState.idle:
          {
            return;
          }
        case ProcessingState.loading:
          return;
        case ProcessingState.buffering:
          return;
        case ProcessingState.ready:
          return;
        case ProcessingState.completed:
          currentlyPlayingAudio.value = null;
          return;
      }
    });
  }

  void stopAudio() {
    player.stop();
    currentlyPlayingAudio.value = null;
    isPlaying.value = false;
  }

  void pauseAudio() {
    player.pause();
    isPlaying.value = false;
  }

  void updateProgress(Duration currentPosition) {
    // progress.value =
    //     ProgressBarState(current: currentPosition, total: totalDuration);
    player.seek(currentPosition);
  }

  Future<void> playAudioFile(File file) async {
    await player.setFilePath(file.path);

    player.play();
    listenToStates();
  }

  Future<void> playAudioFileTimeIntervalBased(
      ReelMusicModel audio, double startTime, double endTime) async {
    await player.setUrl(audio.url);
    await player.setClip(
        start: Duration(seconds: startTime.toInt()),
        end: Duration(seconds: endTime.toInt()));
    player.play();
    listenToStates();
  }
}
