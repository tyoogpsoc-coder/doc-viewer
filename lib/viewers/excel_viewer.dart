import 'dart:math' as math;
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/viewer_screen.dart';

/// 엑셀(.xlsx / .xlsm / .xls) 뷰어.
/// 시트 탭 전환, 확대/축소, 셀을 누르면 전체 값 보기·복사.
class ExcelViewerPage extends StatefulWidget {
  const ExcelViewerPage({super.key, required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;

  @override
  State<ExcelViewerPage> createState() => _ExcelViewerPageState();
}

class _ExcelViewerPageState extends State<ExcelViewerPage> {
  Excel? _excel;
  String? _error;
  List<String> _sheetNames = [];
  int _sheetIndex = 0;
  double _scale = 1.0;

  // 너무 넓은 시트로 화면이 멈추지 않도록 표시 열 수를 제한
  static const _maxCols = 200;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final excel = await Excel.decodeBytesAsync(widget.bytes);
      if (!mounted) return;
      setState(() {
        _excel = excel;
        _sheetNames = excel.tables.keys.toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _zoom(double delta) =>
      setState(() => _scale = (_scale + delta).clamp(0.6, 2.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: '축소',
            icon: const Icon(Icons.zoom_out),
            onPressed: _excel == null ? null : () => _zoom(-0.2),
          ),
          IconButton(
            tooltip: '확대',
            icon: const Icon(Icons.zoom_in),
            onPressed: _excel == null ? null : () => _zoom(0.2),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _sheetNames.length > 1 ? _sheetTabs() : null,
    );
  }

  Widget _buildBody() {
    if (_error != null) return ViewerError(message: _error!);
    if (_excel == null) return const Center(child: CircularProgressIndicator());
    if (_sheetNames.isEmpty) return const Center(child: Text('시트가 없습니다.'));

    final sheet = _excel!.tables[_sheetNames[_sheetIndex]]!;
    final rows = sheet.rows;
    if (rows.isEmpty) return const Center(child: Text('빈 시트입니다.'));

    final colCount = math.min(
      math.max(sheet.maxColumns, rows.fold<int>(0, (m, r) => math.max(m, r.length))),
      _maxCols,
    );
    return _SheetGrid(
      key: ValueKey(_sheetIndex),
      rows: rows,
      colCount: colCount,
      scale: _scale,
      truncated: sheet.maxColumns > _maxCols,
    );
  }

  Widget _sheetTabs() {
    return SafeArea(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: _sheetNames.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ChoiceChip(
            label: Text(_sheetNames[i]),
            selected: i == _sheetIndex,
            onSelected: (_) => setState(() => _sheetIndex = i),
          ),
        ),
      ),
    );
  }
}

class _SheetGrid extends StatelessWidget {
  const _SheetGrid({
    super.key,
    required this.rows,
    required this.colCount,
    required this.scale,
    required this.truncated,
  });

  final List<List<Data?>> rows;
  final int colCount;
  final double scale;
  final bool truncated;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cellW = 110.0 * scale;
    final cellH = 34.0 * scale;
    final headW = 48.0 * scale;
    final fontSize = 13.0 * scale;
    final border = BorderSide(color: cs.outlineVariant, width: 0.5);
    final headerColor = cs.surfaceContainerHighest;

    Widget headerCell(String text, double w) => Container(
          width: w,
          height: cellH,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: headerColor,
            border: Border(right: border, bottom: border),
          ),
          child: Text(text,
              style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.w600)),
        );

    final totalW = headW + cellW * colCount;

    return Column(
      children: [
        if (truncated)
          MaterialBanner(
            content: Text('열이 너무 많아 앞의 $colCount개 열만 표시합니다.'),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              child: Column(
                children: [
                  // 열 머리글 A, B, C ...
                  Row(children: [
                    headerCell('', headW),
                    for (var c = 0; c < colCount; c++) headerCell(colName(c), cellW),
                  ]),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemExtent: cellH,
                      itemBuilder: (context, r) {
                        final row = rows[r];
                        return Row(children: [
                          headerCell('${r + 1}', headW),
                          for (var c = 0; c < colCount; c++)
                            _cell(context, c < row.length ? row[c] : null, r, c,
                                cellW, cellH, fontSize, border),
                        ]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, Data? data, int r, int c, double w, double h,
      double fontSize, BorderSide border) {
    final v = data?.value;
    final text = formatCell(v);
    final isNumber = v is IntCellValue || v is DoubleCellValue;
    return InkWell(
      onTap: text.isEmpty ? null : () => _showCell(context, '${colName(c)}${r + 1}', v, text),
      child: Container(
        width: w,
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: isNumber ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(border: Border(right: border, bottom: border)),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }

  void _showCell(BuildContext context, String address, CellValue? v, String text) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address, style: Theme.of(ctx).textTheme.titleMedium),
            if (v is FormulaCellValue) ...[
              const SizedBox(height: 4),
              Text('수식: =${v.formula}',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
            ],
            const SizedBox(height: 12),
            SelectableText(text, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('복사'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 0 → A, 25 → Z, 26 → AA ...
String colName(int index) {
  var n = index + 1;
  var s = '';
  while (n > 0) {
    final m = (n - 1) % 26;
    s = String.fromCharCode(65 + m) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

/// 셀 값을 화면용 문자열로
String formatCell(CellValue? v) {
  if (v == null) return '';
  if (v is DoubleCellValue) {
    final d = v.value;
    if (d == d.roundToDouble() && d.abs() < 1e15) return d.toInt().toString();
    return d.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  if (v is IntCellValue) return v.value.toString();
  if (v is BoolCellValue) return v.value ? 'TRUE' : 'FALSE';
  if (v is DateCellValue) {
    return '${v.year}-${_two(v.month)}-${_two(v.day)}';
  }
  if (v is DateTimeCellValue) {
    return '${v.year}-${_two(v.month)}-${_two(v.day)} ${_two(v.hour)}:${_two(v.minute)}';
  }
  if (v is TimeCellValue) return '${_two(v.hour)}:${_two(v.minute)}:${_two(v.second)}';
  if (v is FormulaCellValue) return '=${v.formula}';
  return v.toString();
}

String _two(int n) => n.toString().padLeft(2, '0');
