import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PanelPdfResult {
  PanelPdfResult({required this.printPdf, required this.guidePdf});
  final Uint8List printPdf;
  final Uint8List guidePdf;
}

class PanelPdfService {
  static Future<PanelPdfResult> build({
    required Uint8List imageBytes,
    required int pageCount,
    required String paper,
    required int overlapMm,
  }) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Não foi possível ler a imagem.');
    final grid = _gridFor(pageCount);
    final cols = grid.$1;
    final rows = grid.$2;
    final printDoc = pw.Document();
    final guideDoc = pw.Document();
    final format = _format(paper);
    final overlapRatioX = overlapMm / (paper == 'A3' ? 297 : paper == 'A5' ? 148 : 210);
    final overlapRatioY = overlapMm / (paper == 'A3' ? 420 : paper == 'A5' ? 210 : 297);

    // Cada folha é um recorte proporcional da arte original. A sobreposição
    // é aplicada na área de recorte para facilitar alinhamento e colagem.
    for (var index = 0; index < pageCount; index++) {
      final row = index ~/ cols;
      final col = index % cols;
      final left = (col / cols * decoded.width).floor();
      final top = (row / rows * decoded.height).floor();
      final right = ((col + 1) / cols * decoded.width).ceil();
      final bottom = ((row + 1) / rows * decoded.height).ceil();

      final extraX = (decoded.width * overlapRatioX / 2).round();
      final extraY = (decoded.height * overlapRatioY / 2).round();
      final x0 = math.max(0, left - extraX);
      final y0 = math.max(0, top - extraY);
      final x1 = math.min(decoded.width, right + extraX);
      final y1 = math.min(decoded.height, bottom + extraY);

      final tile = img.copyCrop(
        decoded,
        x: x0,
        y: y0,
        width: x1 - x0,
        height: y1 - y0,
      );
      final tileBytes = Uint8List.fromList(img.encodePng(tile));
      final memory = pw.MemoryImage(tileBytes);
      final pageNumber = index + 1;
      final rowLabel = String.fromCharCode(65 + row);
      final colLabel = col + 1;

      printDoc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(18),
          build: (_) => pw.Column(
            children: [
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(memory, fit: pw.BoxFit.contain),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UP!IMAGE • PAINEL'),
                  pw.Text('Folha $pageNumber de $pageCount • $rowLabel$colLabel'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    guideDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text('GUIA DE MONTAGEM DO PAINEL',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Organize as folhas na ordem indicada. Comece pela primeira linha e avance da esquerda para a direita.'),
          pw.SizedBox(height: 18),
          pw.Text('MAPA DAS FOLHAS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blue),
            children: List.generate(rows, (r) {
              return pw.TableRow(
                children: List.generate(cols, (c) {
                  final n = r * cols + c + 1;
                  return pw.Container(
                    height: 48,
                    alignment: pw.Alignment.center,
                    color: PdfColors.lightBlue50,
                    child: pw.Text(n <= pageCount ? '$n' : ''),
                  );
                }),
              );
            }),
          ),
          pw.SizedBox(height: 18),
          pw.Text('PASSO A PASSO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: 'Imprima todas as páginas em tamanho real (100%), sem ajustar à página.'),
          pw.Bullet(text: 'Confira a numeração no rodapé de cada folha.'),
          pw.Bullet(text: 'Disponha as folhas no chão ou em uma mesa seguindo o mapa.'),
          pw.Bullet(text: 'Ajuste as áreas de sobreposição e alinhe os desenhos.'),
          pw.Bullet(text: 'Recorte as bordas indicadas, quando necessário, e cole pelo verso com fita adesiva.'),
          pw.Bullet(text: 'Fixe o painel montado na parede.'),
          pw.SizedBox(height: 12),
          pw.Text('Configuração: $pageCount folhas • papel $paper • sobreposição de $overlapMm mm.'),
          pw.Text('A qualidade final depende da resolução e nitidez da imagem de origem.'),
        ],
      ),
    );

    return PanelPdfResult(
      printPdf: await printDoc.save(),
      guidePdf: await guideDoc.save(),
    );
  }

  static (int, int) _gridFor(int pages) {
    switch (pages) {
      case 4: return (2, 2);
      case 6: return (2, 3);
      case 10: return (2, 5);
      case 20: return (4, 5);
      default: throw ArgumentError('Escolha 4, 6, 10 ou 20 páginas.');
    }
  }

  static PdfPageFormat _format(String paper) {
    switch (paper) {
      case 'A3': return PdfPageFormat.a3;
      case 'A5': return PdfPageFormat.a5;
      default: return PdfPageFormat.a4;
    }
  }
}
