import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 260});

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'شعار السيدة رزقي',
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .20),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'app/src/main/assets/file_000000006aec822f86d7646dc1970fb0.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
