import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SlideLeftRoute extends PageRouteBuilder {

  final Widget widget;
  SlideLeftRoute({
    RouteSettings settings,this.widget})
      : super(
    settings: settings,
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return widget;
      },
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        return FadeTransition(child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ), opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(animation),);
      }
  );
}