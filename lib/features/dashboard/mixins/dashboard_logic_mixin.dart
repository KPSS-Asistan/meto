import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kpss_2026/core/services/last_study_service.dart';
import '../cubit/dashboard_cubit.dart';

mixin DashboardLogicMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  Future<Map<String, dynamic>?>? lastStudyFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    lastStudyFuture = LastStudyService.getLastStudy();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) context.read<DashboardCubit>().refreshStats();
    }
  }
}
