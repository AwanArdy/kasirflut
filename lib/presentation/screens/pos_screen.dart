import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sync/sync_service.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/checkout/checkout_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../logic/update/update_cubit.dart';
import '../../utils/currency_formatter.dart';
import '../navigation/top_nav_bar.dart';
import '../widgets/menu_grid_widget.dart';
import '../widgets/order_sidebar_widget.dart';
import '../widgets/payment_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/shift_modals.dart';
import '../widgets/update_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  bool _isUpdateDialogOpen = false;

  void _maybeShowUpdateDialog(UpdateState state) {
    if (_isUpdateDialogOpen) return;
    if (state is UpdateAvailable && state.showDialogPrompt) {
      _isUpdateDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(
          release: state.release,
          onOpenSettings: () => showSettingsModal(context),
        ),
      ).whenComplete(() {
        if (mounted) {
          _isUpdateDialogOpen = false;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogCubit>().fetchCatalog();

      // Jika baru saja login dari modal Login + Buka Shift, langsung eksekusi openShift
      final pendingDraft = PendingShiftDraft.consume();
      if (pendingDraft != null) {
        context.read<ShiftCubit>().openShift(
              startingCashIdr: pendingDraft.startingCashIdr,
              shiftName: pendingDraft.shiftName,
              notes: pendingDraft.notes,
            );
      } else {
        context.read<ShiftCubit>().loadActiveShift();
      }

      context.read<SyncService>().startListening(
        onSynced: (result) {
          if (!mounted) return;
          if (result.syncedTransactions > 0 || result.syncedShifts > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Auto-sync: ${result.syncedTransactions} transaksi offline berhasil dikirim ke server.',
                ),
                backgroundColor: AppColors.primaryStrong,
              ),
            );
            context.read<ShiftCubit>().loadActiveShift();
          }
        },
      );

      _maybeShowUpdateDialog(context.read<UpdateCubit>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UpdateCubit, UpdateState>(
          listener: (context, state) {
            _maybeShowUpdateDialog(state);
          },
        ),
        BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) async {
            if (state is CheckoutSuccess) {
              context.read<CartCubit>().clearCart();
              context.read<ShiftCubit>().loadActiveShift();
              await showReceiptModal(context, state.transaction);
              if (context.mounted) {
                context.read<CheckoutCubit>().reset();
              }
            } else if (state is CheckoutError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
              context.read<CheckoutCubit>().reset();
            }
          },
        ),
        BlocListener<ShiftCubit, ShiftState>(
          listener: (context, state) {
            if (state is ShiftClosedSummary) {
              final s = state.closedShift;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shift ditutup (${s.status.toUpperCase()}). '
                    'Selisih kas: ${formatRupiah(s.differenceIdr ?? 0)}',
                  ),
                ),
              );
              // Tutup shift = otomatis logout
              context.read<AuthCubit>().logout();
            } else if (state is ShiftError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, shiftState) {
              // Wajib punya shift aktif; jika belum terbuka tampilkan backdrop POS blur + modal buka shift
              if (shiftState is! ShiftActive) {
                return const PosBlurredBackdrop(
                  child: OpenShiftModalCard(isLoginMode: false),
                );
              }

              return const Column(
                children: [
                  TopNavBar(),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: MenuGridWidget()),
                        OrderSidebarWidget(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
