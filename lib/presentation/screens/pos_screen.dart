import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../navigation/top_nav_bar.dart';
import '../widgets/menu_grid_widget.dart';
import '../widgets/order_sidebar_widget.dart';

class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
    Widget build(BuildContext context) {
      // TODO: implement build
      return const Scaffold(
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
              )
            ],
          )
        )
      );
    }
}
