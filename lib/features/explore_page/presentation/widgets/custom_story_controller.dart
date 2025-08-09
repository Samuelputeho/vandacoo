import 'dart:async';
import 'package:flutter/widgets.dart';

enum StoryState {
  playing,
  paused,
  completed,
}

class CustomStoryController extends ChangeNotifier {
  int _currentIndex = 0;
  StoryState _state = StoryState.paused;
  Timer? _progressTimer;
  double _progress = 0.0;
  final int _totalStories;
  Duration _storyDuration;

  // Real-time progress tracking
  Duration _contentDuration = Duration.zero;
  Duration _contentPosition = Duration.zero;
  bool _useRealTimeProgress = false;

  Timer? _notificationTimer;

  // Callbacks
  VoidCallback? onComplete;
  Function(int index)? onStoryChanged;

  CustomStoryController({
    required int totalStories,
    Duration storyDuration = const Duration(seconds: 60),
    this.onComplete,
    this.onStoryChanged,
  })  : _totalStories = totalStories,
        _storyDuration = storyDuration;

  // Getters
  int get currentIndex => _currentIndex;
  StoryState get state => _state;
  double get progress => _progress;
  int get totalStories => _totalStories;
  bool get isPlaying => _state == StoryState.playing;
  bool get isPaused => _state == StoryState.paused;
  bool get isCompleted => _state == StoryState.completed;

  // Navigation methods
  void next() {
    if (_currentIndex < _totalStories - 1) {
      _currentIndex++;
      _resetProgress();
      onStoryChanged?.call(_currentIndex);
      notifyListeners();
      if (_state == StoryState.playing) {
        _startProgressTimer();
      }
    } else {
      complete();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _resetProgress();
      onStoryChanged?.call(_currentIndex);
      notifyListeners();
      if (_state == StoryState.playing) {
        _startProgressTimer();
      }
    }
  }

  void goToStory(int index) {
    if (index >= 0 && index < _totalStories) {
      _currentIndex = index;
      _resetProgress();
      onStoryChanged?.call(_currentIndex);
      notifyListeners();
      if (_state == StoryState.playing) {
        _startProgressTimer();
      }
    }
  }

  // Playback control methods
  void play() {
    if (_state != StoryState.completed) {
      _state = StoryState.playing;
      // Start timer immediately for auto-progression, content will override if needed
      _startProgressTimer();
      notifyListeners();
    }
  }

  void startProgressWhenReady() {
    if (_state == StoryState.playing) {
      _startProgressTimer();
    }
  }

  void pauseProgressDueToContent() {
    _progressTimer?.cancel();
    // Defer notification to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void resumeProgressFromContent() {
    if (_state == StoryState.playing) {
      _startProgressTimer();
    }
    // Defer notification to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Real-time progress methods
  void updateRealTimeProgress(Duration position, Duration duration) {
    _contentPosition = position;
    _contentDuration = duration;

    // If duration is zero, this indicates non-video content - use timer
    if (duration == Duration.zero) {
      _useRealTimeProgress = false;
      switchToTimerProgress();
      return;
    }

    _useRealTimeProgress = true;

    if (duration.inMilliseconds > 0) {
      _progress = position.inMilliseconds / duration.inMilliseconds;
      _progress = _progress.clamp(0.0, 1.0);

      // Check if we've reached the end
      if (_progress >= 1.0) {
        next();
      } else {
        // Use debounced notification to avoid setState during build
        _scheduleNotification();
      }
    }
  }

  void switchToTimerProgress() {
    _useRealTimeProgress = false;
    if (_state == StoryState.playing) {
      _startProgressTimer();
    }
  }

  void _scheduleNotification() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer(const Duration(milliseconds: 16), () {
      // Only notify if we're still using real-time progress
      if (_useRealTimeProgress) {
        notifyListeners();
      }
    });
  }

  void pause() {
    _state = StoryState.paused;
    _progressTimer?.cancel();
    notifyListeners();
  }

  void restart() {
    _resetProgress();
    // Always start playing when restarting, but don't start timer until content ready
    _state = StoryState.playing;
    notifyListeners();
  }

  void complete() {
    _state = StoryState.completed;
    _progressTimer?.cancel();
    onComplete?.call();
    notifyListeners();
  }

  // Progress management
  void _startProgressTimer() {
    _progressTimer?.cancel();

    // Don't start timer if using real-time progress
    if (_useRealTimeProgress) {
      return;
    }

    const tickDuration = Duration(milliseconds: 50);
    final totalTicks =
        _storyDuration.inMilliseconds / tickDuration.inMilliseconds;
    final progressIncrement = 1.0 / totalTicks;

    _progressTimer = Timer.periodic(tickDuration, (timer) {
      if (_state == StoryState.playing && !_useRealTimeProgress) {
        _progress += progressIncrement;

        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          // Auto-advance to next story
          next();
        } else {
          notifyListeners();
        }
      }
    });
  }

  void _resetProgress() {
    _progress = 0.0;
    _progressTimer?.cancel();
    _notificationTimer?.cancel();
    _useRealTimeProgress = false;
    _contentPosition = Duration.zero;
    _contentDuration = Duration.zero;
  }

  // Duration control
  void setStoryDuration(Duration duration) {
    _storyDuration = duration;
    if (_state == StoryState.playing) {
      _startProgressTimer();
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }
}
