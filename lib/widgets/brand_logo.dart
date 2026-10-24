import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 260});
  @override
  Widget build(BuildContext context) => Semantics(
    image: true, label: 'شعار السيدة رزقي',
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: .14), blurRadius: 40, spreadRadius: 3),
      ]),
      child: Image.asset(
        'app/src/main/assets/file_000000006aec822f86d7646dc1970fb0.png',
        fit: BoxFit.contain, filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      ),
    ),
  );
}
