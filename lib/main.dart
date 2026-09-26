import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_client.dart';
import 'logic/cart/cart_cubit.dart';
import 'logic/catalog/catalog_cubit.dart';
import 'logic/checkout/checkout_cubit.dart';
import 'logic/shift/shift_cubit.dart';
import 'presentation/screens/pos_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();

  runApp(kasirflut(apiClient: apiClient));
}

class kasirflut extends StatelessWidget {
  final ApiClient apiClient;

  const kasirflut({super.key, required this.apiClient});

  @override
    Widget build(BuildContext context) {
      // TODO: implement build
      return MultiBlocProvider(
        providers: [
          BlocProvider<ShiftCubit>(
            create: (_) => ShiftCubit(apiClient: apiClient),
          ),
          BlocProvider<CatalogCubit>(
            create: (_) => CatalogCubit(apiClient: apiClient)..fetchCatalog(),
          ),
          BlocProvider<CartCubit>(
            create: (_) => CartCubit(),
          ),
          BlocProvider<CheckoutCubit>(
            create: (_) => CheckoutCubit(apiClient: apiClient),
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
              surface: AppColors.surface
            ),
          ),
          home: const PosScreen(),
        ),
      );
    }
}
