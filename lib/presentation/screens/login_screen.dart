import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/storage/session_storage.dart';
import '../../logic/auth/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'kasir@teratur.id');
  final _passwordController = TextEditingController(text: 'password123');
  final _serverController =
      TextEditingController(text: SessionStorage.defaultBaseUrl);
  bool _obscurePassword = true;
  bool _showServerField = false;

  @override
  void initState() {
    super.initState();
    SessionStorage().getBaseUrl().then((url) {
      if (mounted) _serverController.text = url;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthCubit>().login(
          email: _emailController.text,
          password: _passwordController.text,
          serverUrl: _serverController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 860;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(flex: 5, child: _buildBrandPanel()),
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildLoginCard(),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildLoginCard(),
                ),
              ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.20),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.onPrimary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TERATUR POS',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primaryStrong,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Operasional Kasir\nLebih Cepat & Teratur.',
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.onPrimaryContainer,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Catat pesanan, kelola shift kas, dan sinkronkan transaksi secara otomatis bahkan saat koneksi terputus.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              _featureItem(
                Icons.flash_on_rounded,
                'Checkout Instan',
                'Pilih menu, atur tipe order, dan hitung kembalian otomatis.',
              ),
              const SizedBox(height: 14),
              _featureItem(
                Icons.cloud_sync_rounded,
                'Mode Offline-First',
                'Transaksi tetap aman di SQLite lokal dan tersinkron otomatis.',
              ),
              const SizedBox(height: 14),
              _featureItem(
                Icons.account_balance_wallet_rounded,
                'Kontrol Shift Akurat',
                'Pantau modal awal dan selisih kas laci di setiap pergantian shift.',
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryStrong, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimaryContainer,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: 430,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: AppColors.onPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masuk Kasir',
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sinkronisasi menu & transaksi outlet',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Email Akun', style: AppTypography.labelSm),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'kasir@teratur.id',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text('Password', style: AppTypography.labelSm),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _showServerField = !_showServerField),
                  icon: Icon(
                    _showServerField
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.tune_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _showServerField
                        ? 'Sembunyikan Server URL'
                        : 'Atur Server URL',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryStrong,
                  ),
                ),
              ),
              if (_showServerField) ...[
                const SizedBox(height: 4),
                Text('API Base URL', style: AppTypography.labelSm),
                const SizedBox(height: 6),
                TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    hintText: 'http://10.0.2.2:3000/api/v1',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
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
                            Text(
                              'Masuk Kasir',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
