// Copyright 2018 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:charts_common/src/common/color.dart' show Color;
import 'package:charts_common/src/common/graphics_factory.dart'
    show GraphicsFactory;
import 'package:charts_common/src/common/line_style.dart' show LineStyle;
import 'package:charts_common/src/common/text_element.dart'
    show TextDirection, TextElement, MaxWidthStrategy;
import 'package:charts_common/src/common/text_measurement.dart'
    show TextMeasurement;
import 'package:charts_common/src/common/text_style.dart' show TextStyle;
import 'package:charts_common/src/common/text_utils.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

/// A fake [GraphicsFactory] that returns [FakeTextStyle] and [FakeTextElement].
class FakeGraphicsFactory extends GraphicsFactory {
  @override
  TextStyle createTextPaint() => FakeTextStyle();

  @override
  TextElement createTextElement(String text) => FakeTextElement(
        text,
        textStyle: FakeTextStyle(),
      );

  @override
  LineStyle createLinePaint() => MockLinePaint();
}

/// Stores [TextStyle] properties for test to verify.
class FakeTextStyle implements TextStyle {
  FakeTextStyle({
    this.color = const Color(r: 0, g: 0, b: 0),
    this.fontSize = 12,
    this.fontFamily = 'Arial',
    this.fontWeight = '12',
    this.lineHeight = 12.0,
  });

  @override
  final Color color;

  @override
  final int fontSize;

  @override
  final String fontFamily;

  @override
  final String fontWeight;

  @override
  final double lineHeight;

  @override
  set color(Color? value) {
    // not implemented
  }

  @override
  set fontFamily(String? fontFamily) {
    // not implemented
  }

  @override
  set fontSize(int? value) {
    // not implemented
  }

  @override
  set fontWeight(String? value) {
    // not implemented
  }

  @override
  set lineHeight(double? value) {
    // not implemented
  }
}

/// Fake [TextElement] which returns text length as [horizontalSliceWidth].
///
/// Font size is returned for [verticalSliceWidth] and [baseline].
class FakeTextElement extends TextElement {
  final String _text;

  @override
  final TextStyle textStyle;

  @override
  final int maxWidth;

  @override
  final MaxWidthStrategy maxWidthStrategy;

  @override
  final TextDirection textDirection;

  FakeTextElement(
    this._text, {
    required this.textStyle,
    this.maxWidth = 9999,
    this.maxWidthStrategy = MaxWidthStrategy.ellipsize,
    this.textDirection = TextDirection.ltr,
  });

  @override
  String get text {
    if (maxWidthStrategy == MaxWidthStrategy.ellipsize) {
      var width = measureTextWidth(_text);
      var ellipsis = '...';
      var ellipsisWidth = measureTextWidth(ellipsis);
      if (width <= maxWidth || width <= ellipsisWidth) {
        return _text;
      } else {
        var len = _text.length;
        var ellipsizedText = _text;
        while (width >= maxWidth - ellipsisWidth && len-- > 0) {
          ellipsizedText = ellipsizedText.substring(0, len);
          width = measureTextWidth(ellipsizedText);
        }
        return ellipsizedText + ellipsis;
      }
    }
    return _text;
  }

  @override
  TextMeasurement get measurement => TextMeasurement(
        horizontalSliceWidth: _text.length.toDouble(),
        verticalSliceWidth: textStyle.fontSize?.toDouble() ?? 0.0,
        baseline: textStyle.fontSize?.toDouble() ?? 0.0,
      );

  double measureTextWidth(String text) => text.length.toDouble();

  @override
  set maxWidth(int? value) {
    // not implemented
  }

  @override
  set maxWidthStrategy(MaxWidthStrategy? maxWidthStrategy) {
    // not implemented
  }

  @override
  set opacity(double? opacity) {
    // not implemented
  }

  @override
  set textDirection(TextDirection direction) {
    // not implemented
  }

  @override
  set textStyle(TextStyle? value) {
    // not implemented
  }
}

class MockLinePaint extends Mock implements LineStyle {}

const _defaultFontSize = 12;
const _defaultLineHeight = 12.0;

void main() {
  late GraphicsFactory graphicsFactory;
  late num maxWidth;
  late num maxHeight;
  late FakeTextStyle textStyle;

  setUpAll(() {
    graphicsFactory = FakeGraphicsFactory();
    maxWidth = 10;
    maxHeight = _defaultLineHeight * 2;
    textStyle = FakeTextStyle()
      ..color = Color.black
      ..fontSize = _defaultFontSize;
  });

  group('tree map', () {
    test(
        'when label can fit in a single line, enable allowLabelOverflow, '
        'disable multiline, return full text', () {
      final textElement = FakeTextElement('text', textStyle: textStyle)
        ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: true, multiline: false);

      expect(textElements, hasLength(1));
      expect(textElements.first.text, 'text');
    });

    test(
        'when label can not fit in a single line, enable allowLabelOverflow, '
        'disable multiline, return ellipsized text', () {
      final textElement =
          FakeTextElement('texttexttexttext', textStyle: textStyle)
            ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: true, multiline: false);

      expect(textElements, hasLength(1));
      expect(textElements.first.text, 'texttexttexttext');
    });

    test(
        'when label can not fit in a single line, enable allowLabelOverflow '
        'and multiline, return two textElements', () {
      final textElement =
          FakeTextElement('texttexttexttext', textStyle: textStyle)
            ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: true, multiline: true);

      expect(textElements, hasLength(2));
      expect(textElements.first.text, 'texttextte');
      expect(textElements.last.text, 'xttext');
    });

    test(
        'when both label and ellpisis can not fit in a single line, disable '
        'allowLabelOverflow and multiline, return empty', () {
      final maxWidth = 2;
      final textElement =
          FakeTextElement('texttexttexttext', textStyle: textStyle)
            ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: false, multiline: false);

      expect(textElements, isEmpty);
    });

    test(
        'when both label and ellpisis can not fit in a single line, disable '
        'allowLabelOverflow but enable multiline, return textElements', () {
      final maxWidth = 2;
      final textElement = FakeTextElement('t ex text', textStyle: textStyle)
        ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: false, multiline: true);

      expect(textElements, hasLength(2));
      expect(textElements.first.text, 't');
      expect(textElements.last.text, 'ex');
    });
  });
}
