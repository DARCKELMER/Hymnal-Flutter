import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Color más vivo que además ocupa una parte apreciable de una imagen, con
/// la misma lógica que usa Material You para elegir el color de un fondo de
/// pantalla (cuantización Celebi + puntaje por croma y presencia).
///
/// Devuelve `null` si la imagen no se puede leer.
Future<Color?> vividColorFromImage(
  ImageProvider provider, {
  int sampleWidth = 96,
}) async {
  final image = await _resolve(ResizeImage(provider, width: sampleWidth));
  if (image == null) return null;
  try {
    return await vividColorFromUiImage(image);
  } finally {
    image.dispose();
  }
}

/// Igual que [vividColorFromImage] para una imagen ya decodificada.
Future<Color?> vividColorFromUiImage(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;
  final pixels = <int>[];
  for (var i = 0; i + 3 < data.lengthInBytes; i += 4) {
    final a = data.getUint8(i + 3);
    if (a < 255) continue; // ignora píxeles transparentes
    final r = data.getUint8(i);
    final g = data.getUint8(i + 1);
    final b = data.getUint8(i + 2);
    pixels.add(0xFF000000 | (r << 16) | (g << 8) | b);
  }
  if (pixels.isEmpty) return null;
  final quantized = await QuantizerCelebi().quantize(pixels, 128);
  final best = Score.score(quantized.colorToCount, desired: 1).first;
  return Color(best);
}

/// Ajusta [color] para una gota de cristal con ícono blanco encima: tono
/// medio (contraste con el blanco) y croma suficiente para que se note
/// sobre el cristal, conservando el matiz.
Color dropColorFrom(Color color) {
  final hct = Hct.fromInt(color.toARGB32());
  final tuned = Hct.from(hct.hue, math.max(hct.chroma, 48), 52);
  return Color(tuned.toInt());
}

Future<ui.Image?> _resolve(ImageProvider provider) {
  final completer = Completer<ui.Image?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      completer.complete(info.image.clone());
      info.dispose();
    },
    onError: (_, _) {
      stream.removeListener(listener);
      completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}
