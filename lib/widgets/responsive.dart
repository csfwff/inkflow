import 'package:flutter/material.dart';

class Responsive {
  static const double wideBreakpoint = 900;
  static const double maxWidth = 1200;

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width > wideBreakpoint;
  }

  /// 在宽屏上约束内容最大宽度并居中
  static Widget constrain({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
