## tsc_utils

标签打印机 *TSC* 数据转换工具，主要用于将 image 图像转换成标签打印机可识别的字节数组。

内部图像处理使用 `image: ^3.0.2` 。

### 使用示例

```dart
tsc_utils: ^0.0.1
```

#### 1. 获取图片数据转 Uint8List
```dart
// 通过文件路径获取图片
static Future<Uint8List> getImage(String imgPath) async {
    final imgFile = File(imgPath);
    final exist = await imgFile.exists();
    if(exist) {
      return imgFile.readAsBytes();
    } else {
      throw Exception('print imgFile is not exist');
    }
  }
```
#### 2. Unit8List 转 tsc 字节数组
```dart
import 'package:image/image.dart' as img;

// unit8List 转 esc 字节数组
static Future<List<int>> decodeBytes(Uint8List imgData) async {
   final img.Image image = await cropImage(
      imgData,
    );
    final origin = image;
    final width = origin.width;
    final height = origin.height;
    img.Image targetImg = origin;
    // 对图像进行缩放处理，保证标签图像的宽能被8整除
    if (width % 8 != 0) {
      targetImg = await ImageDecodeTool.resizeImage(
        origin,
        targetWidth: width ~/ 8 * 8,
        targetHeight: height,
      );
    }
    final targetWidth = targetImg.width;
    final targetHeight = targetImg.height;
    Generator generator = Generator();
    // 设置标签宽高
    generator.addSize(width: targetWidth ~/ 8, height: targetHeight ~/ 8);
    generator.addGap(1);
    // 设置标签浓度
    generator.addDensity(Density.density15);
    // 设置标签方向（正向或倒向）
    generator.addDirection(Direction.backWord);
    generator.addReference(2, 2);
    // 清空图像缓存
    generator.addCls();
    // 加入打印图像
    generator.addImage(targetImg);
    // 设置打印张数
    generator.addPrint(1);
    return generator.byte;
```

### 注意事项

通常 1mm 对应 8个像素，例如打印标签尺寸为 45mm * 70mm，对应的标签图像尺寸应为 360px * 560px 。
