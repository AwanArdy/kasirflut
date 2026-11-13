import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/shift_model.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';

Future<void> showOpenShiftDialog(BuildContext context) async {
  final cashController = TextEditingController(text: '200000');
  final notesController = TextEditingController();
  String shiftName = DateTime.now().hour < 15 ? 'morning' : 'evening';

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Buka Shift Kasir'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Shift', style: AppTypography.labelMd),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'morning', label: Text('Pagi')),
                      ButtonSegment(value: 'evening', label: Text('Sore / Malam')),
                    ],
                    selected: {shiftName},
                    onSelectionChanged: (val) {
                      setState(() => shiftName = val.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Modal Kas Awal (IDR)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final cash = int.tryParse(
                          cashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                      0;
                  Navigator.pop(dialogCtx);
                  context.read<ShiftCubit>().openShift(
                        startingCashIdr: cash,
                        shiftName: shiftName,
                        notes: notesController.text.trim(),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Buka Shift'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> showCloseShiftDialog(
    BuildContext context, ShiftModel activeShift) async {
  final cashController =
      TextEditingController(text: activeShift.expectedCashIdr.toString());
  final notesController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final actualCash = int.tryParse(
                  cashController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
          final diff = actualCash - activeShift.expectedCashIdr;

          return AlertDialog(
            title: const Text('Tutup Shift Kasir'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow('Modal Awal', formatRupiah(activeShift.startingCashIdr)),
                  _summaryRow('Penjualan Tunai', formatRupiah(activeShift.cashSalesIdr)),
                  _summaryRow('Penjualan QRIS', formatRupiah(activeShift.qrisSalesIdr)),
                  const Divider(),
                  _summaryRow(
                    'Ekspektasi Uang Laci',
                    formatRupiah(activeShift.expectedCashIdr),
                    bold: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Uang Fisik Aktual di Laci (IDR)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diff == 0
                        ? 'Status: Balance (Sesuai)'
                        : 'Selisih: ${formatRupiah(diff)}',
                    style: AppTypography.labelMd.copyWith(
                      color: diff == 0
                          ? AppColors.primaryStrong
                          : AppColors.errorStrong,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Tutup Shift (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  context.read<ShiftCubit>().closeShift(
                        actualPhysicalCashIdr: actualCash,
                        notes: notesController.text.trim(),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tutup Shift'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _summaryRow(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bold ? AppTypography.labelMd : AppTypography.bodyMd),
        Text(
          value,
          style: bold
              ? AppTypography.headlineSm.copyWith(color: AppColors.primaryStrong)
              : AppTypography.bodyMd,
        ),
      ],
    ),
  );
}
