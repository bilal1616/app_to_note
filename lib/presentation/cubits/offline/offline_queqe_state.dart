import 'package:equatable/equatable.dart';

enum OfflineActionType { create, update, softDelete }

class OfflineAction extends Equatable {
  final OfflineActionType type;
  final Map<String, dynamic> payload; // {title, content} | {noteId, title?, content?, pinned?} | {noteId}

  const OfflineAction({required this.type, required this.payload});

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'payload': payload,
      };

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      type: OfflineActionType.values.firstWhere((e) => e.name == json['type']),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }

  @override
  List<Object?> get props => [type, payload];
}

class OfflineQueueState extends Equatable {
  final bool online;
  final List<OfflineAction> queue;

  const OfflineQueueState({
    this.online = true,
    this.queue = const [],
  });

  OfflineQueueState copyWith({
    bool? online,
    List<OfflineAction>? queue,
  }) {
    return OfflineQueueState(
      online: online ?? this.online,
      queue: queue ?? this.queue,
    );
  }

  Map<String, dynamic> toJson() => {
        'online': online,
        'queue': queue.map((e) => e.toJson()).toList(),
      };

  factory OfflineQueueState.fromJson(Map<String, dynamic> json) {
    return OfflineQueueState(
      online: (json['online'] as bool?) ?? true,
      queue: ((json['queue'] as List?) ?? [])
          .map((e) => OfflineAction.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [online, queue];
}
