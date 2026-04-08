import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/entities/task.dart';
import '../adaptive/adaptive_scaffold.dart';
import '../adaptive/constrained_content.dart';
import '../providers/auth_provider.dart';
import '../providers/basic_mode_provider.dart';
import '../providers/confirm_actions_provider.dart';
import '../providers/enhanced_feedback_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/tutorial_seen_provider.dart';
import '../providers/user_preferences_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  /// GlobalKeys compartilhadas para os itens de navegação.
  /// Usadas pelo router (AdaptiveScaffold) e pelo tutorial.
  static final navKeys = <int, GlobalKey>{
    0: GlobalKey(debugLabel: 'nav_inicio'),
    1: GlobalKey(debugLabel: 'nav_concluidas'),
    2: GlobalKey(debugLabel: 'nav_settings'),
    3: GlobalKey(debugLabel: 'nav_profile'),
  };

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // GlobalKeys para o tutorial
  final _fabKey = GlobalKey();
  bool _tutorialChecked = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final basicMode = ref.watch(basicModeProvider);
    final tutorialSeen = ref.watch(tutorialSeenProvider);
    final theme = Theme.of(context);

    // Auto-mostra o tutorial na primeira visita, após os dados carregarem
    if (!_tutorialChecked && !tutorialSeen && tasksAsync is! AsyncLoading) {
      _tutorialChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }

    final displayName = authState.asData?.value?.displayName;
    final greeting = displayName != null ? 'Olá, $displayName' : 'Olá!';

    // Filtra apenas pendentes
    final pendingTasks =
        tasksAsync.asData?.value.where((t) => !t.completed).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Como usar o app',
            onPressed: _showTutorial,
          ),
        ],
      ),
      body: ConstrainedContent(
        child: tasksAsync.when(
          loading: () => Center(
            child: Semantics(
              label: 'Carregando tarefas',
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(
            child: Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar tarefas',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (_) {
            if (pendingTasks.isEmpty) {
              return _EmptyState(onCreatePressed: () => _showCreateDialog());
            }

            // Modo básico: lista plana simples
            if (basicMode) {
              final overdue = pendingTasks
                  .where((t) => _getUrgency(t.dueDate) == _Urgency.overdue)
                  .toList();
              final rest = pendingTasks
                  .where((t) => _getUrgency(t.dueDate) != _Urgency.overdue)
                  .toList();
              final sorted = [...overdue, ...rest];

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: sorted.length + (overdue.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (overdue.isNotEmpty && index == 0) {
                    return _OverdueWarning(count: overdue.length);
                  }
                  final task = sorted[overdue.isNotEmpty ? index - 1 : index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TaskCard(
                      task: task,
                      basicMode: basicMode,
                      onToggle: () => _toggleTask(task),
                      onDelete: () => _deleteTask(task),
                    ),
                  );
                },
              );
            }

            // Modo avançado: lista com seções
            final overdueTasks = pendingTasks
                .where((t) => _getUrgency(t.dueDate) == _Urgency.overdue)
                .toList();
            final todayTasks = pendingTasks
                .where((t) => _getUrgency(t.dueDate) == _Urgency.today)
                .toList();
            final otherTasks = pendingTasks.where((t) {
              final u = _getUrgency(t.dueDate);
              return u != _Urgency.overdue && u != _Urgency.today;
            }).toList();

            return _SectionedTaskList(
              overdueTasks: overdueTasks,
              todayTasks: todayTasks,
              otherTasks: otherTasks,
              basicMode: basicMode,
              onToggle: _toggleTask,
              onDelete: _deleteTask,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: _fabKey,
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
        tooltip: 'Criar nova tarefa',
      ),
    );
  }

  // ---------- Tutorial ----------

  void _showTutorial() {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge!.copyWith(color: Colors.white);

    final navKeys = HomePage.navKeys;

    // No mobile (compact) a nav fica embaixo → texto vai para cima.
    // Na web (expanded) a nav fica na lateral → texto vai para a direita.
    final breakpoint = getBreakpoint(MediaQuery.sizeOf(context).width);
    final isCompact = breakpoint == LayoutBreakpoint.compact;
    final navContentAlign = isCompact ? ContentAlign.top : ContentAlign.right;

    // Mobile: padding maior para cobrir ícone + label da aba
    final navPadding = isCompact ? 40.0 : 15.0;

    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'fab',
        keyTarget: _fabKey,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => _TutorialStep(
              text:
                  'Toque aqui para criar uma nova tarefa.\n'
                  'Você pode definir o título, a prioridade '
                  'e uma data de vencimento.',
              textStyle: textStyle,
              step: '1 de 5',
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'inicio',
        keyTarget: navKeys[0]!,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: navPadding,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: navContentAlign,
            builder: (context, controller) => _TutorialStep(
              text:
                  'Esta é a tela Início, onde ficam '
                  'todas as suas tarefas pendentes.',
              textStyle: textStyle,
              step: '2 de 5',
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'concluidas',
        keyTarget: navKeys[1]!,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: navPadding,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: navContentAlign,
            builder: (context, controller) => _TutorialStep(
              text:
                  'Veja aqui todas as tarefas que você '
                  'já concluiu.',
              textStyle: textStyle,
              step: '3 de 5',
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'settings',
        keyTarget: navKeys[2]!,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: navPadding,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: navContentAlign,
            builder: (context, controller) => _TutorialStep(
              text:
                  'Personalize o app: tamanho de texto, '
                  'contraste, espaçamento e muito mais.',
              textStyle: textStyle,
              step: '4 de 5',
              onNext: controller.next,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'profile',
        keyTarget: navKeys[3]!,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        paddingFocus: navPadding,
        alignSkip: Alignment.topCenter,
        contents: [
          TargetContent(
            align: navContentAlign,
            builder: (context, controller) => _TutorialStep(
              text: 'Acesse e edite seus dados pessoais.',
              textStyle: textStyle,
              step: '5 de 5',
              isLast: true,
              onNext: controller.next,
            ),
          ),
        ],
      ),
    ];

    final tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      hideSkip: true,
      onClickTarget: (target) {
        _announceStep(target.identify as String);
      },
      onFinish: _markTutorialSeen,
      onSkip: () {
        _markTutorialSeen();
        return true;
      },
    );

    tutorial.show(context: context, rootOverlay: true);

    // Anuncia o primeiro passo
    SemanticsService.sendAnnouncement(
      View.of(context),
      'Tutorial iniciado. Passo 1 de 5: botão nova tarefa.',
      TextDirection.ltr,
    );
  }

  void _markTutorialSeen() {
    ref.read(tutorialSeenProvider.notifier).set(seen: true);
    final prefs = ref.read(userPreferencesProvider).asData?.value;
    if (prefs != null) {
      ref
          .read(userPreferencesProvider.notifier)
          .save(prefs.copyWith(tutorialSeen: true));
    }
  }

  void _announceStep(String identify) {
    final announcement = switch (identify) {
      'fab' => 'Passo 2 de 5: início.',
      'inicio' => 'Passo 3 de 5: concluídas.',
      'concluidas' => 'Passo 4 de 5: configurações.',
      'settings' => 'Passo 5 de 5: perfil.',
      _ => 'Tutorial concluído.',
    };

    SemanticsService.sendAnnouncement(
      View.of(context),
      announcement,
      TextDirection.ltr,
    );
  }

  // ---------- Ações ----------

  void _showCreateDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateTaskSheet(ref: ref),
    );
  }

  Future<void> _toggleTask(Task task) async {
    unawaited(ref.read(taskActionsProvider.notifier).toggleComplete(task));

    final enhanced = ref.read(enhancedFeedbackProvider);
    final message = 'Tarefa "${task.title}" concluída!';

    if (enhanced) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tarefa concluída'),
          content: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.check_circle,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmActions = ref.read(confirmActionsProvider);
    final message = 'Tarefa "${task.title}" excluída';
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final view = View.of(context);

    if (confirmActions) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Excluir tarefa?'),
          content: Text('Deseja excluir "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    unawaited(ref.read(taskActionsProvider.notifier).delete(task.id));

    scaffoldMessenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));

    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }
}

// ---------- Passo do tutorial ----------

class _TutorialStep extends StatelessWidget {
  const _TutorialStep({
    required this.text,
    required this.textStyle,
    required this.step,
    required this.onNext,
    this.isLast = false,
  });

  final String text;
  final TextStyle textStyle;
  final String step;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: textStyle),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step,
                style: textStyle.copyWith(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: onNext,
                  child: Text(isLast ? 'Concluir' : 'Próximo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- Aviso simples para modo básico ----------

class _OverdueWarning extends StatelessWidget {
  const _OverdueWarning({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text =
        'Você tem $count tarefa${count > 1 ? 's' : ''} atrasada${count > 1 ? 's' : ''}';

    return Semantics(
      liveRegion: true,
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Lista com seções ----------

class _SectionedTaskList extends StatelessWidget {
  const _SectionedTaskList({
    required this.overdueTasks,
    required this.todayTasks,
    required this.otherTasks,
    required this.basicMode,
    required this.onToggle,
    required this.onDelete,
  });

  final List<Task> overdueTasks;
  final List<Task> todayTasks;
  final List<Task> otherTasks;
  final bool basicMode;
  final Future<void> Function(Task) onToggle;
  final Future<void> Function(Task) onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (overdueTasks.isNotEmpty)
          _TaskSection(
            icon: Icons.warning_amber_rounded,
            title: 'Atrasadas (${overdueTasks.length})',
            type: _SectionType.overdue,
            tasks: overdueTasks,
            basicMode: basicMode,
            onToggle: onToggle,
            onDelete: onDelete,
          ),
        if (todayTasks.isNotEmpty)
          _TaskSection(
            icon: Icons.today,
            title: 'Hoje (${todayTasks.length})',
            type: _SectionType.today,
            tasks: todayTasks,
            basicMode: basicMode,
            onToggle: onToggle,
            onDelete: onDelete,
          ),
        if (otherTasks.isNotEmpty)
          _TaskSection(
            icon: Icons.checklist,
            title: 'Próximas (${otherTasks.length})',
            type: _SectionType.normal,
            tasks: otherTasks,
            basicMode: basicMode,
            onToggle: onToggle,
            onDelete: onDelete,
          ),
      ],
    );
  }
}

enum _SectionType { overdue, today, normal }

class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.icon,
    required this.title,
    required this.type,
    required this.tasks,
    required this.basicMode,
    required this.onToggle,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final _SectionType type;
  final List<Task> tasks;
  final bool basicMode;
  final Future<void> Function(Task) onToggle;
  final Future<void> Function(Task) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (bgColor, fgColor, borderColor) = switch (type) {
      _SectionType.overdue => (
        theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        theme.colorScheme.onErrorContainer,
        theme.colorScheme.error,
      ),
      _SectionType.today => (
        theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        theme.colorScheme.onPrimaryContainer,
        theme.colorScheme.primary,
      ),
      _SectionType.normal => (
        Colors.transparent,
        theme.colorScheme.onSurface,
        Colors.transparent,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != Colors.transparent
              ? Border.all(color: borderColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Padding(
          padding: type != _SectionType.normal
              ? const EdgeInsets.fromLTRB(12, 12, 12, 8)
              : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da seção
              Semantics(
                header: true,
                liveRegion: type == _SectionType.overdue,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: fgColor),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: fgColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Cards das tarefas
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskCard(
                    task: task,
                    basicMode: basicMode,
                    onToggle: () => onToggle(task),
                    onDelete: () => onDelete(task),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Estado vazio ----------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.task_alt,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma tarefa pendente',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no botão abaixo para criar sua primeira tarefa.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Criar tarefa'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Card de tarefa ----------

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.basicMode,
    required this.onToggle,
    required this.onDelete,
  });

  final Task task;
  final bool basicMode;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgency = _getUrgency(task.dueDate);

    return Semantics(
      button: false,
      label: _buildSemanticLabel(urgency),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: basicMode && urgency == _Urgency.overdue
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              // Checkbox de conclusão
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  value: false,
                  onChanged: (_) => onToggle(),
                  semanticLabel: 'Marcar "${task.title}" como concluída',
                ),
              ),
              const SizedBox(width: 4),
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!basicMode) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _PriorityChip(priority: task.priority),
                          if (task.dueDate != null)
                            _DueDateChip(
                              dueDate: task.dueDate!,
                              urgency: urgency,
                            ),
                        ],
                      ),
                    ],
                    if (basicMode && urgency == _Urgency.overdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Atrasada',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Botão excluir
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Excluir tarefa',
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel(_Urgency urgency) {
    final parts = <String>[task.title];
    if (!basicMode) {
      parts.add('Prioridade ${task.priority.label}');
      if (task.dueDate != null) {
        parts.add(_formatDueDate(task.dueDate!));
        if (urgency == _Urgency.overdue) {
          parts.add('Atrasada');
        } else if (urgency == _Urgency.today) {
          parts.add('Vence hoje');
        }
      }
    }
    return parts.join('. ');
  }
}

// ---------- Chips de prioridade e data ----------

enum _Urgency { overdue, today, soon, normal }

_Urgency _getUrgency(DateTime? dueDate) {
  if (dueDate == null) return _Urgency.normal;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

  if (due.isBefore(today)) return _Urgency.overdue;
  if (due.isAtSameMomentAs(today)) return _Urgency.today;
  if (due.difference(today).inDays <= 2) return _Urgency.soon;
  return _Urgency.normal;
}

String _formatDueDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(date.year, date.month, date.day);
  final diff = due.difference(today).inDays;

  if (diff < 0) return 'Atrasada ${-diff} dia${diff == -1 ? '' : 's'}';
  if (diff == 0) return 'Vence hoje';
  if (diff == 1) return 'Vence amanhã';
  return 'Vence em $diff dias';
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (priority) {
      TaskPriority.high => (theme.colorScheme.error, Icons.arrow_upward),
      TaskPriority.medium => (theme.colorScheme.tertiary, Icons.remove),
      TaskPriority.low => (
        theme.colorScheme.onSurface.withValues(alpha: 0.5),
        Icons.arrow_downward,
      ),
    };

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.dueDate, required this.urgency});

  final DateTime dueDate;
  final _Urgency urgency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _formatDueDate(dueDate);
    final color = switch (urgency) {
      _Urgency.overdue => theme.colorScheme.error,
      _Urgency.today => theme.colorScheme.error,
      _Urgency.soon => theme.colorScheme.tertiary,
      _Urgency.normal => theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: urgency == _Urgency.overdue ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Sheet de criação ----------

class _CreateTaskSheet extends ConsumerStatefulWidget {
  const _CreateTaskSheet({required this.ref});

  final WidgetRef ref;

  @override
  ConsumerState<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<_CreateTaskSheet> {
  final _titleController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final basicMode = ref.watch(basicModeProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nova tarefa', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),

          // Título
          TextField(
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'O que precisa fazer?',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),

          if (!basicMode) ...[
            const SizedBox(height: 20),

            // Prioridade
            Text('Prioridade', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(
                  value: TaskPriority.low,
                  label: Text('Baixa'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TaskPriority.medium,
                  label: Text('Média'),
                  icon: Icon(Icons.remove),
                ),
                ButtonSegment(
                  value: TaskPriority.high,
                  label: Text('Alta'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (v) => setState(() => _priority = v.first),
            ),

            const SizedBox(height: 16),

            // Data de vencimento
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dueDate != null
                    ? 'Vence: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                    : 'Definir data de vencimento',
              ),
            ),
            if (_dueDate != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _dueDate = null),
                  child: const Text('Remover data'),
                ),
              ),
          ],

          const SizedBox(height: 24),

          // Botão salvar
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? 'Salvando...' : 'Criar tarefa'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: 'Quando esta tarefa vence?',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    try {
      final task = Task.create(
        id: '', // Firestore gerará o ID
        title: title,
        priority: _priority,
        userId: '', // Provider preencherá via _getUid
        dueDate: _dueDate,
      );

      await ref.read(taskActionsProvider.notifier).create(task);

      if (!mounted) return;
      Navigator.of(context).pop();

      final enhanced = ref.read(enhancedFeedbackProvider);
      final message = 'Tarefa "$title" criada!';

      if (enhanced) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tarefa criada'),
            content: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.check_circle,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
      }

      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Erro ao criar tarefa')));
    }
  }
}
