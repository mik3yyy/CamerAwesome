import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camerawesome/src/camera_controller.dart'; // Import the CameraController

/// This is the builder for your camera interface
/// Using the [state] you can do anything you need without having to think about the camera flow
/// On app start we are in [PreparingCameraState]
/// Then depending on the initialCaptureMode you set you will be [PhotoCameraState] or [VideoCameraState]
/// Starting a video will push a [VideoRecordingCameraState]
/// Stopping the video will push back the [VideoCameraState]
/// ----
/// If you need to call specific function for a state use the 'when' function.
typedef CameraLayoutBuilder = Widget Function(
  CameraState state,

  /// [previewSize] not clipped
  //PreviewSize previewSize,

  /// [previewRect] size might be different than [previewSize] if it has been
  /// clipped. It is often clipped in 1:1 ratio. Use it to show elements
  /// relative to the preview (inside or outside for instance)
  //Rect previewRect,

  Preview preview,
);

/// Callback when a video or photo has been saved and user click on thumbnail
typedef OnMediaTap = Function(MediaCapture mediaCapture)?;

/// Used to set a permission result callback
typedef OnPermissionsResult = void Function(bool result);

/// Listener for picture or video capture event
typedef OnMediaCaptureEvent = void Function(MediaCapture mediaCapture);

/// Analysis image stream listener
/// The Preview object will help you to convert a point from the preview to the
/// to your screen
typedef OnImageForAnalysis = Future Function(
  AnalysisImage image,
);

/// This is the entry point of the CameraAwesome plugin
/// You can either
/// - build your custom layout
/// or
/// - use our built in interface
/// with the awesome factory
class CameraAwesomeBuilder extends StatefulWidget {
  /// Which sensors you want to use
  final SensorConfig sensorConfig;

  /// check this for more details
  /// https://api.flutter.dev/flutter/painting/BoxFit.html
  // one of fitWidth, fitHeight, contain, cover
  // currently only work for Android, this do nothing on iOS
  final CameraPreviewFit previewFit;

  /// Enable physical button (volume +/-) to take photo or record video
  final bool enablePhysicalButton;

  /// Path builders when taking photos or recording videos
  final SaveConfig? saveConfig;

  /// Called when the preview of the last captured media is tapped
  final OnMediaTap onMediaTap;

  // Widgets
  final Widget? progressIndicator;

  /// UI Builder
  final CameraLayoutBuilder builder;

  final OnImageForAnalysis? onImageForAnalysis;

  /// only for Android
  final AnalysisConfig? imageAnalysisConfig;

  /// Useful for drawing things based on AI Analysis above the CameraPreview for instance
  final CameraLayoutBuilder? previewDecoratorBuilder;

  final OnPreviewTap Function(CameraState)? onPreviewTapBuilder;
  final OnPreviewScale Function(CameraState)? onPreviewScaleBuilder;

  /// Theme of the camera UI, used in the built-in interface.
  ///
  /// You can also use it in your own UI with [AwesomeThemeProvider].
  /// You might need to wrap your UI in a [Builder] to get a [context].
  final AwesomeTheme theme;

  /// Add padding to the preview to adjust where you want to position it.
  /// See also [previewAlignment].
  final EdgeInsets previewPadding;

  /// Set alignment of the preview to adjust its position.
  /// See also [previewPadding].
  final Alignment previewAlignment;

  /// Set it to true to show a Preview of the camera, false if you only want to
  /// do image analysis
  final bool showPreview;

  final PictureInPictureConfigBuilder? pictureInPictureConfigBuilder;

  /// THe default filter to use when the camera is started.
  final AwesomeFilter? defaultFilter;

  /// List of filters to show in the built-in interface.
  /// (default: [awesomePresetFiltersList])
  /// Push null to hide the filter button
  final List<AwesomeFilter>? availableFilters;

  /// Triggered when a photo or video has been saved
  /// You can use it to do whatever you want once a media has been saved
  final OnMediaCaptureEvent? onMediaCaptureEvent;

  final CameraController? controller;

  const CameraAwesomeBuilder._({
    required this.sensorConfig,
    required this.enablePhysicalButton,
    required this.progressIndicator,
    required this.saveConfig,
    required this.onMediaTap,
    required this.builder,
    required this.previewFit,
    required this.defaultFilter,
    this.onImageForAnalysis,
    this.imageAnalysisConfig,
    this.onPreviewTapBuilder,
    this.onPreviewScaleBuilder,
    this.previewDecoratorBuilder,
    required this.theme,
    this.previewPadding = EdgeInsets.zero,
    this.previewAlignment = Alignment.center,
    this.showPreview = true,
    required this.pictureInPictureConfigBuilder,
    this.availableFilters,
    this.onMediaCaptureEvent,
    this.controller, // Initialize the controller
  });
  CameraAwesomeBuilder.awesome({
    SensorConfig? sensorConfig,
    bool enablePhysicalButton = false,
    Widget? progressIndicator,
    required SaveConfig saveConfig,
    Function(MediaCapture)? onMediaTap,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    OnPreviewTap Function(CameraState)? onPreviewTapBuilder,
    OnPreviewScale Function(CameraState)? onPreviewScaleBuilder,
    CameraPreviewFit? previewFit,
    CameraLayoutBuilder? previewDecoratorBuilder,
    AwesomeTheme? theme,
    Widget Function(CameraState state)? topActionsBuilder,
    Widget Function(CameraState state)? bottomActionsBuilder,
    Widget Function(CameraState state)? middleContentBuilder,
    EdgeInsets previewPadding = EdgeInsets.zero,
    Alignment previewAlignment = Alignment.center,
    PictureInPictureConfigBuilder? pictureInPictureConfigBuilder,
    AwesomeFilter? defaultFilter,
    List<AwesomeFilter>? availableFilters,
    OnMediaCaptureEvent? onMediaCaptureEvent,
    CameraController? controller, // Add controller parameter
  }) : this._(
          sensorConfig: sensorConfig ??
              SensorConfig.single(
                sensor: Sensor.position(SensorPosition.back),
              ),
          enablePhysicalButton: enablePhysicalButton,
          progressIndicator: progressIndicator,
          builder: (cameraModeState, preview) {
            return AwesomeCameraLayout(
              state: cameraModeState,
              onMediaTap: onMediaTap,
              topActions: topActionsBuilder?.call(cameraModeState),
              bottomActions: bottomActionsBuilder?.call(cameraModeState),
              middleContent: middleContentBuilder?.call(cameraModeState),
            );
          },
          saveConfig: saveConfig,
          onMediaTap: onMediaTap,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          onPreviewTapBuilder: onPreviewTapBuilder,
          onPreviewScaleBuilder: onPreviewScaleBuilder,
          previewFit: previewFit ?? CameraPreviewFit.cover,
          previewDecoratorBuilder: previewDecoratorBuilder,
          theme: theme ?? AwesomeTheme(),
          previewPadding: previewPadding,
          previewAlignment: previewAlignment,
          pictureInPictureConfigBuilder: pictureInPictureConfigBuilder,
          defaultFilter: defaultFilter,
          availableFilters: availableFilters ?? awesomePresetFiltersList,
          onMediaCaptureEvent: onMediaCaptureEvent,
          controller: controller, // Pass the controller
        );

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetBuilder();
  }
}

class _CameraWidgetBuilder extends State<CameraAwesomeBuilder>
    with WidgetsBindingObserver {
  late CameraContext _cameraContext;
  final _cameraPreviewKey = GlobalKey<AwesomeCameraPreviewState>();
  StreamSubscription<MediaCapture?>? _captureStateListener;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraContext.dispose();
    _captureStateListener?.cancel();
    widget.controller?.dispose(); // Dispose the controller if provided

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CameraAwesomeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      print("CameraAwesomeBuilder: Updating controller.");
      widget.controller!.init(_cameraContext);
    }
  }

  @override
  void didChangeDependencies() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cameraContext //
            .state
            .when(onVideoRecordingMode: (mode) => mode.stopRecording());
        break;
      case AppLifecycleState.hidden:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraContext = CameraContext.create(
      widget.sensorConfig,
      enablePhysicalButton: widget.enablePhysicalButton,
      filter: widget.defaultFilter ?? AwesomeFilter.None,
      initialCaptureMode: widget.saveConfig?.initialCaptureMode ??
          (widget.showPreview
              ? CaptureMode.preview
              : CaptureMode.analysis_only),
      saveConfig: widget.saveConfig,
      onImageForAnalysis: widget.onImageForAnalysis,
      analysisConfig: widget.imageAnalysisConfig,
      exifPreferences: widget.saveConfig?.exifPreferences ??
          ExifPreferences(saveGPSLocation: false),
      availableFilters: widget.availableFilters,
    );

    // Initialize the controller with the CameraContext
    if (widget.controller != null) {
      print("CameraAwesomeBuilder: Initializing CameraController.");
      widget.controller!.init(_cameraContext);
    }

    // Initial CameraState is always PreparingState
    print("CameraAwesomeBuilder: Starting camera preparation.");
    _cameraContext.state.when(onPreparingCamera: (mode) {
      print("CameraAwesomeBuilder: Starting camera.");
      mode.start();
    });

    _captureStateListener = _cameraContext.captureState$.listen((mediaCapture) {
      if (mediaCapture != null) {
        print("CameraAwesomeBuilder: Media captured: $mediaCapture");
        widget.onMediaCaptureEvent?.call(mediaCapture);
      }
    }, onError: (error) {
      print("CameraAwesomeBuilder: Error in captureState: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return AwesomeThemeProvider(
      theme: widget.theme,
      child: StreamBuilder<CameraState>(
        stream: _cameraContext.state$,
        builder: (context, snapshot) {
          if (!snapshot.hasData ||
              snapshot.data!.captureMode == null ||
              snapshot.requireData is PreparingCameraState) {
            return widget.progressIndicator ??
                const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(
                child: !widget.showPreview
                    ? widget.builder(
                        snapshot.requireData,
                        Preview.hidden(),
                      )
                    : AwesomeCameraPreview(
                        key: _cameraPreviewKey,
                        controller: widget.controller, // Pass the controller

                        previewFit: widget.previewFit,
                        state: snapshot.requireData,
                        padding: widget.previewPadding,
                        alignment: widget.previewAlignment,
                        onPreviewTap: widget.onPreviewTapBuilder
                                ?.call(snapshot.requireData) ??
                            OnPreviewTap(
                              onTap: (
                                position,
                                flutterPreviewSize,
                                pixelPreviewSize,
                              ) {
                                snapshot.requireData.when(
                                  onPhotoMode: (photoState) =>
                                      photoState.focusOnPoint(
                                    flutterPosition: position,
                                    pixelPreviewSize: pixelPreviewSize,
                                    flutterPreviewSize: flutterPreviewSize,
                                  ),
                                  onVideoMode: (videoState) =>
                                      videoState.focusOnPoint(
                                    flutterPosition: position,
                                    pixelPreviewSize: pixelPreviewSize,
                                    flutterPreviewSize: flutterPreviewSize,
                                  ),
                                  onVideoRecordingMode: (videoRecState) =>
                                      videoRecState.focusOnPoint(
                                    flutterPosition: position,
                                    pixelPreviewSize: pixelPreviewSize,
                                    flutterPreviewSize: flutterPreviewSize,
                                  ),
                                  onPreviewMode: (previewState) =>
                                      previewState.focusOnPoint(
                                    flutterPosition: position,
                                    pixelPreviewSize: pixelPreviewSize,
                                    flutterPreviewSize: flutterPreviewSize,
                                  ),
                                );
                              },
                            ),
                        onPreviewScale: widget.onPreviewScaleBuilder
                                ?.call(snapshot.requireData) ??
                            OnPreviewScale(
                              onScale: (scale) {
                                snapshot.requireData.sensorConfig
                                    .setZoom(scale);
                              },
                            ),
                        interfaceBuilder: widget.builder,
                        previewDecoratorBuilder: widget.previewDecoratorBuilder,
                        pictureInPictureConfigBuilder:
                            widget.pictureInPictureConfigBuilder,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
