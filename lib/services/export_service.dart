import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:cross_file/cross_file.dart';
import '../models/rapport.dart';
import '../models/adherent.dart';

class ExportService {
  static Future<void> exportRapportPDF(Rapport rapport, List<Adherent> adherents) async {
    try {
      // Charger une police avec support Unicode
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();

      final pdf = pw.Document();

      // En-tête
      pdf.addPage(pw.Page(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                  rapport.titre,
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: fontBold)
              ),
            ),
            pw.SizedBox(height: 20),

            // Informations générales
            _buildInfoSection(rapport, font, fontBold),
            pw.SizedBox(height: 20),

            // Statistiques
            _buildStatistiquesSection(rapport, font, fontBold),
            pw.SizedBox(height: 20),

            // Détails selon le type
            if (rapport.type == TypeRapport.cotisations || rapport.type == TypeRapport.adherent)
              ..._buildCotisationsDetails(rapport, adherents, font, fontBold),
            if (rapport.type == TypeRapport.benefices)
              ..._buildBeneficesDetails(rapport, font, fontBold),
            if (rapport.type == TypeRapport.global)
              ..._buildGlobalDetails(rapport, adherents, font, fontBold),
          ],
        ),
      ));

      // Sauvegarder et partager
      final String fileName = '${rapport.titre.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf';
      final Uint8List pdfBytes = await pdf.save();
      final String filePath = await _saveFile(pdfBytes, fileName, 'pdf');
      await _shareFile(filePath, 'application/pdf');
    } catch (e) {
      throw Exception('Erreur lors de l\'exportation PDF: $e');
    }
  }

  static Future<void> exportRapportJSON(Rapport rapport, List<Adherent> adherents) async {
    try {
      final Map<String, dynamic> exportData = {
        'rapport': {
          'id': rapport.id,
          'titre': rapport.titre,
          'type': rapport.type.toString(),
          'periode': rapport.periode.toString(),
          'dateDebut': rapport.dateDebut.toIso8601String(),
          'dateFin': rapport.dateFin.toIso8601String(),
          'dateGeneration': rapport.dateGeneration.toIso8601String(),
          'description': rapport.description,
          'estModifiable': rapport.estModifiable,
        },
        'statistiques': {
          'totalCotisations': rapport.totalCotisations,
          'totalBenefices': rapport.totalBenefices,
          'nombreCotisations': rapport.nombreCotisations,
          'nombreAdherents': rapport.nombreAdherents,
        },
        'details': rapport.donnees,
        'dateExport': DateTime.now().toIso8601String(),
      };

      // Ajouter les noms des adhérents si disponible
      if (rapport.adherentId != null) {
        final adherent = adherents.firstWhere(
              (a) => a.id == rapport.adherentId,
          orElse: () => Adherent(nom: 'Inconnu', prenom: '', telephone: ''),
        );
        exportData['rapport']['adherentNom'] = adherent.nomComplet;
      }

      final String jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final String fileName = '${rapport.titre.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.json';
      final String filePath = await _saveFile(Uint8List.fromList(jsonString.codeUnits), fileName, 'json');
      await _shareFile(filePath, 'application/json');
    } catch (e) {
      throw Exception('Erreur lors de l\'exportation JSON: $e');
    }
  }

  static Future<void> exportRapportCSV(Rapport rapport, List<Adherent> adherents) async {
    try {
      List<List<dynamic>> rows = [];

      // En-tête
      rows.add([
        'Type de rapport',
        'Titre',
        'Période',
        'Date de début',
        'Date de fin',
        'Date de génération',
        'Description',
        'Total cotisations',
        'Total bénéfices',
        'Nombre de cotisations',
        'Nombre d\'adhérents',
      ]);

      // Données principales
      rows.add([
        rapport.typeFormate,
        rapport.titre,
        rapport.periodeFormate,
        DateFormat('dd/MM/yyyy').format(rapport.dateDebut),
        DateFormat('dd/MM/yyyy').format(rapport.dateFin),
        DateFormat('dd/MM/yyyy HH:mm').format(rapport.dateGeneration),
        rapport.description,
        rapport.totalCotisations,
        rapport.totalBenefices,
        rapport.nombreCotisations,
        rapport.nombreAdherents,
      ]);

      // Ligne vide
      rows.add([]);

      // Détails selon le type
      if (rapport.type == TypeRapport.cotisations || rapport.type == TypeRapport.adherent) {
        rows.add(['DÉTAILS DES COTISATIONS']);
        rows.add(['Adhérent', 'Année', 'Montant total', 'Montant payé', 'Reste à payer', 'Pourcentage', 'Statut']);

        for (var detail in rapport.detailsCotisations) {
          rows.add([
            detail['adherentNom'] ?? '',
            detail['annee'] ?? '',
            '${detail['montantTotal'] ?? 0} FCFA',
            '${detail['montantPaye'] ?? 0} FCFA',
            '${detail['resteAPayer'] ?? 0} FCFA',
            '${(detail['pourcentagePaye'] ?? 0).toStringAsFixed(1)}%',
            detail['estSoldee'] == true ? 'Soldée' : 'Non soldée',
          ]);
        }
      }

      if (rapport.type == TypeRapport.benefices) {
        rows.add(['DÉTAILS DES BÉNÉFICES']);
        rows.add(['Année', 'Montant total', 'Date distribution', 'Description', 'Distribué']);

        for (var detail in rapport.detailsBenefices) {
          rows.add([
            detail['annee'] ?? '',
            '${detail['montantTotal'] ?? 0} FCFA',
            detail['dateDistribution'] != null
                ? DateFormat('dd/MM/yyyy').format(DateTime.parse(detail['dateDistribution']))
                : '',
            detail['description'] ?? '',
            detail['estDistribue'] == true ? 'Oui' : 'Non',
          ]);
        }
      }

      // Convertir en CSV
      String csvString = const ListToCsvConverter().convert(rows);

      // Ajouter BOM pour Excel
      const bom = '\uFEFF';
      csvString = bom + csvString;

      final String fileName = '${rapport.titre.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.csv';
      final String filePath = await _saveFile(Uint8List.fromList(csvString.codeUnits), fileName, 'csv');
      await _shareFile(filePath, 'text/csv');
    } catch (e) {
      throw Exception('Erreur lors de l\'exportation CSV: $e');
    }
  }

  static pw.Widget _buildInfoSection(Rapport rapport, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
              'Informations générales',
              style: pw.TextStyle(font: fontBold, fontSize: 14)
          ),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Type: ${rapport.typeFormate}', style: pw.TextStyle(font: font))),
            pw.Expanded(child: pw.Text('Période: ${rapport.periodeFormate}', style: pw.TextStyle(font: font))),
          ]),
          pw.SizedBox(height: 5),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Début: ${DateFormat('dd/MM/yyyy').format(rapport.dateDebut)}', style: pw.TextStyle(font: font))),
            pw.Expanded(child: pw.Text('Fin: ${DateFormat('dd/MM/yyyy').format(rapport.dateFin)}', style: pw.TextStyle(font: font))),
          ]),
          pw.SizedBox(height: 5),
          pw.Text('Généré le: ${DateFormat('dd MMM yyyy à HH:mm').format(rapport.dateGeneration)}', style: pw.TextStyle(font: font)),
          if (rapport.description.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text('Description: ${rapport.description}', style: pw.TextStyle(font: font)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildStatistiquesSection(Rapport rapport, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Statistiques', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          if (rapport.type == TypeRapport.cotisations || rapport.type == TypeRapport.adherent) ...[
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Total cotisations: ${rapport.totalCotisationsFormate}', style: pw.TextStyle(font: font))),
              pw.Expanded(child: pw.Text('Nombre: ${rapport.nombreCotisations}', style: pw.TextStyle(font: font))),
            ]),
          ],
          if (rapport.type == TypeRapport.benefices) ...[
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Total bénéfices: ${rapport.totalBeneficesFormate}', style: pw.TextStyle(font: font))),
              pw.Expanded(child: pw.Text('Nombre: ${rapport.donnees['nombreBenefices'] ?? 0}', style: pw.TextStyle(font: font))),
            ]),
          ],
          if (rapport.type == TypeRapport.global) ...[
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Total cotisations: ${rapport.totalCotisationsFormate}', style: pw.TextStyle(font: font))),
              pw.Expanded(child: pw.Text('Total bénéfices: ${rapport.totalBeneficesFormate}', style: pw.TextStyle(font: font))),
            ]),
            pw.SizedBox(height: 5),
            pw.Row(children: [
              pw.Expanded(child: pw.Text('Solde global: ${(rapport.donnees['solde'] ?? 0).toInt()} FCFA', style: pw.TextStyle(font: font))),
              pw.Expanded(child: pw.Text('Nombre d\'adhérents: ${rapport.nombreAdherents}', style: pw.TextStyle(font: font))),
            ]),
          ],
        ],
      ),
    );
  }

  static List<pw.Widget> _buildCotisationsDetails(Rapport rapport, List<Adherent> adherents, pw.Font font, pw.Font fontBold) {
    return [
      pw.Container(
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Détails des cotisations', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
                4: pw.FlexColumnWidth(1.5),
                5: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(child: pw.Text('Adhérent', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Année', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Payé', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Reste', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('%', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                  ],
                ),
                ...rapport.detailsCotisations.map((detail) => pw.TableRow(
                  children: [
                    pw.Padding(child: pw.Text(detail['adherentNom'] ?? '', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('${detail['annee'] ?? ''}', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('${detail['montantTotal'] ?? 0} FCFA', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('${detail['montantPaye'] ?? 0} FCFA', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('${detail['resteAPayer'] ?? 0} FCFA', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('${(detail['pourcentagePaye'] ?? 0).toStringAsFixed(1)}%', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                  ],
                )).toList(),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildBeneficesDetails(Rapport rapport, pw.Font font, pw.Font fontBold) {
    return [
      pw.Container(
        padding: pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Détails des bénéfices', style: pw.TextStyle(font: fontBold, fontSize: 14)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(child: pw.Text('Année', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Montant', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Date distribution', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('Distribué', style: pw.TextStyle(font: fontBold, fontSize: 10)), padding: pw.EdgeInsets.all(5)),
                  ],
                ),
                ...rapport.detailsBenefices.map((detail) => pw.TableRow(
                  children: [
                    pw.Padding(child: pw.Text('${detail['annee'] ?? ''}', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text('${detail['montantTotal'] ?? 0} FCFA', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text(detail['dateDistribution'] != null
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(detail['dateDistribution']))
                        : '', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                    pw.Padding(child: pw.Text(detail['estDistribue'] == true ? 'Oui' : 'Non', style: pw.TextStyle(font: font, fontSize: 9)), padding: pw.EdgeInsets.all(5)),
                  ],
                )).toList(),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildGlobalDetails(Rapport rapport, List<Adherent> adherents, pw.Font font, pw.Font fontBold) {
    return [
      ..._buildCotisationsDetails(rapport, adherents, font, fontBold),
      pw.SizedBox(height: 20),
      ..._buildBeneficesDetails(rapport, font, fontBold),
    ];
  }

  static Future<String> _saveFile(Uint8List bytes, String fileName, String extension) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> _shareFile(String filePath, String mimeType) async {
    final xFile = XFile(filePath, mimeType: mimeType);
    await Share.shareXFiles([xFile]);
  }
}