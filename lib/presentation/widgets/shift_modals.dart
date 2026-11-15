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
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primaryStrong,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Buka Shift Kasir'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Shift', style: AppTypography.labelSm),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'morning',
                          icon: Icon(Icons.wb_sunny_outlined, size: 16),
                          label: Text('Pagi'),
                        ),
                        ButtonSegment(
                          value: 'evening',
                          icon: Icon(Icons.nights_stay_outlined, size: 16),
                          label: Text('Sore / Malam'),
                        ),
                      ],
                      selected: {shiftName},
                      onSelectionChanged: (val) {
                        setState(() => shiftName = val.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Modal Kas Awal (IDR)', style: AppTypography.labelSm),
                  const SizedBox(height: 6),
                  TextField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '200000',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Catatan (opsional)', style: AppTypography.labelSm),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      hintText: 'Catatan pembukaan shift',
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
                  final cash = int.tryParse(cashController.text
                          .replaceAll(RegExp(r'[^0-9]'), '')) ??
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
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: AppColors.errorStrong,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Tutup Shift Kasir'),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Modal Awal',
                              formatRupiah(activeShift.startingCashIdr)),
                          _summaryRow('Penjualan Tunai',
                              formatRupiah(activeShift.cashSalesIdr)),
                          _summaryRow('Penjualan QRIS',
                              formatRupiah(activeShift.qrisSalesIdr)),
                          const Divider(height: 18),
                          _summaryRow(
                            'Ekspektasi Uang Laci',
                            formatRupiah(activeShift.expectedCashIdr),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Uang Fisik Aktual di Laci (IDR)',
                        style: AppTypography.labelSm),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            diff == 0 ? AppColors.successBg : AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            diff == 0
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: diff == 0
                                ? AppColors.primaryStrong
                                : AppColors.errorStrong,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            diff == 0
                                ? 'Status: Balance (Sesuai)'
                                : 'Selisih: ${formatRupiah(diff)}',
                            style: AppTypography.labelMd.copyWith(
                              letterSpacing: 0.1,
                              color: diff == 0
                                  ? AppColors.primaryStrong
                                  : AppColors.errorStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Catatan Tutup Shift (opsional)',
                        style: AppTypography.labelSm),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        hintText: 'Catatan penutupan shift',
                      ),
                    ),
                  ],
                ),
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
                  foregroundColor: AppColors.onError,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
        Text(
          label,
          style: bold
              ? AppTypography.labelMd.copyWith(letterSpacing: 0)
              : AppTypography.bodySm,
        ),
        Text(
          value,
          style: bold
              ? AppTypography.headlineSm.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w800,
                )
              : AppTypography.bodyMd.copyWith(fontSize: 14),
        ),
      ],
    ),
  );
}
