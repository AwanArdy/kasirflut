import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'core/sync/sync_service.dart';
import 'data/repositories/pos_repository.dart';
import 'data/repositories/update_repository.dart';
import 'logic/update/update_cubit.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/cart/cart_cubit.dart';
import 'logic/catalog/catalog_cubit.dart';
import 'logic/checkout/checkout_cubit.dart';
import 'logic/shift/shift_cubit.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/pos_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final posRepository = PosRepository(apiClient: apiClient);
  final syncService = SyncService(apiClient: apiClient);
  final updateRepository = UpdateRepository();

  runApp(
    KasirFlutApp(
      apiClient: apiClient,
      posRepository: posRepository,
      syncService: syncService,
      updateRepository: updateRepository
    ),
  );
}

class KasirFlutApp extends StatelessWidget {
  final ApiClient apiClient;
  final PosRepository posRepository;
  final SyncService syncService;
  final UpdateRepository updateRepository;


  const KasirFlutApp({
    super.key,
    required this.apiClient,
    required this.posRepository,
    required this.syncService,
    required this.updateRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SyncService>.value(value: syncService),
        RepositoryProvider<UpdateRepository>.value(value: updateRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(apiClient: apiClient)..checkSession(),
          ),
          BlocProvider<ShiftCubit>(
            create: (_) => ShiftCubit(repository: posRepository),
          ),
          BlocProvider<CatalogCubit>(
            create: (_) => CatalogCubit(repository: posRepository),
          ),
          BlocProvider<CartCubit>(
            create: (_) => CartCubit(),
          ),
          BlocProvider<CheckoutCubit>(
            create: (_) => CheckoutCubit(repository: posRepository),
          ),
          BlocProvider<UpdateCubit>(
            create: (_) => UpdateCubit(repository: updateRepository)
            ..checkOnAppStart(),
          ),
        ],
        child: MaterialApp(
          title: 'TeraturPOS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              error: AppColors.error,
            ),
            dividerTheme: const DividerThemeData(
              color: AppColors.outlineVariant,
              thickness: 1,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const PosScreen();
              }
              if (state is AuthInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
