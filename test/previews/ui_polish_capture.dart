import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadPolishFonts() async {
  final font = FontLoader('Plus Jakarta Sans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-VariableFont_wght.ttf'));
  await font.load();
  final material = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await material.load();
  final lucide = FontLoader('packages/flutter_lucide/lucide')
    ..addFont(rootBundle.load('packages/flutter_lucide/lib/fonts/lucide.ttf'));
  await lucide.load();
}

Future<void> capturePolish(WidgetTester tester, GlobalKey key, String name) async {
  const directory = String.fromEnvironment('UI_POLISH_CAPTURE');
  if (directory.isEmpty) return;
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
