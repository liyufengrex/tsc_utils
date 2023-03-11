import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:tsc_utils/src/commands.dart';
import 'package:tsc_utils/src/enums.dart';

class Generator {
  List<int> _byte = [];

  List<int> get byte => _byte;

  // step1
  void addSize({
    required int width,
    required int height,
  }) {
    final size = "SIZE $width mm,$height mm$tscFix".codeUnits;
    _byte += size;
  }

  // step2
  void addGap(int value) {
    final gap = "GAP $value mm,0 mm$tscFix".codeUnits;
    _byte += gap;
  }

  // step3
  void addCls() {
    final cls = "CLS$tscFix".codeUnits;
    _byte += cls;
  }

  // step4
  void addImage(
    Image image,
  ) {
    final int widthPx = image.width;
    final int heightPx = image.height;
    final int widthBytes = (widthPx + 7) ~/ 8;
    final List<int> resterizedData = _toRasterFormat(image);

    final List<int> header = "BITMAP 0,0,$widthBytes,$heightPx,0,".codeUnits;
    _byte += header;
    _byte += resterizedData;
    _byte += tscFix.codeUnits;
  }

  // step5
  void addPrint(int count) {
    final print = "PRINT $count$tscFix".codeUnits;
    _byte += print;
  }

  // 推纸
  void addFeed(int dot) {
    final feed = "FEED $dot$tscFix".codeUnits;
    _byte += feed;
  }

  // 浓度
  void addDensity(Density value) {
    final density = "DENSITY ${value.value}$tscFix".codeUnits;
    _byte += density;
  }

  // 方向
  void addDirection(Direction value) {
    final direction = "DIRECTION ${value.value},0$tscFix".codeUnits;
    _byte += direction;
  }

  // 坐标原点
  void addReference(int x, int y) {
    final value = "REFERENCE $x,$y$tscFix".codeUnits;
    _byte += value;
  }

  List<int> _toRasterFormat(Image imgSrc) {
    Image image = Image.from(imgSrc); // make a copy
    final int widthPx = image.width;
    final int heightPx = image.height;

    // R/G/B channels are same -> keep only one channel
    final List<int> oneChannelBytes = [];
    final List<int> buffer = image.getBytes(format: Format.rgba);
    for (int i = 0; i < buffer.length; i += 4) {
      oneChannelBytes.add(buffer[i]);
    }

    // Add some empty pixels at the end of each line (to make the width divisible by 8)
    if (widthPx % 8 != 0) {
      final targetWidth = (widthPx + 8) - (widthPx % 8);
      final missingPx = targetWidth - widthPx;
      final extra = Uint8List(missingPx);
      for (int i = 0; i < heightPx; i++) {
        final pos = (i * widthPx + widthPx) + i * missingPx;
        oneChannelBytes.insertAll(pos, extra);
      }
    }

    // Pack bits into bytes
    return _packBitsIntoBytes(oneChannelBytes);
  }

  List<int> _packBitsIntoBytes(List<int> bytes) {
    const pxPerLine = 8;
    final List<int> res = <int>[];
    const threshold = 127; // set the greyscale -> b/w threshold here
    for (int i = 0; i < bytes.length; i += pxPerLine) {
      int newVal = 0;
      for (int j = 0; j < pxPerLine; j++) {
        newVal = _transformUint32Bool(
          newVal,
          pxPerLine - j,
          bytes[i + j] > threshold,
        );
      }
      res.add(newVal ~/ 2);
    }
    return res;
  }

  int _transformUint32Bool(int uint32, int shift, bool newValue) {
    return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) |
        ((newValue ? 1 : 0) << shift);
  }
}
