import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../logic/auth/auth_cubit.dart';
import '../widgets/shift_modals.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          // Hapus draft buka shift jika login gagal
          PendingShiftDraft.consume();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: PosBlurredBackdrop(
          child: OpenShiftModalCard(isLoginMode: true),
        ),
      ),
    );
  }
}
