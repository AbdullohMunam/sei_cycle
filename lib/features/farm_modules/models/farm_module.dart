import 'package:cloud_firestore/cloud_firestore.dart';

class FarmModule {
  const FarmModule({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.icon,
    required this.color,
    required this.isActive,
  });

  final String id;
  final String name;
  final String type;
  final String description;
  final String icon;
  final String color;
  final bool isActive;

  factory FarmModule.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return FarmModule(
      id: data['module_id'] as String? ?? document.id,
      name: data['module_name'] as String? ?? document.id,
      type: data['module_type'] as String? ?? document.id,
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'eco',
      color: data['color'] as String? ?? '#2D6A27',
      isActive: data['is_active'] as bool? ?? true,
    );
  }
}
