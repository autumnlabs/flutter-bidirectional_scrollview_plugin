import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BidirectionalScrollViewPlugin extends StatefulWidget {
  BidirectionalScrollViewPlugin({@required this.child,
    this.childWidth,
    this.childHeight,
    this.velocityFactor,
    this.initialOffset,
    this.scrollDirection,
    this.scrollListener,
    this.scrollOverflow = Overflow.clip,
  });

  final Widget child;
  final double childWidth;
  final double childHeight;
  final double velocityFactor;
  final Offset initialOffset;
  final ScrollDirection scrollDirection;
  final ValueChanged<Offset> scrollListener;
  final Overflow scrollOverflow;

  _BidirectionalScrollViewState _state;

  @override
  State<StatefulWidget> createState() {
    if (_state == null) {
      _state = new _BidirectionalScrollViewState(
          child,
          childWidth,
          childHeight,
          velocityFactor,
          initialOffset,
          scrollDirection,
          scrollListener);
    }
    return _state;
  }

  set initialOffset(Offset offset) {
    _state.initOffset = offset;
  }

  // set x and y scroll offset of the overflowed widget
  set offset(Offset offset) {
    _state.offset = offset;
  }

  // x scroll offset of the overflowed widget
  double get x {
    return _state.x;
  }

  // x scroll offset of the overflowed widget
  double get y {
    return _state.y;
  }

  // height of the overflowed widget
  double get height {
    return _state.height;
  }

  // width of the overflowed widget
  double get width {
    return _state.width;
  }

  // height of the container that holds the overflowed widget
  double get containerHeight {
    return _state.containerHeight;
  }

  // width of the container that holds the overflowed widget
  double get containerWidth {
    return _state.containerWidth;
  }
}

class _BidirectionalScrollViewState extends State<BidirectionalScrollViewPlugin>
    with SingleTickerProviderStateMixin {
  final GlobalKey _containerKey = new GlobalKey();
  final GlobalKey _positionedKey = new GlobalKey();
  final GlobalKey _childKey = new GlobalKey();

  Widget _child;
  double _childWidth;
  double _childHeight;
  Offset _initialOffset = new Offset(0.0, 0.0);
  ScrollDirection _scrollDirection = ScrollDirection.both;
  ValueChanged<Offset> _scrollListener;

  double xPos = 0.0;
  double yPos = 0.0;
  double xViewPos = 0.0;
  double yViewPos = 0.0;

  bool _isPanning = false;

  _BidirectionalScrollViewState(Widget child, double childWidth,
      double childHeight, double velocityFactor,
      Offset initialOffset, ScrollDirection scrollDirection,
      ValueChanged<Offset> scrollListener) {
    _child = child;
    _childWidth = childWidth;
    _childHeight = childHeight;

    if (scrollListener != null) {
      _scrollListener = scrollListener;
    }

    if (scrollDirection != null) {
      _scrollDirection = scrollDirection;
    }

    if (initialOffset != null) {
      _initialOffset = initialOffset;
      xViewPos = _initialOffset.dx;
      yViewPos = _initialOffset.dy;
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();
  }

  _afterLayout(_) {
    if (_childWidth != null && _childHeight != null) {
      return;
    }
    final RenderBox renderBox = _childKey.currentContext.findRenderObject();
    setState(() {
      _childWidth = renderBox.size.width;
      _childHeight = renderBox.size.height;
    });
  }

  set initOffset(Offset offset) {
    setState(() {
      _initialOffset = offset;
    });
  }

  set offset(Offset offset) {
    setState(() {
      xViewPos = -offset.dx;
      yViewPos = -offset.dy;
    });
  }

  double get x {
    return -xViewPos;
  }

  double get y {
    return -yViewPos;
  }

  double get height {
    RenderBox renderBox = _positionedKey.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  double get width {
    RenderBox renderBox = _positionedKey.currentContext.findRenderObject();
    return renderBox.size.width;
  }

  double get containerHeight {
    RenderBox containerBox = _containerKey.currentContext.findRenderObject();
    return containerBox.size.height;
  }

  double get containerWidth {
    RenderBox containerBox = _containerKey.currentContext.findRenderObject();
    return containerBox.size.width;
  }

  void _handlePanDown(PointerDownEvent details) {
    // Only pan if right mouse
    if (details.buttons != 2) {
      return;
    }

    final RenderBox referenceBox = context.findRenderObject();
    Offset position = referenceBox.globalToLocal(details.position);
    xPos = position.dx;
    yPos = position.dy;

    setState(() {
      _isPanning = true;
    });
  }

  void _handlePanUpdate(PointerMoveEvent details) {
    if (!_isPanning) {
      return;
    }

    final RenderBox referenceBox = context.findRenderObject();
    Offset position = referenceBox.globalToLocal(details.position);

    double newXPosition = xViewPos + (position.dx - xPos);
    double newYPosition = yViewPos + (position.dy - yPos);

    RenderBox containerBox = _containerKey.currentContext.findRenderObject();
    double containerWidth = containerBox.size.width;
    double containerHeight = containerBox.size.height;


    if (newXPosition > _initialOffset.dx || width < containerWidth) {
      newXPosition = _initialOffset.dx;
    } else if (-newXPosition + containerWidth > width) {
      newXPosition = containerWidth - width;
    }

    if (newYPosition > _initialOffset.dy || height < containerHeight) {
      newYPosition = _initialOffset.dy;
    } else if (-newYPosition + containerHeight > height) {
      newYPosition = containerHeight - height;
    }

    setState(() {
      xViewPos = newXPosition;
      yViewPos = newYPosition;
    });

    xPos = position.dx;
    yPos = position.dy;

    _sendScrollValues();
  }

  void _handlePanEnd(PointerUpEvent event) {
    xPos = xViewPos;
    yPos = yViewPos;

    setState(() {
      _isPanning = false;
    });
  }

  _sendScrollValues() {
    if (_scrollListener != null) {
      _scrollListener(new Offset(-xViewPos, -yViewPos));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollDirection == ScrollDirection.horizontal) {
      yViewPos = _initialOffset.dy;
    }

    if (_scrollDirection == ScrollDirection.vertical) {
      xViewPos = _initialOffset.dx;
    }

    if (_childWidth == null && _childHeight == null) {
      // This is just a workaround to get the width and height of child widget
      return new Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          new Positioned(
              top: 0,
              left: 0,
              child: new Container(
                key: _childKey,
                child: _child,
              ),
          ),
        ],
      );
    }

    return new Listener(
        onPointerDown: _handlePanDown,
        onPointerMove: _handlePanUpdate,
        onPointerUp: _handlePanEnd,
        child: new Container(
            key: _containerKey,
            color: Colors.transparent,
            child: new Stack(
              overflow: widget.scrollOverflow,
              children: <Widget>[
                new Positioned(
                  key: _positionedKey,
                  top: yViewPos,
                  left: xViewPos,
                  width: _childWidth,
                  height: _childHeight,
                  child: new CustomScrollView(
                      physics: new NeverScrollableScrollPhysics(),
                      slivers: [
                        SliverSafeArea(
                          sliver: SliverFillRemaining(
                            child: _child,
                          ),
                        )
                      ],
                  ),
                ),
              ],
            ),
        ),
    );
  }
}

enum ScrollDirection {
  horizontal,
  vertical,
  both
}