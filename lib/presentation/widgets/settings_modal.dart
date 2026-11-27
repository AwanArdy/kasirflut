import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/storage/session_storage.dart';
import '../../core/sync/sync_service.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/update_repository.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../logic/update/update_cubit.dart';
import 'offline_queue_modal.dart';

Future<void> showSettingsModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.42),
    builder: (_) => const SettingsModal(),
  );
}

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool _autoPrintReceipt = true;
  bool _autoCutPaper = true;
  bool _printKitchenCopy = false;
  bool _keepScreenAwake = true;
  bool _isSyncingCloud = false;

  String _serverUrl = SessionStorage.defaultBaseUrl;
  int _pendingTxCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    final url = await SessionStorage().getBaseUrl();
    final txs = await AppDatabase.instance.getRecentTransactions(limit: 50);
    final pending = txs
        .where((t) => t.syncStatus == 'pending' || t.syncStatus == 'failed')
        .length;
    if (mounted) {
      setState(() {
        _serverUrl = url;
        _pendingTxCount = pending;
      });
    }
  }

  Future<void> _forceSyncCloud() async {
    if (_isSyncingCloud) return;
    setState(() => _isSyncingCloud = true);
    final result = await context.read<SyncService>().syncAll();
    if (mounted) {
      await context.read<CatalogCubit>().fetchCatalog();
      await context.read<ShiftCubit>().loadActiveShift(silent: true);
      await _loadDiagnostics();
      setState(() => _isSyncingCloud = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sinkronisasi cloud selesai (${result.syncedTransactions} transaksi terkirim).',
          ),
          backgroundColor: AppColors.primaryStrong,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateRepo = context.read<UpdateRepository>();
    final authState = context.watch<AuthCubit>().state;
    final outletName = authState is AuthAuthenticated
        ? authState.session.outletName
        : 'Outlet TERATUR POS';
    final cashierName =
        authState is AuthAuthenticated ? authState.session.userName : 'Kasir';

    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return Dialog(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 740),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Top Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceContainerHigh),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan & Sistem Kasir',
                          style: AppTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        FutureBuilder<String>(
                          future: updateRepo.getCurrentVersion(),
                          builder: (context, snapshot) {
                            final ver = snapshot.data ?? '-';
                            return Text(
                              'TERATUR POS • Versi terpasang v$ver',
                              style: AppTypography.labelSm,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
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

            // Scrollable Settings Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Update Banner Card
                    _UpdateHeroCard(updateRepo: updateRepo),
                    const SizedBox(height: 16),

                    // 2. Grid 2x2 Core Blocks
                    _buildResponsiveRow(
                      isWide: isWide,
                      left: _SettingsSectionCard(
                        icon: Icons.print_rounded,
                        title: 'Printer & Struk Kasir',
                        subtitle: 'Konfigurasi Thermal Printer & Struk',
                        badgeText: 'Mode Simulasi',
                        badgeBg: AppColors.surfaceContainerLow,
                        badgeFg: AppColors.onSurfaceVariant,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Thermal Printer (58mm / 80mm)',
                                          style: AppTypography.labelMd.copyWith(
                                            letterSpacing: 0,
                                          ),
                                        ),
                                        Text(
                                          'Belum ada perangkat fisik terpasang',
                                          style: AppTypography.labelXs,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SettingToggleRow(
                              title: 'Cetak Otomatis Setelah Bayar',
                              subtitle:
                                  'Struk langsung diproses begitu transaksi sukses',
                              value: _autoPrintReceipt,
                              onChanged: (v) =>
                                  setState(() => _autoPrintReceipt = v),
                            ),
                            _SettingToggleRow(
                              title: 'Potong Kertas Otomatis (Auto-Cut)',
                              subtitle:
                                  'Kertas terpotong rapi di akhir struk tercetak',
                              value: _autoCutPaper,
                              onChanged: (v) =>
                                  setState(() => _autoCutPaper = v),
                            ),
                            _SettingToggleRow(
                              title: 'Cetak Salinan Dapur (Kitchen Copy)',
                              subtitle:
                                  'Tiket pesanan ringkas untuk station barista/dapur',
                              value: _printKitchenCopy,
                              onChanged: (v) =>
                                  setState(() => _printKitchenCopy = v),
                            ),
                          ],
                        ),
                        footer: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Simulasi test print struk berhasil dijalankan.',
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerLow,
                              foregroundColor: AppColors.primaryStrong,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.print_outlined, size: 19),
                            label: Text(
                              'Uji Test Print Struk',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.primaryStrong,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      right: _SettingsSectionCard(
                        icon: Icons.storage_rounded,
                        title: 'Penyimpanan & SQLite Offline',
                        subtitle: 'Basis Data Transaksi Lokal Perangkat',
                        badgeText: 'Kondisi Sehat',
                        badgeBg: AppColors.surfaceContainerHigh,
                        badgeFg: AppColors.primaryStrong,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status Antrean Lokal',
                                        style: AppTypography.labelSm,
                                      ),
                                      Text(
                                        _pendingTxCount == 0
                                            ? '0 Tertunda'
                                            : '$_pendingTxCount Transaksi Pending',
                                        style: AppTypography.labelSm.copyWith(
                                          color: _pendingTxCount == 0
                                              ? AppColors.primaryStrong
                                              : AppColors.warningText,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MiniMetricTile(
                                          icon: Icons
                                              .cloud_done_rounded,
                                          label: 'Antrean Offline',
                                          value: '$_pendingTxCount Pending',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: _MiniMetricTile(
                                          icon: Icons.offline_bolt_rounded,
                                          label: 'Mode Katalog',
                                          value: 'Cache SQLite Aktif',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SettingToggleRow(
                              title: 'Layar Selalu Menyala (Keep Awake)',
                              subtitle:
                                  'Mencegah layar sleep selama shift kasir aktif',
                              value: _keepScreenAwake,
                              onChanged: (v) =>
                                  setState(() => _keepScreenAwake = v),
                            ),
                          ],
                        ),
                        footer: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton.icon(
                            onPressed: () => showOfflineQueueModal(context),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.surfaceContainerLow,
                              foregroundColor: AppColors.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.list_alt_rounded, size: 19),
                            label: Text(
                              'Buka Antrean SQLite Lokal',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onSurface,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Row 2: Outlet & Server Endpoint
                    _buildResponsiveRow(
                      isWide: isWide,
                      left: _SettingsSectionCard(
                        icon: Icons.storefront_rounded,
                        title: 'Toko & Operasional Kasir',
                        subtitle: 'Profil Cabang & Kalkulasi Transaksi',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NAMA OUTLET TERDAFTAR',
                                    style: AppTypography.labelXs.copyWith(
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    outletName,
                                    style: AppTypography.headlineSm.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kasir Bertugas: $cashierName',
                                    style: AppTypography.labelSm,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pajak Restoran (PB1)',
                                          style: AppTypography.labelXs,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '10%',
                                          style: AppTypography.headlineSm
                                              .copyWith(
                                            color: AppColors.primaryStrong,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Promo Aktif Default',
                                          style: AppTypography.labelXs,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'TERATUR10',
                                          style: AppTypography.headlineSm
                                              .copyWith(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      right: _SettingsSectionCard(
                        icon: Icons.dns_rounded,
                        title: 'Sistem & Koneksi Server',
                        subtitle: 'Backend Cloud API & Sinkronisasi',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BACKEND SERVER ENDPOINT',
                                    style: AppTypography.labelXs.copyWith(
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _serverUrl,
                                      style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        footer: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton.icon(
                            onPressed:
                                _isSyncingCloud ? null : _forceSyncCloud,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isSyncingCloud
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimaryContainer,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, size: 19),
                            label: Text(
                              _isSyncingCloud
                                  ? 'Menyinkronkan...'
                                  : 'Paksa Sinkron Cloud & Menu',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isWide,
    required Widget left,
    required Widget right,
  }) {
    if (!isWide) {
      return Column(
        children: [
          left,
          const SizedBox(height: 16),
          right,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _UpdateHeroCard extends StatelessWidget {
  final UpdateRepository updateRepo;
  const _UpdateHeroCard({required this.updateRepo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BlocBuilder<UpdateCubit, UpdateState>(
        builder: (context, state) {
          final isBusy =
              state is UpdateChecking || state is UpdateDownloading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
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
                          runSpacing: 6,
                          children: [
                            Text(
                              'Pembaruan Sistem Aplikasi',
                              style: AppTypography.headlineSm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (state is UpdateAvailable)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Tersedia: v${state.release.version}',
                                  style: AppTypography.labelXs.copyWith(
                                    color: AppColors.primaryStrong,
                                  ),
                                ),
                              )
                            else if (state is UpdateUpToDate)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Versi Terbaru',
                                  style: AppTypography.labelXs.copyWith(
                                    color: AppColors.primaryStrong,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<String>(
                          future: updateRepo.getCurrentVersion(),
                          builder: (context, snapshot) {
                            final ver = snapshot.data ?? '-';
                            return Text(
                              'Versi Terpasang Saat Ini: v$ver • Stabil',
                              style: AppTypography.bodySm,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        height: 44,
                        child: TextButton.icon(
                          onPressed: isBusy
                              ? null
                              : () => context
                                  .read<UpdateCubit>()
                                  .checkManually(),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            foregroundColor: AppColors.primaryStrong,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: state is UpdateChecking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryStrong,
                                  ),
                                )
                              : const Icon(Icons.sync_rounded, size: 19),
                          label: Text(
                            state is UpdateChecking
                                ? 'Memeriksa...'
                                : 'Periksa Update',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.primaryStrong,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                      if (state is UpdateAvailable)
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => context
                                .read<UpdateCubit>()
                                .downloadAndInstall(state.release),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 19),
                            label: Text(
                              'Unduh & Pasang v${state.release.version}',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              if (state is UpdateDownloading) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mengunduh v${state.release.version} (${(state.progress * 100).toStringAsFixed(0)}%)',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: state.progress > 0 ? state.progress : null,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (state is UpdateAvailable &&
                  state.release.notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CATATAN RILIS V${state.release.version}',
                        style: AppTypography.labelXs.copyWith(
                          color: AppColors.primaryStrong,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.release.notes,
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
              ] else if (state is UpdateError) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: AppColors.errorStrong,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.message,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.errorStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;
  final Widget child;
  final Widget? footer;

  const _SettingsSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeBg,
    this.badgeFg,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryStrong, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(subtitle, style: AppTypography.labelXs),
                  ],
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg ?? AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTypography.labelXs.copyWith(
                      color: badgeFg ?? AppColors.primaryStrong,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          if (footer != null) ...[
            const Spacer(),
            const SizedBox(height: 14),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMd.copyWith(
                      letterSpacing: 0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(subtitle, style: AppTypography.labelXs),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              activeThumbColor: AppColors.onPrimary,
              activeTrackColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelXs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }
}
