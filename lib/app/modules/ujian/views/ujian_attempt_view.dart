import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/exam_item.dart';
import '../../../models/exam_question.dart';
import '../../../models/exam_choice.dart';
import '../../../models/exam_attempt.dart';
import '../../../models/exam_answer.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../controllers/ujian_controller.dart';

class UjianAttemptView extends StatefulWidget {
  final ExamItem exam;

  const UjianAttemptView({super.key, required this.exam});

  @override
  State<UjianAttemptView> createState() => _UjianAttemptViewState();
}

class _UjianAttemptViewState extends State<UjianAttemptView> {
  final UjianController _controller = Get.find<UjianController>();
  final AuthService _authService = Get.find<AuthService>();
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, GlobalKey> _questionKeys = {};
  final ScrollController _scrollController = ScrollController();
  ExamAttempt? _attempt;
  List<ExamQuestion> _questions = [];
  Map<String, List<ExamChoice>> _choices = {};
  Map<String, ExamAnswer> _answers = {};
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final userId = _authService.user.value?.id;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _errorMessage = 'Sesi login tidak ditemukan.';
        _isLoading = false;
      });
      return;
    }
    final now = DateTime.now();
    if (now.isBefore(widget.exam.startAt) || now.isAfter(widget.exam.endAt)) {
      setState(() {
        _errorMessage = 'Ujian belum dibuka atau sudah berakhir.';
        _isLoading = false;
      });
      return;
    }
    try {
      await _controller.loadQuestions(widget.exam.id);
      final attempts = await _controller.loadAttempts(
        examId: widget.exam.id,
        userId: userId,
      );
      ExamAttempt? attempt;
      for (final item in attempts) {
        if (item.status == 'in_progress') {
          attempt = item;
          break;
        }
      }
      if (attempt == null) {
        final submittedAttempts =
            attempts.where((item) => item.status == 'submitted').length;
        if (submittedAttempts >= widget.exam.maxAttempts) {
          setState(() {
            _errorMessage = 'Percobaan ujian sudah habis.';
            _isLoading = false;
          });
          return;
        }
        attempt = await _controller.createAttempt(
          examId: widget.exam.id,
          userId: userId,
          attemptNumber: submittedAttempts + 1,
        );
      }
      final answers = await _controller.loadAnswers(attempt.id);
      _attempt = attempt;
      _questions = _controller.questions.toList();
      _choices = _groupChoices(_controller.choices.toList());
      _answers = {for (final item in answers) item.questionId: item};
      for (final question in _questions) {
        _questionKeys.putIfAbsent(question.id, () => GlobalKey());
      }
      for (final question in _questions) {
        if (question.type == 'essay') {
          final existing = _answers[question.id];
          _textControllers[question.id] = TextEditingController(
            text: existing?.answerText ?? '',
          );
        }
      }
      _startTimer();
      setState(() => _isLoading = false);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, List<ExamChoice>> _groupChoices(List<ExamChoice> items) {
    final map = <String, List<ExamChoice>>{};
    for (final item in items) {
      map.putIfAbsent(item.questionId, () => []);
      map[item.questionId]!.add(item);
    }
    return map;
  }

  void _startTimer() {
    _timer?.cancel();
    if (_attempt == null) {
      return;
    }
    final endAt = _attempt!.startedAt
        .add(Duration(minutes: widget.exam.durationMinutes));
    _remaining = endAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) {
        return;
      }
      final diff = endAt.difference(DateTime.now());
      if (diff.isNegative || diff == Duration.zero) {
        _timer?.cancel();
        setState(() => _remaining = Duration.zero);
        await _submit(auto: true);
        return;
      }
      setState(() => _remaining = diff);
    });
  }

  void _queueEssaySave(String questionId, String value) {
    _debounceTimers[questionId]?.cancel();
    _debounceTimers[questionId] = Timer(
      const Duration(milliseconds: 400),
      () => _saveAnswer(questionId: questionId, answerText: value),
    );
  }

  Future<void> _saveAnswer({
    required String questionId,
    String? choiceId,
    String? answerText,
  }) async {
    if (_attempt == null) {
      return;
    }
    await _controller.saveAnswer(
      attemptId: _attempt!.id,
      questionId: questionId,
      choiceId: choiceId,
      answerText: answerText,
    );
    final existing = _answers[questionId];
    _answers[questionId] = ExamAnswer(
      id: existing?.id ?? '',
      attemptId: _attempt!.id,
      questionId: questionId,
      choiceId: choiceId ?? existing?.choiceId,
      answerText: answerText ?? existing?.answerText,
      isCorrect: existing?.isCorrect,
      score: existing?.score,
    );
  }

  Future<void> _submit({bool auto = false}) async {
    if (_attempt == null || _isSubmitting) {
      return;
    }
    if (!auto) {
      final confirmed = await _confirmSubmit();
      if (!confirmed) {
        return;
      }
    }
    setState(() => _isSubmitting = true);
    String? error;
    try {
      error = await _controller.submitAttempt(
        exam: widget.exam,
        attempt: _attempt!,
        questions: _questions,
        choices: _controller.choices.toList(),
        answers: _answers.values.toList(),
      );
    } catch (err) {
      error = err.toString();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    if (!mounted) {
      return;
    }
    if (error != null) {
      Get.snackbar(
        'Gagal',
        error,
        backgroundColor: AppColors.navy,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    const snackDuration = Duration(seconds: 2);
    Get.snackbar(
      'Berhasil',
      auto ? 'Waktu ujian habis.' : 'Ujian berhasil disubmit.',
      backgroundColor: AppColors.navy,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: snackDuration,
    );
    await Future.delayed(snackDuration + const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }
    if (Get.key.currentState != null && Get.key.currentState!.canPop()) {
      Get.back(result: true);
      return;
    }
    Navigator.of(context, rootNavigator: true).pop(true);
  }

  Future<bool> _confirmSubmit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit ujian sekarang?'),
          content: const Text(
            'Pastikan semua jawaban sudah benar. Setelah submit, '
            'jawaban tidak bisa diubah.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ujian')),
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final timeLabel = _remaining == Duration.zero
        ? '00:00'
        : _formatDuration(_remaining);
    final totalQuestions = _questions.length;
    final answeredCount = _questions
        .where((q) {
          final answer = _answers[q.id];
          if (q.type == 'mcq') {
            return answer?.choiceId != null;
          }
          return answer?.answerText != null &&
              answer!.answerText!.trim().isNotEmpty;
        })
        .length;
    final isWide = MediaQuery.of(context).size.width >= 980;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  timeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final questionList = ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16, 16, 16, isWide ? 24 : 96),
            children: [
              _ExamHeader(
                answeredCount: answeredCount,
                totalQuestions: totalQuestions,
                durationMinutes: widget.exam.durationMinutes,
                startAt: widget.exam.startAt,
                endAt: widget.exam.endAt,
              ),
              const SizedBox(height: 16),
              ..._questions.map(
                (question) => _QuestionCard(
                  key: _questionKeys[question.id],
                  index: _questions.indexOf(question) + 1,
                  total: totalQuestions,
                  question: question,
                  choices: _choices[question.id] ?? const [],
                  selectedChoiceId: _answers[question.id]?.choiceId,
                  controller: _textControllers[question.id],
                  onChoiceSelected: (choiceId) =>
                      _saveAnswer(questionId: question.id, choiceId: choiceId),
                  onEssayChanged: (value) =>
                      _queueEssaySave(question.id, value),
                ),
              ),
            ],
          );

          if (!isWide) {
            return questionList;
          }
          return Row(
            children: [
              Expanded(child: questionList),
              SizedBox(
                width: 280,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 16, 24),
                  child: Column(
                    children: [
                      _SidebarCard(
                        title: 'Progress',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$answeredCount dari $totalQuestions terjawab',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: totalQuestions == 0
                                  ? 0
                                  : answeredCount / totalQuestions,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE8ECF5),
                              color: AppColors.navy,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SidebarCard(
                        title: 'Navigasi Soal',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            totalQuestions,
                            (index) {
                              final question = _questions[index];
                              final answered = question.type == 'mcq'
                                  ? _answers[question.id]?.choiceId != null
                                  : _answers[question.id]?.answerText
                                          ?.trim()
                                          .isNotEmpty ==
                                      true;
                              return GestureDetector(
                                onTap: () {
                                  final key = _questionKeys[question.id];
                                  if (key == null) {
                                    return;
                                  }
                                  final context = key.currentContext;
                                  if (context == null) {
                                    return;
                                  }
                                  Scrollable.ensureVisible(
                                    context,
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: answered
                                        ? AppColors.navy
                                        : const Color(0xFFE8ECF5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: answered
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                      _SidebarCard(
                        title: 'Submit',
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ||
                                    answeredCount != totalQuestions
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit Ujian'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMobileNav(
                        answeredCount: answeredCount,
                        totalQuestions: totalQuestions,
                      ),
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('Navigasi'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting || answeredCount != totalQuestions
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Ujian'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showMobileNav({
    required int answeredCount,
    required int totalQuestions,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '$answeredCount dari $totalQuestions terjawab',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalQuestions == 0
                      ? 0
                      : answeredCount / totalQuestions,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8ECF5),
                  color: AppColors.navy,
                ),
                const SizedBox(height: 16),
                Text(
                  'Navigasi Soal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    totalQuestions,
                    (index) {
                      final question = _questions[index];
                      final answered = question.type == 'mcq'
                          ? _answers[question.id]?.choiceId != null
                          : _answers[question.id]?.answerText
                                  ?.trim()
                                  .isNotEmpty ==
                              true;
                      return GestureDetector(
                        onTap: () {
                          final key = _questionKeys[question.id];
                          if (key == null) {
                            return;
                          }
                          final ctx = key.currentContext;
                          if (ctx == null) {
                            return;
                          }
                          Navigator.of(context).pop();
                          Scrollable.ensureVisible(
                            ctx,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: answered
                                ? AppColors.navy
                                : const Color(0xFFE8ECF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: answered
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final int total;
  final ExamQuestion question;
  final List<ExamChoice> choices;
  final String? selectedChoiceId;
  final TextEditingController? controller;
  final ValueChanged<String> onChoiceSelected;
  final ValueChanged<String> onEssayChanged;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.total,
    required this.question,
    required this.choices,
    required this.selectedChoiceId,
    required this.controller,
    required this.onChoiceSelected,
    required this.onEssayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$index/$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (question.type == 'mcq')
              ...choices.map(
                (choice) => _ChoiceTile(
                  label: choice.text,
                  isSelected: selectedChoiceId == choice.id,
                  onTap: () => onChoiceSelected(choice.id),
                ),
              )
            else
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Jawaban essay',
                  alignLabelWithHint: true,
                ),
                onChanged: onEssayChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.navy : const Color(0xFFE1E5F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.navy : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.navy : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamHeader extends StatelessWidget {
  final int answeredCount;
  final int totalQuestions;
  final int durationMinutes;
  final DateTime startAt;
  final DateTime endAt;

  const _ExamHeader({
    required this.answeredCount,
    required this.totalQuestions,
    required this.durationMinutes,
    required this.startAt,
    required this.endAt,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalQuestions == 0
        ? 0.0
        : answeredCount / totalQuestions;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Ujian',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderPill(
                label: 'Terjawab',
                value: '$answeredCount/$totalQuestions',
              ),
              _HeaderPill(
                label: 'Durasi',
                value: '$durationMinutes menit',
              ),
              _HeaderPill(
                label: 'Akses',
                value:
                    '${_formatDate(startAt)} - ${_formatDate(endAt)}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year $hour:$minute';
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFFDDE5F5),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SidebarCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
