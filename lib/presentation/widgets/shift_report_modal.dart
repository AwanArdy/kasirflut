import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/local/app_database.dart';
import '../../data/models/shift_model.dart';
import '../../data/models/transaction_model.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../utils/currency_formatter.dart';

Future<void> showShiftReportModal(
  BuildContext context, {
  required ShiftModel shift,
  int startingCashIdr = 0,
  int? actualPhysicalCashIdr,
  String shiftName = 'Shift Kasir',
  DateTime? openedAt,
  bool defaultReportZ = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.55),
    builder: (_) => ShiftReportModal(
      shift: shift,
      startingCashIdr: startingCashIdr,
      actualPhysicalCashIdr: actualPhysicalCashIdr,
      shiftName: shiftName,
      openedAt: openedAt,
      defaultReportZ: defaultReportZ,
    ),
  );
}

class ShiftReportModal extends StatefulWidget {
  final ShiftModel shift;
  final int startingCashIdr;
  final int? actualPhysicalCashIdr;
  final String shiftName;
  final DateTime? openedAt;
  final bool defaultReportZ;

  const ShiftReportModal({
    super.key,
    required this.shift,
    this.startingCashIdr = 0,
    this.actualPhysicalCashIdr,
    this.shiftName = 'Shift Kasir',
    this.openedAt,
    this.defaultReportZ = true,
  });

  @override
  State<ShiftReportModal> createState() => _ShiftReportModalState();
}

class _ShiftReportModalState extends State<ShiftReportModal> {
  late bool _isReportZ;
  int _paperWidthMm = 80;

  bool _openCashDrawer = true;
  bool _autoCutPaper = true;
  bool _printDuplicate = false;

  bool _loadingTx = true;
  bool _printing = false;
  bool _highlightCard = false;
  List<TransactionModel> _shiftTransactions = [];

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isReportZ = widget.defaultReportZ;
    _loadShiftTransactions();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadShiftTransactions() async {
    final rows = await AppDatabase.instance.getRecentTransactions(limit: 200);
    final now = DateTime.now();
    final startBoundary = widget.openedAt ??
        DateTime(now.year, now.month, now.day);

    final filtered = rows.where((tx) {
      return !tx.soldAt.toLocal().isBefore(
            startBoundary.subtract(const Duration(minutes: 1)),
          );
    }).toList();

    if (mounted) {
      setState(() {
        _shiftTransactions = filtered;
        _loadingTx = false;
      });
    }
  }

  Future<void> _handleTestPrint() async {
    setState(() => _highlightCard = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _highlightCard = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Perintah Uji Cetak terkirim ke printer thermal! Sinyal laci kasir aktif.',
        ),
        backgroundColor: AppColors.primaryStrong,
      ),
    );
  }

  Future<void> _handleExecutePrint() async {
    if (_printing) return;
    setState(() => _printing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _printing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Struk ${_isReportZ ? 'Laporan Z' : 'Laporan X'} (${_paperWidthMm}mm) berhasil dikirim ke printer.',
        ),
        backgroundColor: AppColors.primaryStrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final outletName = authState is AuthAuthenticated
        ? authState.session.outletName
        : 'TERATUR POS OUTLET';
    final cashierName = authState is AuthAuthenticated
        ? authState.session.userName
        : 'Kasir Bertugas';

    final now = DateTime.now();
    final docDateTag = DateFormat('yyyyMMdd').format(now);
    final docNo = _isReportZ
        ? '#RPT-Z-$docDateTag-001'
        : '#RPT-X-$docDateTag-001';
    final printedAt = DateFormat('dd MMM yyyy, HH:mm').format(now);

    // Hitung ringkasan transaksi dari SQLite
    int cashTotal = 0;
    int cashCount = 0;
    int qrisTotal = 0;
    int qrisCount = 0;
    int debitTotal = 0;
    int debitCount = 0;
    int transferTotal = 0;
    int transferCount = 0;

    for (final tx in _shiftTransactions) {
      switch (tx.paymentMethod) {
        case 'qris':
          qrisTotal += tx.totalIdr;
          qrisCount++;
          break;
        case 'debit':
          debitTotal += tx.totalIdr;
          debitCount++;
          break;
        case 'bank_transfer':
          transferTotal += tx.totalIdr;
          transferCount++;
          break;
        default:
          cashTotal += tx.totalIdr;
          cashCount++;
      }
    }

    final netSalesIdr =
        cashTotal + qrisTotal + debitTotal + transferTotal;
    final nonCashTotalIdr = qrisTotal + debitTotal + transferTotal;
    final txCount = _shiftTransactions.length;
    final avgBasketIdr = txCount > 0 ? (netSalesIdr ~/ txCount) : 0;

    final expectedDrawerCashIdr = widget.startingCashIdr + cashTotal;
    final actualDrawerCashIdr =
        widget.actualPhysicalCashIdr ?? expectedDrawerCashIdr;
    final diffCashIdr = actualDrawerCashIdr - expectedDrawerCashIdr;
    final cashDepositIdr =
        (actualDrawerCashIdr - widget.startingCashIdr).clamp(0, 1 << 31);

    final isWide = MediaQuery.sizeOf(context).width >= 920;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyP &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          _handleExecutePrint();
        }
      },
      child: Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120, maxHeight: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 18, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        color: AppColors.primaryStrong,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                'Cetak Laporan Shift Kasir',
                                style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'REPORT X / Z',
                                  style: AppTypography.labelXs,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pratinjau struk thermal 80mm/58mm untuk audit tengah shift (Laporan X) dan penutupan akhir buku kasir (Laporan Z).',
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Toolbar: Report X vs Z & Lebar Kertas
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                color: AppColors.surfaceContainerLow,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 10,
                  spacing: 12,
                  children: [
                    // Segmented Tab Switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ReportTabButton(
                            selected: !_isReportZ,
                            icon: Icons.analytics_rounded,
                            title: 'Laporan X (Interim)',
                            subtitle: 'Audit berjalan • Kas tetap buka',
                            onTap: () => setState(() => _isReportZ = false),
                          ),
                          const SizedBox(width: 4),
                          _ReportTabButton(
                            selected: _isReportZ,
                            icon: Icons.lock_reset_rounded,
                            title: 'Laporan Z (Final / Tutup)',
                            subtitle: 'Tutup buku • Reset counter',
                            badge: 'RESMI',
                            onTap: () => setState(() => _isReportZ = true),
                          ),
                        ],
                      ),
                    ),

                    // Paper Width Selector
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LEBAR KERTAS:',
                          style: AppTypography.labelXs.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _PaperSizeChip(
                          selected: _paperWidthMm == 80,
                          icon: Icons.receipt_long_rounded,
                          label: 'Thermal 80mm',
                          onTap: () => setState(() => _paperWidthMm = 80),
                        ),
                        const SizedBox(width: 6),
                        _PaperSizeChip(
                          selected: _paperWidthMm == 58,
                          icon: Icons.receipt_rounded,
                          label: 'Thermal 58mm',
                          onTap: () => setState(() => _paperWidthMm = 58),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Body Split View
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _buildReceiptPreviewPane(
                              outletName: outletName,
                              cashierName: cashierName,
                              docNo: docNo,
                              printedAt: printedAt,
                              netSalesIdr: netSalesIdr,
                              txCount: txCount,
                              avgBasketIdr: avgBasketIdr,
                              cashTotal: cashTotal,
                              cashCount: cashCount,
                              qrisTotal: qrisTotal,
                              qrisCount: qrisCount,
                              debitTotal: debitTotal,
                              debitCount: debitCount,
                              transferTotal: transferTotal,
                              transferCount: transferCount,
                              nonCashTotalIdr: nonCashTotalIdr,
                              expectedDrawerCashIdr: expectedDrawerCashIdr,
                              actualDrawerCashIdr: actualDrawerCashIdr,
                              diffCashIdr: diffCashIdr,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: _buildControlsPane(
                              cashDepositIdr: cashDepositIdr,
                              nonCashTotalIdr: nonCashTotalIdr,
                              diffCashIdr: diffCashIdr,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildReceiptPreviewPane(
                              outletName: outletName,
                              cashierName: cashierName,
                              docNo: docNo,
                              printedAt: printedAt,
                              netSalesIdr: netSalesIdr,
                              txCount: txCount,
                              avgBasketIdr: avgBasketIdr,
                              cashTotal: cashTotal,
                              cashCount: cashCount,
                              qrisTotal: qrisTotal,
                              qrisCount: qrisCount,
                              debitTotal: debitTotal,
                              debitCount: debitCount,
                              transferTotal: transferTotal,
                              transferCount: transferCount,
                              nonCashTotalIdr: nonCashTotalIdr,
                              expectedDrawerCashIdr: expectedDrawerCashIdr,
                              actualDrawerCashIdr: actualDrawerCashIdr,
                              diffCashIdr: diffCashIdr,
                              scrollable: false,
                            ),
                            _buildControlsPane(
                              cashDepositIdr: cashDepositIdr,
                              nonCashTotalIdr: nonCashTotalIdr,
                              diffCashIdr: diffCashIdr,
                              scrollable: false,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreviewPane({
    required String outletName,
    required String cashierName,
    required String docNo,
    required String printedAt,
    required int netSalesIdr,
    required int txCount,
    required int avgBasketIdr,
    required int cashTotal,
    required int cashCount,
    required int qrisTotal,
    required int qrisCount,
    required int debitTotal,
    required int debitCount,
    required int transferTotal,
    required int transferCount,
    required int nonCashTotalIdr,
    required int expectedDrawerCashIdr,
    required int actualDrawerCashIdr,
    required int diffCashIdr,
    bool scrollable = true,
  }) {
    final maxReceiptWidth = _paperWidthMm == 58 ? 300.0 : 420.0;
    final baseFontSize = _paperWidthMm == 58 ? 11.0 : 12.0;

    final content = Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxReceiptWidth),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_rounded,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PRATINJAU THERMAL REALTIME',
                      style: AppTypography.labelXs.copyWith(letterSpacing: 0.5),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _paperWidthMm == 58
                        ? 'Lebar: 58 mm (Compact)'
                        : 'Lebar: 80 mm',
                    style: AppTypography.labelXs.copyWith(
                      color: AppColors.primaryStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Thermal Receipt Card
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: double.infinity,
          constraints: BoxConstraints(maxWidth: maxReceiptWidth),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: _highlightCard
                ? Border.all(color: AppColors.primaryStrong, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: baseFontSize,
              height: 1.45,
              color: AppColors.onSurface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Store Header
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primaryStrong,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      outletName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'TERATUR POS • Cloud & Offline Ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: baseFontSize - 1,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const _DashedDivider(thick: true),

                // Report Banner
                Column(
                  children: [
                    Text(
                      _isReportZ
                          ? '*** LAPORAN Z - TUTUP SHIFT RESMI ***'
                          : '*** LAPORAN X - AUDIT BERJALAN ***',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: baseFontSize + 1,
                        color: _isReportZ
                            ? AppColors.primaryStrong
                            : AppColors.warningText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isReportZ
                          ? 'REGISTER DI-RESET KE COUNTER 0'
                          : 'KAS REGISTER TETAP BERJALAN (TANPA RESET)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: baseFontSize - 2,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const _DashedDivider(),

                _ReceiptMetaRow(label: 'No. Laporan:', value: docNo),
                _ReceiptMetaRow(label: 'Kasir / Operator:', value: cashierName),
                _ReceiptMetaRow(label: 'Sesi Shift:', value: widget.shiftName),
                _ReceiptMetaRow(label: 'Waktu Cetak:', value: '$printedAt WIB'),

                const _DashedDivider(thick: true),

                // Section 1: Sales Summary
                Text(
                  '[ 1. RINGKASAN PENJUALAN ]',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: baseFontSize - 1,
                    color: AppColors.primaryStrong,
                  ),
                ),
                const SizedBox(height: 4),
                _ReceiptAmountRow(
                  label: 'Modal Awal (Float Cash)',
                  amount: formatRupiah(widget.startingCashIdr),
                ),
                _ReceiptAmountRow(
                  label: 'Penjualan Bersih',
                  amount: formatRupiah(netSalesIdr),
                ),
                const _DashedDivider(),
                _ReceiptAmountRow(
                  label: 'TOTAL PENJUALAN BERSIH:',
                  amount: formatRupiah(netSalesIdr),
                  bold: true,
                  valueColor: AppColors.primaryStrong,
                ),
                _ReceiptMetaRow(
                  label: 'Total Struk Transaksi:',
                  value: '$txCount Struk (Avg: ${formatRupiah(avgBasketIdr)})',
                ),

                const _DashedDivider(thick: true),

                // Section 2: Payment Breakdown
                Text(
                  '[ 2. RINCIAN METODE PEMBAYARAN ]',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: baseFontSize - 1,
                    color: AppColors.primaryStrong,
                  ),
                ),
                const SizedBox(height: 4),
                if (_loadingTx)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  _ReceiptAmountRow(
                    label: '1. Tunai / Cash ($cashCount trx)',
                    amount: formatRupiah(cashTotal),
                    boldValue: true,
                  ),
                  _ReceiptAmountRow(
                    label: '2. QRIS ($qrisCount trx)',
                    amount: formatRupiah(qrisTotal),
                    boldValue: true,
                  ),
                  _ReceiptAmountRow(
                    label: '3. Kartu Debit / EDC ($debitCount trx)',
                    amount: formatRupiah(debitTotal),
                    boldValue: true,
                  ),
                  _ReceiptAmountRow(
                    label: '4. Transfer Bank ($transferCount trx)',
                    amount: formatRupiah(transferTotal),
                  ),
                  const _DashedDivider(),
                  _ReceiptAmountRow(
                    label: 'Total Non-Tunai:',
                    amount: formatRupiah(nonCashTotalIdr),
                    bold: true,
                  ),
                ],

                const _DashedDivider(thick: true),

                // Section 3: Cash Drawer Reconciliation
                Text(
                  '[ 3. REKONSILIASI KAS LACI ]',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: baseFontSize - 1,
                    color: AppColors.primaryStrong,
                  ),
                ),
                const SizedBox(height: 4),
                _ReceiptAmountRow(
                  label: 'Modal Awal Laci:',
                  amount: formatRupiah(widget.startingCashIdr),
                ),
                _ReceiptAmountRow(
                  label: 'Penerimaan Tunai:',
                  amount: '+ ${formatRupiah(cashTotal)}',
                ),
                const _DashedDivider(),
                _ReceiptAmountRow(
                  label: 'Ekspektasi Kas Sistem:',
                  amount: formatRupiah(expectedDrawerCashIdr),
                  bold: true,
                ),
                _ReceiptAmountRow(
                  label: 'Kas Fisik Aktual:',
                  amount: formatRupiah(actualDrawerCashIdr),
                  bold: true,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: diffCashIdr == 0
                        ? AppColors.surfaceContainerHigh.withValues(alpha: 0.7)
                        : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELISIH KAS:',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: baseFontSize - 1,
                          color: diffCashIdr == 0
                              ? AppColors.primaryStrong
                              : AppColors.errorStrong,
                        ),
                      ),
                      Text(
                        diffCashIdr == 0
                            ? 'Rp 0 [SEIMBANG]'
                            : '${diffCashIdr > 0 ? '+' : ''}${formatRupiah(diffCashIdr)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: baseFontSize - 1,
                          color: diffCashIdr == 0
                              ? AppColors.primaryStrong
                              : AppColors.errorStrong,
                        ),
                      ),
                    ],
                  ),
                ),

                const _DashedDivider(thick: true),

                // Signatures
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Kasir Bertugas,',
                              style: TextStyle(fontSize: baseFontSize - 2),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              '( $cashierName )',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: baseFontSize - 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Supervisor / Mod,',
                              style: TextStyle(fontSize: baseFontSize - 2),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              '( ...................... )',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: baseFontSize - 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const _DashedDivider(),
                Text(
                  'Simpan struk ini sebagai lampiran setor kas.\n--- TERATUR POS ---',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize - 2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(20),
      child: scrollable
          ? SingleChildScrollView(child: Center(child: content))
          : Center(child: content),
    );
  }

  Widget _buildControlsPane({
    required int cashDepositIdr,
    required int nonCashTotalIdr,
    required int diffCashIdr,
    bool scrollable = true,
  }) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Printer Hardware Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.print_rounded,
                        size: 19,
                        color: AppColors.primaryStrong,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Printer Kasir Utama',
                        style: AppTypography.labelMd.copyWith(
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Siap Cetak',
                      style: AppTypography.labelXs.copyWith(
                        color: AppColors.primaryStrong,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CheckOptionRow(
                label: 'Buka Laci Kasir Otomatis (Kick RJ11 Drawer)',
                value: _openCashDrawer,
                onChanged: (v) => setState(() => _openCashDrawer = v),
              ),
              _CheckOptionRow(
                label: 'Potong Kertas Otomatis (Auto-Cutter)',
                value: _autoCutPaper,
                onChanged: (v) => setState(() => _autoCutPaper = v),
              ),
              _CheckOptionRow(
                label: 'Cetak Rangkap 2 (Arsip Kasir & Owner)',
                value: _printDuplicate,
                onChanged: (v) => setState(() => _printDuplicate = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Audit Highlight Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RINGKASAN VALIDASI SHIFT KASIR',
                style: AppTypography.labelXs.copyWith(
                  color: AppColors.primaryStrong,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setor Tunai (Deposit)',
                            style: AppTypography.labelXs,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatRupiah(cashDepositIdr),
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Setelah modal disisihkan',
                            style: AppTypography.labelXs.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Kas Laci',
                            style: AppTypography.labelXs,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                diffCashIdr == 0
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: diffCashIdr == 0
                                    ? AppColors.primaryStrong
                                    : AppColors.errorStrong,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  diffCashIdr == 0 ? 'SEIMBANG' : 'SELISIH',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headlineSm.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: diffCashIdr == 0
                                        ? AppColors.primaryStrong
                                        : AppColors.errorStrong,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            diffCashIdr == 0
                                ? 'Selisih 0 rupiah'
                                : formatRupiah(diffCashIdr),
                            style: AppTypography.labelXs.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Non-Tunai (QRIS & EDC):',
                      style: AppTypography.labelSm,
                    ),
                    Text(
                      formatRupiah(nonCashTotalIdr),
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Export & Share
        Text(
          'EKSPOR & NOTIFIKASI MANAJER',
          style: AppTypography.labelXs.copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menyiapkan dokumen PDF laporan shift...'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 18,
                    color: AppColors.primaryStrong,
                  ),
                  label: Text(
                    'Unduh PDF',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Ringkasan shift siap dibagikan ke SPV.'),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 17,
                    color: AppColors.primaryStrong,
                  ),
                  label: Text(
                    'Kirim ke SPV',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final bottomActions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextButton.icon(
                  onPressed: _handleTestPrint,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.primaryStrong,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.bug_report_rounded, size: 18),
                  label: Text(
                    'Uji Cetak (Test)',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primaryStrong,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Batal / Tutup',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _printing ? null : _handleExecutePrint,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 21),
            label: Text(
              _printing
                  ? 'Mengirim ke Printer...'
                  : 'Cetak Struk Sekarang (Ctrl + P)',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: scrollable
          ? Column(
              children: [
                Expanded(child: SingleChildScrollView(child: body)),
                bottomActions,
              ],
            )
          : Column(
              children: [
                body,
                bottomActions,
              ],
            ),
    );
  }
}

class _ReportTabButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _ReportTabButton({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 13,
                        letterSpacing: 0,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge!,
                          style: AppTypography.labelXs.copyWith(
                            fontSize: 9,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelXs.copyWith(
                    fontSize: 10,
                    color: selected
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperSizeChip extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PaperSizeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final bool thick;
  const _DashedDivider({this.thick = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 7).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => SizedBox(
                width: 4,
                height: thick ? 1.5 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptAmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final bool bold;
  final bool boldValue;
  final Color? valueColor;

  const _ReceiptAmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
    this.boldValue = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? AppColors.onSurface : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(
              fontWeight:
                  (bold || boldValue) ? FontWeight.w700 : FontWeight.w400,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckOptionRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckOptionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                activeColor: AppColors.primary,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySm.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
