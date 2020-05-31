import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../modal_bottom_sheet.dart';

const Duration _bottomSheetDuration = Duration(milliseconds: 400);

class _ModalBottomSheet<T> extends StatefulWidget {
  const _ModalBottomSheet({
    Key key,
    this.route,
    this.secondAnimationController,
    this.bounce = false,
    this.scrollController,
    this.expanded = false,
    this.enableDrag = true,
    this.animationCurve,
  })  : assert(expanded != null),
        assert(enableDrag != null),
        super(key: key);

  final ModalBottomSheetRoute<T> route;
  final bool expanded;
  final bool bounce;
  final bool enableDrag;
  final AnimationController secondAnimationController;
  final Curve animationCurve;
  final ScrollController scrollController;

  @override
  _ModalBottomSheetState<T> createState() => _ModalBottomSheetState<T>();
}

class _ModalBottomSheetState<T> extends State<_ModalBottomSheet<T>> {
  String _getRouteLabel() {
    final platform = Theme.of(context)?.platform ?? defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.iOS:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        if (Localizations.of(context, MaterialLocalizations) != null) {
          return MaterialLocalizations.of(context).dialogLabel;
        } else {
          return DefaultMaterialLocalizations().dialogLabel;
        }
    }
    return null;
  }

  @override
  void initState() {
    widget.route.animation.addListener(updateController);
    super.initState();
  }

  @override
  void dispose() {
    widget.route.animation.removeListener(updateController);
    super.dispose();
  }

  void updateController() {
    widget.secondAnimationController?.value = widget.route.animation.value;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    return AnimatedBuilder(
      animation: widget.route._animationController,
      builder: (BuildContext context, Widget child) {
        // Disable the initial animation when accessible navigation is on so
        // that the semantics are added to the tree at the correct time.
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: _getRouteLabel(),
          explicitChildNodes: true,
          child: ModalBottomSheet(
            expanded: widget.route.expanded,
            containerBuilder: widget.route.containerBuilder,
            animationController: widget.route._animationController,
            shouldClose: widget.route._hasScopedWillPopCallback
                ? () async {
                    final willPop = await widget.route.willPop();
                    return willPop != RoutePopDisposition.doNotPop;
                  }
                : null,
            onClosing: () {
              if (widget.route.isCurrent) {
                Navigator.of(context).pop();
              }
            },
            builder: widget.route.builder,
            enableDrag: widget.enableDrag,
            bounce: widget.bounce,
            animationCurve: widget.animationCurve,
          ),
        );
      },
    );
  }
}

class ModalBottomSheetRoute<T> extends PopupRoute<T> {
  ModalBottomSheetRoute({
    this.containerBuilder,
    this.builder,
    this.scrollController,
    this.barrierLabel,
    this.secondAnimationController,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    @required this.expanded,
    this.bounce = false,
    this.animationCurve,
    this.duration,
    RouteSettings settings,
  })  : assert(expanded != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(settings: settings);

  final WidgetWithChildBuilder containerBuilder;
  final ScrollWidgetBuilder builder;
  final bool expanded;
  final bool bounce;
  final Color modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final ScrollController scrollController;

  final Duration duration;

  final AnimationController secondAnimationController;
  final Curve animationCurve;

  @override
  Duration get transitionDuration => duration ?? _bottomSheetDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black.withOpacity(0.35);

  AnimationController _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = ModalBottomSheet.createAnimationController(
      navigator.overlay,
      duration: duration,
    );
    return _animationController;
  }

  bool get _hasScopedWillPopCallback => hasScopedWillPopCallback;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      // removeTop: true,
      child: _ModalBottomSheet<T>(
        route: this,
        secondAnimationController: secondAnimationController,
        expanded: expanded,
        scrollController: scrollController,
        bounce: bounce,
        enableDrag: enableDrag,
        animationCurve: animationCurve,
      ),
    );
    return bottomSheet;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is ModalBottomSheetRoute;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) =>
      previousRoute is ModalBottomSheetRoute || previousRoute is PageRoute;

  Widget getPreviousRouteTransition(
    BuildContext context,
    Animation<double> secondAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Shows a modal material design bottom sheet.
Future<T> showCustomModalBottomSheet<T>({
  @required BuildContext context,
  @required ScrollWidgetBuilder builder,
  @required WidgetWithChildBuilder containerWidget,
  Color backgroundColor,
  double elevation,
  ShapeBorder shape,
  Clip clipBehavior,
  Color barrierColor,
  bool bounce = false,
  bool expand = false,
  AnimationController secondAnimation,
  Curve animationCurve,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  ScrollController scrollController,
  Duration duration,
}) async {
  assert(context != null);
  assert(builder != null);
  assert(containerWidget != null);
  assert(expand != null);
  assert(useRootNavigator != null);
  assert(isDismissible != null);
  assert(enableDrag != null);
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));
  final hasMaterialLocalizations =
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations) !=
          null;
  final barrierLabel = hasMaterialLocalizations
      ? MaterialLocalizations.of(context).modalBarrierDismissLabel
      : '';

  final result = await Navigator.of(context, rootNavigator: useRootNavigator)
      .push(ModalBottomSheetRoute<T>(
    builder: builder,
    bounce: bounce,
    containerBuilder: containerWidget,
    secondAnimationController: secondAnimation,
    expanded: expand,
    barrierLabel: barrierLabel,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor,
    enableDrag: enableDrag,
    animationCurve: animationCurve,
    duration: duration,
  ));
  return result;
}
