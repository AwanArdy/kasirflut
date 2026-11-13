import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'core/sync/sync_service.dart';
import 'data/repositories/pos_repository.dart';
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

  runApp(
    KasirFlutApp(
      apiClient: apiClient,
      posRepository: posRepository,
      syncService: syncService,
    ),
  );
}

class KasirFlutApp extends StatelessWidget {
  final ApiClient apiClient;
  final PosRepository posRepository;
  final SyncService syncService;

  const KasirFlutApp({
    super.key,
    required this.apiClient,
    required this.posRepository,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<SyncService>.value(
      value: syncService,
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
        ],
        child: MaterialApp(
          title: 'TeraturPOS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              surface: AppColors.surface,
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
