/// Một câu đố vui sau timeline (C3 / TASK-009). Xem `specs/api-contracts.md`.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explain;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    this.explain = '',
  });

  bool isCorrect(int index) => index == answerIndex;

  /// Hợp lệ: có câu hỏi + ≥2 lựa chọn + đáp án nằm trong phạm vi.
  bool get isValid =>
      question.isNotEmpty &&
      options.length >= 2 &&
      answerIndex >= 0 &&
      answerIndex < options.length;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: (json['question'] ?? '') as String,
        options: ((json['options'] as List?) ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(),
        answerIndex: (json['answer_index'] as num?)?.toInt() ?? 0,
        explain: (json['explain'] ?? '') as String,
      );
}
