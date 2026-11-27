import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/storage/session_storage.dart';
import '../../data/local/app_database.dart';
import '../../data/models/shift_model.dart';
import '../../data/models/transaction_model.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';

/// Menyimpan parameter buka shift sementara selama proses login berlangsung
class PendingShiftDraft {
  final int startingCashIdr;
  final String shiftName;
  final String notes;

  const PendingShiftDraft({
    required this.startingCashIdr,
    required this.shiftName,
    required this.notes,
  });

  static PendingShiftDraft? _current;

  static void save({
    required int startingCashIdr,
    required String shiftName,
    required String notes,
  }) {
    _current = PendingShiftDraft(
      startingCashIdr: startingCashIdr,
      shiftName: shiftName,
      notes: notes,
    );
  }

  static PendingShiftDraft? consume() {
    final draft = _current;
    _current = null;
    return draft;
  }
}

/// Formatter ribuan otomatis untuk input nominal kas (contoh: 500000 -> 500.000)
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = NumberFormat('#,###', 'id_ID').format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Background canvas home kasir kosong dengan efek blur
class PosBlurredBackdrop extends StatelessWidget {
  final Widget child;

  const PosBlurredBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Stack(
      children: [
        // Layer 1: Simulasi Home Kasir (Menu Kosong)
        IgnorePointer(
          child: Column(
            children: [
              // Simulated TopNavBar
              Container(
                height: 74,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.surfaceContainerHigh),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TERATUR POS',
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Menunggu Buka Shift',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.warningText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Simulated Empty POS Canvas + Sidebar
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const [
                                _SkeletonChip(
                                    label: 'Semua Menu', active: true),
                                _SkeletonChip(label: 'Kopi & Espresso'),
                                _SkeletonChip(label: 'Non-Kopi & Teh'),
                                _SkeletonChip(label: 'Makanan Ringan'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 3 : 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.92,
                                ),
                                itemCount: 6,
                                itemBuilder: (_, __) => Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.surfaceContainerLow,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.local_cafe_outlined,
                                              size: 32,
                                              color: AppColors.outlineVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 12,
                                        width: 110,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerHigh,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 14,
                                        width: 75,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isWide)
                      Container(
                        width: 360,
                        color: AppColors.surface,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Detail',
                              style: AppTypography.headlineSm,
                            ),
                            const Spacer(),
                            const Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 44,
                                    color: AppColors.outlineVariant,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Belum ada pesanan'),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Layer 2: Scrim + Blur Backdrop
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),

        // Layer 3: Modal Content
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  final String label;
  final bool active;

  const _SkeletonChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.secondaryFixedDim : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.onSurface,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// Kartu Modal Buka Shift (sekaligus Login + Buka Shift tanpa pilihan sesi kaku)
class OpenShiftModalCard extends StatefulWidget {
  final bool isLoginMode;

  const OpenShiftModalCard({
    super.key,
    required this.isLoginMode,
  });

  @override
  State<OpenShiftModalCard> createState() => _OpenShiftModalCardState();
}

class _OpenShiftModalCardState extends State<OpenShiftModalCard> {
  final _emailController = TextEditingController(text: 'kasir@teratur.id');
  final _passwordController = TextEditingController(text: 'password123');
  final _serverController =
      TextEditingController(text: SessionStorage.defaultBaseUrl);
  final _cashController = TextEditingController(text: '500.000');
  final _notesController = TextEditingController();

  bool _obscurePassword = true;
  bool _showServerField = false;

  static const List<int> _quickNominalOptions = [
    200000,
    300000,
    500000,
    750000,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isLoginMode) {
      SessionStorage().getBaseUrl().then((url) {
        if (mounted) _serverController.text = url;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _parsedStartingCash {
    return int.tryParse(
          _cashController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
  }

  /// Nilai fallback internal untuk kompatibilitas API & model shift
  String get _autoShiftName => DateTime.now().hour < 15 ? 'morning' : 'evening';

  void _selectQuickNominal(int amount) {
    final formatted = NumberFormat('#,###', 'id_ID').format(amount);
    setState(() {
      _cashController.text = formatted;
    });
  }

  void _handleSubmit() {
    final startingCash = _parsedStartingCash;
    final notes = _notesController.text.trim();

    if (widget.isLoginMode) {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email dan password kasir wajib diisi.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      PendingShiftDraft.save(
        startingCashIdr: startingCash,
        shiftName: _autoShiftName,
        notes: notes,
      );

      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            serverUrl: _serverController.text.trim(),
          );
    } else {
      context.read<ShiftCubit>().openShift(
            startingCashIdr: startingCash,
            shiftName: _autoShiftName,
            notes: notes,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final shiftState = context.watch<ShiftCubit>().state;
    final isSubmitting =
        authState is AuthLoading || shiftState is ShiftLoading;

    return Container(
      width: 520,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Modal Buka Shift
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: AppColors.primaryStrong,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isLoginMode
                          ? 'Masuk & Buka Shift Kasir'
                          : 'Buka Shift Kasir',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isLoginMode
                          ? 'Login akun kasir & lengkapi modal laci sebelum transaksi'
                          : 'Lengkapi kas awal laci sebelum mulai transaksi',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'BUKA KASIR',
                  style: AppTypography.labelXs.copyWith(
                    color: AppColors.primaryStrong,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Identitas Kasir: Form Email & Password (jika belum login) atau Card Kasir Bertugas
          if (widget.isLoginMode) ...[
            Text(
              'Akun Kasir',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'kasir@teratur.id',
                      prefixIcon: const Icon(Icons.email_outlined, size: 19),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, size: 19),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 19,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showServerField = !_showServerField),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryStrong,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _showServerField
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.dns_outlined,
                  size: 15,
                ),
                label: Text(
                  _showServerField ? 'Sembunyikan Server' : 'Atur Server URL',
                  style: AppTypography.labelXs.copyWith(
                    color: AppColors.primaryStrong,
                  ),
                ),
              ),
            ),
            if (_showServerField) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _serverController,
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'http://10.0.2.2:3000/api/v1',
                  prefixIcon: const Icon(Icons.link_rounded, size: 19),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ] else if (authState is AuthAuthenticated) ...[
            Text(
              'Kasir Bertugas',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      authState.session.userName.isNotEmpty
                          ? authState.session.userName[0].toUpperCase()
                          : 'K',
                      style: AppTypography.headlineSm.copyWith(
                        fontSize: 16,
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.session.userName,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.session.outletName,
                          style: AppTypography.labelXs,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.primaryStrong,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Modal Awal / Float Cash Input & Quick Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modal Awal / Uang Kasir (Float Cash)',
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Wajib Dihitung Fisik',
                style: AppTypography.labelXs.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
            style: AppTypography.headlineSm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Rp',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryStrong,
                      ),
                    ),
                  ],
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Nominal Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Pilihan cepat:',
                style: AppTypography.labelXs,
              ),
              ..._quickNominalOptions.map((nominal) {
                final isSelected = _parsedStartingCash == nominal;
                return InkWell(
                  onTap: () => _selectQuickNominal(nominal),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      formatRupiah(nominal),
                      style: AppTypography.labelXs.copyWith(
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Catatan Pembukaan Shift (Opsional)
          Row(
            children: [
              Text(
                'Catatan Pembukaan Shift ',
                style: AppTypography.labelSm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '(Opsional)',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText:
                  'Misal: Uang receh pecahan Rp 2.000 dan Rp 5.000 cukup.',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // SOP Alert Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.warningText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pastikan nominal kas fisik di dalam laci sudah dihitung sebelum menekan tombol buka shift.',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.warningText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Row
          Row(
            children: [
              if (!widget.isLoginMode) ...[
                TextButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () => context.read<AuthCubit>().logout(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorStrong,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar Akun'),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_open_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.isLoginMode
                                    ? 'Masuk & Buka Shift'
                                    : 'Buka Shift Sekarang',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fallback jika dipanggil manual dari tombol header
Future<void> showOpenShiftDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.4),
    builder: (_) => const Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: OpenShiftModalCard(isLoginMode: false),
    ),
  );
}

/// Modal Tutup Shift & Rekonsiliasi Kas (dengan Panel Struk Laporan X/Z Side-by-Side)
Future<void> showCloseShiftDialog(
  BuildContext context,
  ShiftModel activeShift,
) async {
  await showDialog<void>(
    context: context,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.45),
    builder: (_) => _CloseShiftWithReceiptDialog(
      parentContext: context,
      activeShift: activeShift,
    ),
  );
}

class _CloseShiftWithReceiptDialog extends StatefulWidget {
  final BuildContext parentContext;
  final ShiftModel activeShift;

  const _CloseShiftWithReceiptDialog({
    required this.parentContext,
    required this.activeShift,
  });

  @override
  State<_CloseShiftWithReceiptDialog> createState() =>
      _CloseShiftWithReceiptDialogState();
}

class _CloseShiftWithReceiptDialogState
    extends State<_CloseShiftWithReceiptDialog> {
  late final TextEditingController _cashController;
  final TextEditingController _notesController = TextEditingController();

  bool _showReportPreview = false;
  bool _isReportZ = true;
  int _paperWidthMm = 80;
  bool _printing = false;
  bool _highlightReceipt = false;

  List<TransactionModel> _shiftTransactions = [];
  bool _loadingTx = true;

  @override
  void initState() {
    super.initState();
    final initialFormatted = NumberFormat('#,###', 'id_ID')
        .format(widget.activeShift.expectedCashIdr);
    _cashController = TextEditingController(text: initialFormatted);
    _loadShiftTransactions();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftTransactions() async {
    final rows = await AppDatabase.instance.getRecentTransactions(limit: 200);
    final boundary = widget.activeShift.openedAt
        .toLocal()
        .subtract(const Duration(minutes: 1));
    final filtered = rows
        .where((tx) => !tx.soldAt.toLocal().isBefore(boundary))
        .toList();

    if (mounted) {
      setState(() {
        _shiftTransactions = filtered;
        _loadingTx = false;
      });
    }
  }

  int get _actualCash =>
      int.tryParse(
        _cashController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  Future<void> _handleTestPrint() async {
    setState(() => _highlightReceipt = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _highlightReceipt = false);
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      const SnackBar(
        content: Text(
          'Uji cetak terkirim ke printer thermal! Sinyal laci kasir aktif.',
        ),
        backgroundColor: AppColors.primaryStrong,
      ),
    );
  }

  Future<void> _handlePrintReceipt() async {
    if (_printing) return;
    setState(() => _printing = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    setState(() => _printing = false);
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
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
    final authState = widget.parentContext.read<AuthCubit>().state;
    final cashierName =
        authState is AuthAuthenticated ? authState.session.userName : 'Kasir';
    final outletName = authState is AuthAuthenticated
        ? authState.session.outletName
        : 'TERATUR POS OUTLET';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final canSideBySide = screenWidth >= 960;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerLeft,
        child: canSideBySide
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KIRI: Card Modal Tutup Shift
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 560,
                      maxHeight: 740,
                    ),
                    child: _buildCloseShiftCard(cashierName: cashierName),
                  ),

                  // KANAN: Panel Struk Laporan X/Z (muncul di sebelahnya saat diklik)
                  if (_showReportPreview) ...[
                    const SizedBox(width: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _paperWidthMm == 58 ? 360 : 430,
                        maxHeight: 740,
                      ),
                      child: _buildSideReportReceiptCard(
                        outletName: outletName,
                        cashierName: cashierName,
                      ),
                    ),
                  ],
                ],
              )
            // Layar sempit (< 960px): bertumpuk vertikal dalam satu scroll
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560, maxHeight: 740),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCloseShiftCard(
                        cashierName: cashierName,
                        scrollable: false,
                      ),
                      if (_showReportPreview) ...[
                        const SizedBox(height: 16),
                        _buildSideReportReceiptCard(
                          outletName: outletName,
                          cashierName: cashierName,
                          scrollable: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCloseShiftCard({
    required String cashierName,
    bool scrollable = true,
  }) {
    final activeShift = widget.activeShift;
    final actualCash = _actualCash;
    final diff = actualCash - activeShift.expectedCashIdr;

    final duration = DateTime.now().difference(activeShift.openedAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final openedTimeLabel =
        'Dibuka ${DateFormat('HH:mm').format(activeShift.openedAt.toLocal())}';

    final Color reconBg;
    final Color reconColor;
    final IconData reconIcon;
    final String reconTitle;
    final String reconDesc;

    if (diff == 0) {
      reconBg = AppColors.surfaceContainer;
      reconColor = AppColors.primaryStrong;
      reconIcon = Icons.check_circle_rounded;
      reconTitle = 'Status: Seimbang / Balance';
      reconDesc = 'Selisih: Rp 0 (Semua uang kas klop sempurna)';
    } else if (diff < 0) {
      reconBg = AppColors.dangerBg;
      reconColor = AppColors.errorStrong;
      reconIcon = Icons.warning_rounded;
      reconTitle = 'Status: Selisih Kurang (Shortage)';
      reconDesc =
          'Kurang: -${formatRupiah(diff.abs())} (Wajib cantumkan catatan)';
    } else {
      reconBg = AppColors.warningBg;
      reconColor = AppColors.warningText;
      reconIcon = Icons.info_rounded;
      reconTitle = 'Status: Selisih Lebih (Overage)';
      reconDesc =
          'Lebih: +${formatRupiah(diff)} (Uang kas berlebih dari penjualan)';
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Modal Tutup Shift
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: AppColors.errorStrong,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tutup Shift & Rekonsiliasi Kas',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hitung total uang fisik dan selesaikan buku kas harian',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.errorStrong,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SELESAI SHIFT',
                    style: AppTypography.labelXs.copyWith(
                      color: AppColors.errorStrong,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Active Shift Meta Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    openedTimeLabel,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '|',
                      style: TextStyle(color: AppColors.outlineVariant),
                    ),
                  ),
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 17,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cashierName,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: AppColors.primaryStrong,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aktif: $hours jam $minutes menit',
                      style: AppTypography.labelXs.copyWith(
                        color: AppColors.primaryStrong,
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

        // Ledger Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _ledgerRow(
                label: '1. Modal Awal Kasir (Float)',
                value: formatRupiah(activeShift.startingCashIdr),
              ),
              const SizedBox(height: 10),
              _ledgerRow(
                label: '2. Penjualan Tunai (Cash)',
                value: '+ ${formatRupiah(activeShift.cashSalesIdr)}',
                valueColor: AppColors.primaryStrong,
              ),
              const SizedBox(height: 10),
              _ledgerRow(
                label: '3. Penjualan Non-Tunai (QRIS)',
                badge: 'Auto-Settled',
                value: formatRupiah(activeShift.qrisSalesIdr),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: AppColors.outlineVariant,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ekspektasi Kas Fisik di Laci',
                        style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Modal Awal + Penjualan Tunai',
                        style: AppTypography.labelXs,
                      ),
                    ],
                  ),
                  Text(
                    formatRupiah(activeShift.expectedCashIdr),
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryStrong,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Input Kas Aktual
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Uang Kas Fisik Dihitung',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _cashController.text = NumberFormat('#,###', 'id_ID')
                      .format(activeShift.expectedCashIdr);
                });
              },
              child: Text(
                'Sesuai Sistem',
                style: AppTypography.labelXs.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _cashController,
          keyboardType: TextInputType.number,
          inputFormatters: [_ThousandsFormatter()],
          onChanged: (_) => setState(() {}),
          style: AppTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rp',
                    style: AppTypography.headlineSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Live Variance Status
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: reconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(reconIcon, color: reconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reconTitle,
                      style: AppTypography.labelMd.copyWith(
                        color: reconColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      reconDesc,
                      style: AppTypography.labelSm.copyWith(
                        color: reconColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Catatan Penutupan Shift
        Text(
          'Catatan Penutupan Shift / Keterangan Selisih',
          style: AppTypography.labelSm.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Semua struk transaksi klop, mesin kasir dibersihkan...',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Footer Buttons
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showReportPreview = !_showReportPreview;
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: _showReportPreview
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLow,
                  foregroundColor: _showReportPreview
                      ? AppColors.onPrimaryContainer
                      : AppColors.primaryStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  _showReportPreview
                      ? Icons.visibility_off_rounded
                      : Icons.print_rounded,
                  size: 19,
                ),
                label: Text(
                  _showReportPreview
                      ? 'Sembunyikan Struk'
                      : 'Cetak Laporan X/Z',
                  style: AppTypography.labelMd.copyWith(
                    color: _showReportPreview
                        ? AppColors.onPrimaryContainer
                        : AppColors.primaryStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.parentContext.read<ShiftCubit>().closeShift(
                            actualPhysicalCashIdr: actualCash,
                            notes: _notesController.text.trim(),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dangerBg,
                      foregroundColor: AppColors.errorStrong,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.lock_rounded, size: 19),
                    label: Text(
                      'Tutup Shift & Keluar',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.errorStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: scrollable
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: content,
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: content,
            ),
    );
  }

  /// Panel Kanan: Pratinjau Struk Laporan X / Z Thermal
  Widget _buildSideReportReceiptCard({
    required String outletName,
    required String cashierName,
    bool scrollable = true,
  }) {
    final activeShift = widget.activeShift;
    final actualCash = _actualCash;
    final expectedCash = activeShift.expectedCashIdr;
    final diffCash = actualCash - expectedCash;

    final now = DateTime.now();
    final docDateTag = DateFormat('yyyyMMdd').format(now);
    final docNo = _isReportZ
        ? '#RPT-Z-$docDateTag-001'
        : '#RPT-X-$docDateTag-001';
    final printedAt = DateFormat('dd MMM yyyy, HH:mm').format(now);

    int cashCount = 0;
    int qrisCount = 0;
    int debitTotal = 0;
    int debitCount = 0;
    int transferTotal = 0;
    int transferCount = 0;

    for (final tx in _shiftTransactions) {
      switch (tx.paymentMethod) {
        case 'qris':
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
          cashCount++;
      }
    }

    final cashTotal = activeShift.cashSalesIdr;
    final qrisTotal = activeShift.qrisSalesIdr;
    final nonCashTotal = qrisTotal + debitTotal + transferTotal;
    final totalNetSales = cashTotal + nonCashTotal;
    final totalStruk = _shiftTransactions.length;
    final baseFontSize = _paperWidthMm == 58 ? 10.5 : 11.5;

    final receiptPaper = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: _highlightReceipt
            ? Border.all(color: AppColors.primaryStrong, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: baseFontSize,
          height: 1.42,
          color: AppColors.onSurface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Text(
                  outletName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 15,
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
            const _ReceiptDashedLine(thick: true),
            Column(
              children: [
                Text(
                  _isReportZ
                      ? '*** LAPORAN Z - TUTUP SHIFT RESMI ***'
                      : '*** LAPORAN X - AUDIT BERJALAN ***',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: baseFontSize + 0.5,
                    color: _isReportZ
                        ? AppColors.primaryStrong
                        : AppColors.warningText,
                  ),
                ),
                Text(
                  _isReportZ
                      ? 'REGISTER DI-RESET KE COUNTER 0'
                      : 'KAS REGISTER TETAP BERJALAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize - 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const _ReceiptDashedLine(),
            _slipRow('No. Laporan:', docNo, boldValue: true),
            _slipRow('Kasir:', cashierName, boldValue: true),
            _slipRow('Waktu Cetak:', '$printedAt WIB'),
            const _ReceiptDashedLine(thick: true),
            Text(
              '[ 1. RINGKASAN PENJUALAN ]',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: baseFontSize - 0.5,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 3),
            _slipRow('Modal Awal (Float)',
                formatRupiah(activeShift.startingCashIdr)),
            _slipRow('Penjualan Tunai', formatRupiah(cashTotal)),
            _slipRow('Penjualan Non-Tunai', formatRupiah(nonCashTotal)),
            const _ReceiptDashedLine(),
            _slipRow(
              'TOTAL PENJUALAN BERSIH:',
              formatRupiah(totalNetSales),
              boldLabel: true,
              boldValue: true,
              valueColor: AppColors.primaryStrong,
            ),
            _slipRow('Total Struk:', '$totalStruk Struk'),
            const _ReceiptDashedLine(thick: true),
            Text(
              '[ 2. METODE PEMBAYARAN ]',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: baseFontSize - 0.5,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 3),
            if (_loadingTx)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              _slipRow('1. Tunai ($cashCount trx)', formatRupiah(cashTotal),
                  boldValue: true),
              _slipRow('2. QRIS ($qrisCount trx)', formatRupiah(qrisTotal),
                  boldValue: true),
              _slipRow('3. Debit ($debitCount trx)', formatRupiah(debitTotal)),
              _slipRow('4. Transfer ($transferCount trx)',
                  formatRupiah(transferTotal)),
            ],
            const _ReceiptDashedLine(thick: true),
            Text(
              '[ 3. REKONSILIASI KAS LACI ]',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: baseFontSize - 0.5,
                color: AppColors.primaryStrong,
              ),
            ),
            const SizedBox(height: 3),
            _slipRow('Ekspektasi Kas Sistem:', formatRupiah(expectedCash),
                boldValue: true),
            _slipRow('Kas Fisik Aktual:', formatRupiah(actualCash),
                boldValue: true),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: diffCash == 0
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
                      fontSize: baseFontSize - 0.5,
                      color: diffCash == 0
                          ? AppColors.primaryStrong
                          : AppColors.errorStrong,
                    ),
                  ),
                  Text(
                    diffCash == 0
                        ? 'Rp 0 [SEIMBANG]'
                        : '${diffCash > 0 ? '+' : ''}${formatRupiah(diffCash)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: baseFontSize - 0.5,
                      color: diffCash == 0
                          ? AppColors.primaryStrong
                          : AppColors.errorStrong,
                    ),
                  ),
                ],
              ),
            ),
            const _ReceiptDashedLine(thick: true),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Kasir,',
                            style: TextStyle(fontSize: baseFontSize - 1.5)),
                        const SizedBox(height: 24),
                        Text(
                          '( $cashierName )',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: baseFontSize - 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Supervisor,',
                            style: TextStyle(fontSize: baseFontSize - 1.5)),
                        const SizedBox(height: 24),
                        Text(
                          '( ............... )',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: baseFontSize - 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Struk Laporan
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: AppColors.primaryStrong,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pratinjau Struk Shift',
                        style: AppTypography.labelMd.copyWith(
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Toggle 80mm / 58mm
                    _miniPaperChip(
                      label: '80mm',
                      selected: _paperWidthMm == 80,
                      onTap: () => setState(() => _paperWidthMm = 80),
                    ),
                    const SizedBox(width: 4),
                    _miniPaperChip(
                      label: '58mm',
                      selected: _paperWidthMm == 58,
                      onTap: () => setState(() => _paperWidthMm = 58),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _showReportPreview = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Report X vs Z Switcher
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniReportTab(
                          label: 'Laporan X (Interim)',
                          selected: !_isReportZ,
                          onTap: () => setState(() => _isReportZ = false),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _miniReportTab(
                          label: 'Laporan Z (Final)',
                          selected: _isReportZ,
                          onTap: () => setState(() => _isReportZ = true),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Thermal Slip
          if (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: receiptPaper,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: receiptPaper,
            ),

          // Footer Print Controls
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: _handleTestPrint,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      foregroundColor: AppColors.primaryStrong,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bug_report_rounded, size: 17),
                    label: Text(
                      'Uji Cetak',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primaryStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _printing ? null : _handlePrintReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _printing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.print_rounded, size: 18),
                      label: Text(
                        _printing ? 'Mencetak...' : 'Cetak Struk',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPaperChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.labelXs.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _miniReportTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelXs.copyWith(
            color: selected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _slipRow(
    String left,
    String right, {
    bool boldLabel = false,
    bool boldValue = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              left,
              style: TextStyle(
                fontWeight: boldLabel ? FontWeight.w700 : FontWeight.w400,
                color: boldLabel
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            right,
            style: TextStyle(
              fontWeight: boldValue ? FontWeight.w700 : FontWeight.w400,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDashedLine extends StatelessWidget {
  final bool thick;
  const _ReceiptDashedLine({this.thick = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 6).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => SizedBox(
                width: 3.5,
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

Widget _ledgerRow({
  required String label,
  required String value,
  String? badge,
  Color? valueColor,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Text(
              '($badge)',
              style: AppTypography.labelXs.copyWith(
                color: AppColors.outline,
              ),
            ),
          ],
        ],
      ),
      Text(
        value,
        style: AppTypography.bodyMd.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: valueColor ?? AppColors.onSurface,
        ),
      ),
    ],
  );
}
