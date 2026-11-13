import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sync/sync_service.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/checkout/checkout_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';
import '../navigation/top_nav_bar.dart';
import '../widgets/menu_grid_widget.dart';
import '../widgets/order_sidebar_widget.dart';
import '../widgets/payment_modal.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogCubit>().fetchCatalog();
      context.read<ShiftCubit>().loadActiveShift();
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
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
              context.read<ShiftCubit>().loadActiveShift();
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
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
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
          ),
        ),
      ),
    );
  }
}
