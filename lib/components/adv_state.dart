import 'dart:ui';

import 'package:adv_image_picker/adv_image_picker.dart';
import 'package:flutter/material.dart';

abstract class AdvState<T extends StatefulWidget> extends State<T> {
  bool _firstRun = true;
  bool _withLoading = true;
  LoadingController _controller = LoadingController();
  bool _isLoading = false;

  bool get isPacked => true;

  @override
  Widget build(BuildContext context) {
    if (_firstRun) {
      initStateWithContext(context);
      _firstRun = false;
    }

    return WillPopScope(
      onWillPop: () async {
        return !_isLoading;
      },
      child: OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          Widget child = orientation == Orientation.portrait
              ? buildView(context)
              : buildViewLandscape(context);

          return child;
        },
      ),
    );
  }

  void initStateWithContext(BuildContext context) {}

  Widget buildView(BuildContext context);

  Widget buildViewLandscape(BuildContext context) {
    return buildView(context);
  }

  void refresh() {
    if (this.mounted) setState(() {});
  }

  Future<dynamic> process(Function f) async {
    _isLoading = true;
    OverlayEntry x = _withLoading ? _showLoading() : null;

    var result = await f();

    if (_controller.refresh != null) await _controller.refresh();
    _isLoading = false;
    x?.remove();

    return result;
  }

  OverlayEntry _showLoading() {
    OverlayEntry toastOverlay = _createLoadingOverlay();

    OverlayState overlay = Overlay.of(context);

    if (overlay == null) return null;
    overlay.insert(toastOverlay);

    return toastOverlay;
  }

  OverlayEntry _createLoadingOverlay() {
    return OverlayEntry(
      builder: (context) => FullLoading(
        true,
        Colors.white.withOpacity(0.3),
        64.0,
        64.0,
        _controller,
      ),
    );
  }
}

typedef Future<void> RefreshLoading();

class LoadingController {
  RefreshLoading refresh;
}

class FullLoading extends StatefulWidget {
  final bool visible;
  final Color barrierColor;
  final double width;
  final double height;
  final LoadingController controller;

  FullLoading(this.visible, this.barrierColor, this.width, this.height,
      this.controller);

  @override
  State<StatefulWidget> createState() => FullLoadingState();
}

class FullLoadingState extends State<FullLoading>
    with TickerProviderStateMixin {
  AnimationController opacityController;

  @override
  void initState() {
    super.initState();
    if (!this.mounted) return;

    widget.controller.refresh = () async {
      if (!opacityController.isDismissed)
        await opacityController.reverse(from: 1.0);
    };

    opacityController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);

    opacityController.addListener(() {
      if (this.mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    opacityController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!opacityController.isAnimating) {
        if (widget.visible && opacityController.value == 0.0)
          opacityController.forward(from: 0.0);
      }
    });

    return Visibility(
      visible: opacityController.value > 0.0,
      child: Positioned.fill(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
              child: Opacity(
                  opacity: opacityController.value,
                  child: Container(
                      color: widget.barrierColor,
                      child: Center(
                          child: Image.asset(
                        AdvImagePicker.loadingAssetName,
                        height: widget.height,
                        width: widget.width,
                      )))))),
    );
  }
}

//class _BarrierRoute<T> extends PageRoute<T> {
//  _BarrierRoute({
//    @required this.tutorial,
//    this.maintainState = true,
//    this.transitionDuration = const Duration(milliseconds: 60),
//    RouteSettings settings,
//  }) : super(settings: settings);
//
//  final Tutorial tutorial;
//
//  @override
//  final bool maintainState;
//
//  @override
//  final Duration transitionDuration;
//
//  @override
//  Widget buildPage(BuildContext context, Animation<double> animation,
//      Animation<double> secondaryAnimation) {
//    return Material(
//      type: MaterialType.transparency,
//      child: GestureDetector(
//        behavior: HitTestBehavior.opaque,
//        onTapDown: (d) {
//          if (tutorial.allShown) Navigator.pop(context);
//        },
//        child: Center(),
//      ),
//    );
//  }
//
//  @override
//  bool get opaque => false;
//
//  @override
//  Color get barrierColor => null;
//
//  @override
//  String get barrierLabel => null;
//}
