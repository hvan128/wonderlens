/// Một bước biến đổi trong game ghép ngược (C2 / TASK-012).
/// `from`/`to` là id vật liệu hoặc id vật (mắt cuối = chính vật đích).
class AssemblyStep {
  final String from;
  final String to;
  final String label;

  const AssemblyStep({
    required this.from,
    required this.to,
    this.label = '',
  });

  bool get isValid => from.isNotEmpty && to.isNotEmpty;

  factory AssemblyStep.fromJson(Map<String, dynamic> json) => AssemblyStep(
        from: (json['from'] ?? '') as String,
        to: (json['to'] ?? '') as String,
        label: (json['label'] ?? '') as String,
      );
}

/// Công thức ghép ngược một vật: kéo nguyên liệu theo đúng chuỗi để tạo ra vật.
/// Xem `specs/api-contracts.md`.
class Assembly {
  final String target;
  final List<AssemblyStep> steps;

  const Assembly({required this.target, required this.steps});

  bool get isValid => steps.isNotEmpty && steps.every((s) => s.isValid);

  factory Assembly.fromJson(Map<String, dynamic> json) => Assembly(
        target: (json['target'] ?? '') as String,
        steps: ((json['steps'] as List?) ?? const <dynamic>[])
            .map((e) => AssemblyStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
