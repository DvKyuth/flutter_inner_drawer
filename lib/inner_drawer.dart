// InnerDrawer is based on Drawer.
// The source code of the Drawer has been re-adapted for Inner Drawer.

// more details:
// https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/material/drawer.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Signature for the callback that's called when a [InnerDrawer] is
/// opened or closed.
typedef InnerDrawerCallback = void Function(bool isOpened);

/// Signature for when a pointer that is in contact with the screen and moves to the right or left
/// values between 1 and 0
typedef InnerDragUpdateCallback = void Function(
    double value, InnerDrawerDirection direction);

/// The possible position of a [InnerDrawer].
enum InnerDrawerDirection {
  start,
  end,
}

/// Animation type of a [InnerDrawer].
enum InnerDrawerAnimation {
  static,
  linear,
  quadratic,
}

//width before initState
const double _kWidth = 400;
const double _kMinFlingVelocity = 365.0;
const double _kEdgeDragWidth = 20.0;
const Duration _kBaseSettleDuration = Duration(milliseconds: 246);

class InnerDrawer extends StatefulWidget {
  const InnerDrawer(
      {GlobalKey key,
      this.leftChild,
      this.rightChild,
      @required this.scaffold,
      this.leftOffset = 0.4,
      this.rightOffset = 0.4,
      this.leftScale = 1,
      this.rightScale = 1,
      this.offset,
      this.scale,
      this.proportionalChildArea = true,
      this.borderRadius = 0,
      this.onTapClose = false,
      this.tapScaffoldEnabled = false,
      this.swipe = true,
      this.duration,
      this.boxShadow,
      this.colorTransition,
      this.leftAnimationType = InnerDrawerAnimation.static,
      this.rightAnimationType = InnerDrawerAnimation.static,
      this.backgroundColor,
      this.innerDrawerCallback,
      this.onDragUpdate})
      : assert(leftChild != null || rightChild != null),
        assert(scaffold != null),
        super(key: key);

  /// Left child
  final Widget leftChild;

  /// Right child
  final Widget rightChild;

  /// A Scaffold is generally used but you are free to use other widgets
  final Widget scaffold;

  /// DEPRECATED:
  /// Use `offset` field. Will be removed in 0.6.0
  ///
  /// Left offset of [InnerDrawer] width; (default 0.4)
  final double leftOffset;

  /// DEPRECATED:
  /// Use `offset` field. Will be removed in 0.6.0
  ///
  /// Right offset of [InnerDrawer] width; default 0.4
  final double rightOffset;

  /// When the [InnerDrawer] is open, it's possible to set the offset of each of the four cardinal directions
  final IDOffset offset;

  /// DEPRECATED:
  /// Use `scale` field. Will be removed in 0.6.0
  ///
  /// When the left [InnerDrawer] is open
  /// Values between 1 and 0. (default 1)
  final double leftScale;

  /// DEPRECATED:
  /// Use `scale` field. Will be removed in 0.6.0
  ///
  /// When the right [InnerDrawer] is open
  /// Values between 1 and 0. (default 1)
  final double rightScale;

  /// When the [InnerDrawer] is open to the left or to the right
  /// values between 1 and 0. (default 1)
  final IDOffset scale;

  /// The proportionalChild Area = true dynamically sets the width based on the selected offset.
  /// On false it leaves the width at 100% of the screen
  final bool proportionalChildArea;

  /// edge radius when opening the scaffold - (defalut 0)
  final double borderRadius;

  /// Closes the open scaffold
  final bool tapScaffoldEnabled;

  /// Closes the open scaffold
  final bool onTapClose;

  /// activate or deactivate the swipe. NOTE: when deactivate, onTap Close is implicitly activated
  final bool swipe;

  /// duration animation controller
  final Duration duration;

  /// BoxShadow of scaffold open
  final List<BoxShadow> boxShadow;

  ///Color of gradient
  final Color colorTransition;

  /// Static or Linear or Quadratic
  final InnerDrawerAnimation leftAnimationType;

  /// Static or Linear or Quadratic
  final InnerDrawerAnimation rightAnimationType;

  /// Color of the main background
  final Color backgroundColor;

  /// Optional callback that is called when a [InnerDrawer] is open or closed.
  final InnerDrawerCallback innerDrawerCallback;

  /// when a pointer that is in contact with the screen and moves to the right or left
  final InnerDragUpdateCallback onDragUpdate;

  @override
  InnerDrawerState createState() => InnerDrawerState();
}

class InnerDrawerState extends State<InnerDrawer>
    with SingleTickerProviderStateMixin {
  ColorTween _color =
      ColorTween(begin: Colors.transparent, end: Colors.black54);

  double _initWidth = _kWidth;
  Orientation _orientation = Orientation.portrait;
  InnerDrawerDirection _position;

  @override
  void initState() {
    _updateWidth();

    _position = widget.leftChild != null
        ? InnerDrawerDirection.start
        : InnerDrawerDirection.end;

    _controller = AnimationController(
        value: 1,
        duration: widget.duration ?? _kBaseSettleDuration,
        vsync: this)
      ..addListener(_animationChanged)
      ..addStatusListener(_animationStatusChanged);
    super.initState();
  }

  @override
  void dispose() {
    _historyEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  void _animationChanged() {
    setState(() {
      // The animation controller's state is our build state, and it changed already.
    });

    if (widget.colorTransition != null)
      _color = ColorTween(
          begin: widget.colorTransition.withOpacity(0.0),
          end: widget.colorTransition);
    else
      _color = ColorTween(begin: Colors.transparent, end: Colors.black54);

    if (widget.onDragUpdate != null && _controller.value < 1) {
      widget.onDragUpdate((1 - _controller.value), _position);
    }
  }

  LocalHistoryEntry _historyEntry;
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  void _ensureHistoryEntry() {
    if (_historyEntry == null) {
      final ModalRoute<dynamic> route = ModalRoute.of(context);
      if (route != null) {
        _historyEntry = LocalHistoryEntry(onRemove: _handleHistoryEntryRemoved);
        route.addLocalHistoryEntry(_historyEntry);
        FocusScope.of(context).setFirstFocus(_focusScopeNode);
      }
    }
  }

  void _animationStatusChanged(AnimationStatus status) {
    final bool opened = _controller.value < 0.5 ? true : false;

    switch (status) {
      case AnimationStatus.reverse:
        break;
      case AnimationStatus.forward:
        break;
      case AnimationStatus.dismissed:
        if (_previouslyOpened != opened) {
          _previouslyOpened = opened;
          if (widget.innerDrawerCallback != null)
            widget.innerDrawerCallback(opened);
        }
        _ensureHistoryEntry();
        break;
      case AnimationStatus.completed:
        if (_previouslyOpened != opened) {
          _previouslyOpened = opened;
          if (widget.innerDrawerCallback != null)
            widget.innerDrawerCallback(opened);
        }
        _historyEntry?.remove();
        _historyEntry = null;
    }
  }

  void _handleHistoryEntryRemoved() {
    _historyEntry = null;
    close();
  }

  AnimationController _controller;

  void _handleDragDown(DragDownDetails details) {
    _controller.stop();
    //_ensureHistoryEntry();
  }

  final GlobalKey _drawerKey = GlobalKey();

  double get _width {
    return _initWidth;
  }

  /// get width of screen after initState
  void _updateWidth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox box = _drawerKey.currentContext?.findRenderObject();
      if (box != null && box.size != null)
        setState(() {
          _initWidth = box.size.width;
        });
    });
  }

  bool _previouslyOpened = false;

  void _move(DragUpdateDetails details) {
    double delta = details.primaryDelta / _width;

    if (delta > 0 && _controller.value == 1 && widget.leftChild != null)
      _position = InnerDrawerDirection.start;
    else if (delta < 0 && _controller.value == 1 && widget.rightChild != null)
      _position = InnerDrawerDirection.end;

    //TEMP
    final double left =
        widget.offset != null ? widget.offset.left : widget.leftOffset;
    final double right =
        widget.offset != null ? widget.offset.right : widget.rightOffset;

    double offset = _position == InnerDrawerDirection.start ? left : right;

    double ee = 1;
    if (offset <= 0.2)
      ee = 1.7;
    else if (offset <= 0.4)
      ee = 1.2;
    else if (offset <= 0.6) ee = 1.05;

    offset = 1 -
        pow(offset / ee,
            1 / 2); //(num.parse(pow(offset/2,1/3).toStringAsFixed(1)));

    switch (_position) {
      case InnerDrawerDirection.end:
        break;
      case InnerDrawerDirection.start:
        delta = -delta;
        break;
    }
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        _controller.value -= delta + (delta * offset);
        break;
      case TextDirection.ltr:
        _controller.value += delta + (delta * offset);
        break;
    }

    final bool opened = _controller.value < 0.5 ? true : false;
    if (opened != _previouslyOpened && widget.innerDrawerCallback != null)
      widget.innerDrawerCallback(opened);
    _previouslyOpened = opened;
  }

  void _settle(DragEndDetails details) {
    if (_controller.isDismissed) return;
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity) {
      double visualVelocity = details.velocity.pixelsPerSecond.dx / _width;

      switch (_position) {
        case InnerDrawerDirection.end:
          break;
        case InnerDrawerDirection.start:
          visualVelocity = -visualVelocity;
          break;
      }
      switch (Directionality.of(context)) {
        case TextDirection.rtl:
          _controller.fling(velocity: -visualVelocity);
          break;
        case TextDirection.ltr:
          _controller.fling(velocity: visualVelocity);
          break;
      }
    } else if (_controller.value < 0.5) {
      open();
    } else {
      close();
    }
  }

  void open({InnerDrawerDirection direction}) {
    if (direction != null) _position = direction;
    _controller.fling(velocity: -1);
  }

  void close({InnerDrawerDirection direction}) {
    if (direction != null) _position = direction;
    _controller.fling(velocity: 1);
  }

  /// Open or Close InnerDrawer
  void toggle({InnerDrawerDirection direction}) {
    if (direction != null) _position = direction;
    if (_previouslyOpened)
      _controller.fling(velocity: 1);
    else
      _controller.fling(velocity: -1);
  }

  final GlobalKey _gestureDetectorKey = GlobalKey();

  /// Outer Alignment
  AlignmentDirectional get _drawerOuterAlignment {
    switch (_position) {
      case InnerDrawerDirection.start:
        return AlignmentDirectional.centerEnd;
      case InnerDrawerDirection.end:
        return AlignmentDirectional.centerStart;
    }
    return null;
  }

  /// Inner Alignment
  AlignmentDirectional get _drawerInnerAlignment {
    switch (_position) {
      case InnerDrawerDirection.start:
        return AlignmentDirectional.centerStart;
      case InnerDrawerDirection.end:
        return AlignmentDirectional.centerEnd;
    }
    return null;
  }

  /// returns the left or right animation type based on InnerDrawerDirection
  InnerDrawerAnimation get _animationType {
    return _position == InnerDrawerDirection.start
        ? widget.leftAnimationType
        : widget.rightAnimationType;
  }

  /// returns the left or right scale based on InnerDrawerDirection
  double get _scaleFactor {
    //TEMP
    final double left =
        widget.scale != null ? widget.scale.left : widget.leftScale;
    final double right =
        widget.scale != null ? widget.scale.right : widget.rightScale;

    return _position == InnerDrawerDirection.start ? left : right;
  }

  /// returns the left or right offset based on InnerDrawerDirection
  double get _offset {
    //TEMP
    final double left =
        widget.offset != null ? widget.offset.left : widget.leftOffset;
    final double right =
        widget.offset != null ? widget.offset.right : widget.rightOffset;

    return _position == InnerDrawerDirection.start ? left : right;
  }

  /// return width with specific offset
  double get _widthWithOffset {
    return (_width / 2) - (_width / 2) * _offset;
  }

  /// return widget with specific animation
  Widget _animatedChild() {
    final Widget container = Container(
      //width: _width - width,
      width: widget.proportionalChildArea ? _width - _widthWithOffset : _width,
      height: MediaQuery.of(context).size.height,
      child: _position == InnerDrawerDirection.start
          ? widget.leftChild
          : widget.rightChild,
    );

    switch (_animationType) {
      case InnerDrawerAnimation.linear:
        return Align(
          alignment: _drawerOuterAlignment,
          widthFactor: 1 - (_controller.value),
          child: container,
        );
      case InnerDrawerAnimation.quadratic:
        return Align(
          alignment: _drawerOuterAlignment,
          widthFactor: 1 - (_controller.value / 2),
          child: container,
        );
      default:
        return container;
    }
  }

  /// Trigger Area
  Widget _trigger(AlignmentDirectional alignment, Widget child) {
    assert(alignment != null);
    final bool drawerIsStart = _position == InnerDrawerDirection.start;
    final EdgeInsets padding = MediaQuery.of(context).padding;
    double dragAreaWidth = drawerIsStart ? padding.left : padding.right;

    if (Directionality.of(context) == TextDirection.rtl)
      dragAreaWidth = drawerIsStart ? padding.right : padding.left;
    dragAreaWidth = max(dragAreaWidth, _kEdgeDragWidth);

    if (_controller.status == AnimationStatus.completed &&
        widget.swipe &&
        child != null)
      return Align(
        alignment: alignment,
        child: Container(color: Colors.transparent, width: dragAreaWidth),
      );
    else
      return null;
  }

  ///Disable the scaffolding tap when the drawer is open
  Widget _invisibleCover() {
    final Container container = Container(
      color: Colors.transparent,
    );
    if (_controller.status == AnimationStatus.dismissed &&
        !widget.tapScaffoldEnabled)
      return BlockSemantics(
        child: GestureDetector(
          // On Android, the back button is used to dismiss a modal.
          excludeFromSemantics: defaultTargetPlatform == TargetPlatform.android,
          onTap: widget.onTapClose || !widget.swipe ? close : null,
          child: Semantics(
            label: MaterialLocalizations.of(context)?.modalBarrierDismissLabel,
            child: container,
          ),
        ),
      );
    return null;
  }

  /// Scaffold
  Widget _scaffold() {
    assert(widget.borderRadius >= 0);

    Widget container = Container(
        key: _drawerKey,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                widget.borderRadius * (1 - _controller.value)),
            boxShadow: widget.boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 5,
                  )
                ]),
        child: widget.borderRadius != 0
            ? ClipRRect(
                borderRadius: BorderRadius.circular(
                    (1 - _controller.value) * widget.borderRadius),
                child: widget.scaffold,
              )
            : widget.scaffold);

    final Widget invC = _invisibleCover();
    if (invC != null)
      container = Stack(
        children: <Widget>[container, invC],
      );

    if (_scaleFactor < 1)
      container = Transform.scale(
        alignment: _drawerInnerAlignment,
        scale: ((1 - _scaleFactor) * _controller.value) + _scaleFactor,
        child: container,
      );

    // Vertical translate
    if (widget.offset != null &&
        (widget.offset.top > 0 || widget.offset.bottom > 0)) {
      final double translateY = MediaQuery.of(context).size.height *
          (widget.offset.top > 0 ? -widget.offset.top : widget.offset.bottom);
      container = Transform.translate(
        offset: Offset(0, translateY * (1 - _controller.value)),
        child: container,
      );
    }

    return container;
  }

  @override
  Widget build(BuildContext context) {
    //assert(debugCheckHasMaterialLocalizations(context));

    /// initialize the correct width
    if (_initWidth == 400 ||
        MediaQuery.of(context).orientation != _orientation) {
      _updateWidth();
      _orientation = MediaQuery.of(context).orientation;
    }

    /// wFactor depends of offset and is used by the second Align that contains the Scaffold
    final double offset = 0.5 - _offset * 0.5;
    final double wFactor = (_controller.value * (1 - offset)) + offset;

    return Container(
      color: widget.backgroundColor ?? Theme.of(context).backgroundColor,
      child: Stack(
        alignment: _drawerInnerAlignment,
        children: <Widget>[
          RepaintBoundary(
            child: _animatedChild(),
          ),
          GestureDetector(
            key: _gestureDetectorKey,
            onTap: () {},
            onHorizontalDragDown: widget.swipe ? _handleDragDown : null,
            onHorizontalDragUpdate: widget.swipe ? _move : null,
            onHorizontalDragEnd: widget.swipe ? _settle : null,
            excludeFromSemantics: true,
            child: RepaintBoundary(
              child: Stack(
                children: <Widget>[
                  ///Gradient
                  Container(
                    width: _controller.value == 0 ||
                            _animationType == InnerDrawerAnimation.linear
                        ? 0
                        : null,
                    color: _color.evaluate(_controller),
                  ),
                  Align(
                    alignment: _drawerOuterAlignment,
                    child: Align(
                        alignment: _drawerInnerAlignment,
                        widthFactor: wFactor,
                        child: RepaintBoundary(
                          child: FocusScope(
                              node: _focusScopeNode, child: widget.scaffold),
                        )),
                  ),

                  ///Trigger
                  _trigger(AlignmentDirectional.centerStart, widget.leftChild),
                  _trigger(AlignmentDirectional.centerEnd, widget.rightChild),
                ].where((a) => a != null).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///An immutable set of offset in each of the four cardinal directions.
class IDOffset {
  const IDOffset.horizontal(
    double horizontal,
  )   : left = horizontal,
        top = 0.0,
        right = horizontal,
        bottom = 0.0;

  const IDOffset.only({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  })  : assert(top >= 0.0 &&
            top <= 1.0 &&
            left >= 0.0 &&
            left <= 1.0 &&
            right >= 0.0 &&
            right <= 1.0 &&
            bottom >= 0.0 &&
            bottom <= 1.0),
        assert(top >= 0.0 && bottom == 0.0 || top == 0.0 && bottom >= 0.0);

  /// The offset from the left.
  final double left;

  /// The offset from the top.
  final double top;

  /// The offset from the right.
  final double right;

  /// The offset from the bottom.
  final double bottom;
}
