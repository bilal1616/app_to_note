// lib/presentation/core/connectivity_binder.dart
import 'dart:async';
import 'package:app_to_note/presentation/cubits/offline/offline_queqe_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/repositories/notes_repository.dart';

/// Bağlantı değişimini dinler; online olunca OfflineQueue'yu flush eder.
class ConnectivityBinder extends StatefulWidget {
  final NotesRepository repo;
  final Widget child;

  const ConnectivityBinder({
    super.key,
    required this.repo,
    required this.child,
  });

  @override
  State<ConnectivityBinder> createState() => _ConnectivityBinderState();
}

class _ConnectivityBinderState extends State<ConnectivityBinder> {
  final _conn = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool? _lastOnline;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _sub = _conn.onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _bootstrap() async {
    // ✅ Yeni API: List<ConnectivityResult> döner
    final first = await _conn.checkConnectivity();
    await _handle(first, initial: true);
  }

  Future<void> _onChanged(List<ConnectivityResult> results) =>
      _handle(results, initial: false);

  Future<void> _handle(
    List<ConnectivityResult> results, {
    required bool initial,
  }) async {
    final online = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );

    final queue = context.read<OfflineQueueCubit>();
    queue.setOnline(online);

    final switchedToOnline = online && (_lastOnline != true);
    _lastOnline = online;

    // İlk açılışta online isek veya offline->online geçişinde flush
    if ((initial && online) || switchedToOnline) {
      await queue.processAll(widget.repo);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
