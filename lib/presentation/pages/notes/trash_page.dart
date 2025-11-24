// ignore_for_file: unnecessary_underscores, deprecated_member_use

import 'package:app_to_note/presentation/cubits/offline/offline_queqe_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../../domain/models/note.dart';
import '../../cubits/trash/trash_cubit.dart';
import '../../cubits/trash/trash_state.dart';

// Yeni ayırdığımız widgetlar
import 'trash_card.dart';
import 'trash_search_delegate.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  bool _selectMode = false;
  final Set<String> _selected = <String>{};

  void _enterSelectMode([String? id]) {
    setState(() {
      _selectMode = true;
      _selected.clear();
      if (id != null) _selected.add(id);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggleOne(String id) {
    setState(() {
      if (_selected.remove(id)) {
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<Note> list) {
    setState(() {
      _selectMode = true;
      _selected
        ..clear()
        ..addAll(list.map((e) => e.id));
    });
  }

  Future<void> _bulkRestore(TrashCubit cubit, List<Note> visibles) async {
    if (_selected.isEmpty) return;
    final ids = _selected.toList();
    for (final id in ids) {
      final n = visibles.firstWhere((e) => e.id == id);
      await cubit.restore(n);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${ids.length} not geri yüklendi')));
    _exitSelectMode();
  }

  Future<void> _bulkHardDelete(TrashCubit cubit, List<Note> visibles) async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Seçili notlar kalıcı olarak silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final ids = _selected.toList();
    for (final id in ids) {
      final n = visibles.firstWhere((e) => e.id == id);
      await cubit.hardDelete(n);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${ids.length} not kalıcı olarak silindi')),
    );
    _exitSelectMode();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrashCubit, TrashState>(
      builder: (context, state) {
        final cubit = context.read<TrashCubit>();

        Future<void> handleRefresh() async {
          try {
            await context.read<OfflineQueueCubit>().processAll();
          } catch (_) {}
          await cubit.refresh();
          await Future<void>.delayed(const Duration(milliseconds: 80));
        }

        // APP BAR
        final PreferredSizeWidget appBar = _selectMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: _exitSelectMode,
                ),
                title: Text(
                  '${_selected.length} seçildi',
                  style: const TextStyle(color: Colors.black87),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(70, 238, 180, 34),
                            Color.fromARGB(160, 220, 210, 200),
                            Color.fromARGB(70, 238, 180, 34),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.00),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => _selectAll(state.visible),
                    icon: const Icon(Icons.select_all, color: Colors.black54),
                    label: const Text(
                      'Tümünü Seç',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Seçiliyi geri yükle',
                    icon: const Icon(Icons.restore, color: Colors.black54),
                    onPressed: () => _bulkRestore(cubit, state.visible),
                  ),
                  IconButton(
                    tooltip: 'Seçiliyi kalıcı sil',
                    icon: const Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.black54,
                    ),
                    onPressed: () => _bulkHardDelete(cubit, state.visible),
                  ),
                ],
              )
            : AppBar(
                title: const Text(
                  'Çöp Kutusu',
                  style: TextStyle(color: Colors.black87),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Colors.black54),
                flexibleSpace: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(70, 238, 180, 34),
                            Color.fromARGB(160, 220, 210, 200),
                            Color.fromARGB(70, 238, 180, 34),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.18),
                            Colors.white.withOpacity(0.00),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black54),
                    onPressed: () async {
                      final q = await showSearch<String?>(
                        context: context,
                        delegate: TrashSearchDelegate(
                          state.visible,
                          initial: state.query,
                        ),
                      );
                      cubit.setQuery(q ?? '');
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.black54,
                    ),
                    tooltip: 'Çöp kutusunu boşalt',
                    onPressed: state.items.isEmpty
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Çöp kutusunu boşalt?'),
                                content: const Text(
                                  'Bu işlem tüm öğeleri kalıcı olarak silecektir.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('İptal'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Sil'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await cubit.emptyTrash();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Çöp kutusu boşaltıldı'),
                                ),
                              );
                            }
                          },
                  ),
                ],
              );

        // BODY (liste)
        final Widget listChild;
        if (state.visible.isEmpty) {
          listChild = ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: const [
              SizedBox(height: 240),
              Center(child: Text('Çöp kutusu boş')),
              SizedBox(height: 80),
            ],
          );
        } else {
          listChild = ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: state.visible.length,
            itemBuilder: (context, idx) {
              final n = state.visible[idx];
              final isSelected = _selected.contains(n.id);

              return TrashCard(
                note: n,
                selectMode: _selectMode,
                selected: isSelected,
                onLongPressSelect: () => _enterSelectMode(n.id),
                onToggleSelect: () => _toggleOne(n.id),
                onRestore: () => cubit.restore(n),
                onHardDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Kalıcı olarak silinsin mi?'),
                      content: const Text('Bu işlem geri alınamaz.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('İptal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sil'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) await cubit.hardDelete(n);
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(70, 238, 180, 34),
                  Color.fromARGB(160, 220, 210, 200),
                  Color.fromARGB(70, 238, 180, 34),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: switch (state.status) {
              TrashStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              TrashStatus.error => Center(child: Text(state.error ?? 'Hata')),
              _ => LiquidPullToRefresh(
                onRefresh: handleRefresh,
                showChildOpacityTransition: false,
                child: listChild,
              ),
            },
          ),
        );
      },
    );
  }
}
