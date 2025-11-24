import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/offline/offline_queqe_cubit.dart';
import '../cubits/offline/offline_queqe_state.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OfflineQueueCubit, OfflineQueueState>(
      buildWhen: (p, n) =>
          p.online != n.online || p.queue.length != n.queue.length,
      builder: (context, state) {
        final hasQueue = state.queue.isNotEmpty;
        final online = state.online;

        return Tooltip(
          message: online
              ? (hasQueue
                    ? 'Senkronize ediliyor… (${state.queue.length})'
                    : 'Senkronize edildi')
              : 'Offline',
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  online
                      ? (hasQueue ? Icons.sync : Icons.check_circle_outline)
                      : Icons.cloud_off,
                  size: 21,
                  color: online
                      ? (hasQueue
                            ? const Color.fromARGB(255, 196, 22, 10)
                            : Colors.black54)
                      : Color.fromARGB(255, 196, 22, 10),
                ),
                if (hasQueue)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.queue.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
