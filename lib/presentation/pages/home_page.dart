import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/entities/task.dart';
import '../providers/auth_provider.dart';
import '../providers/basic_mode_provider.dart';
import '../providers/confirm_actions_provider.dart';
import '../providers/enhanced_feedback_provider.dart';
import '../providers/tasks_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final tasksAsync = ref.watch(tasksProvider);
    final basicMode = ref.watch(basicModeProvider);
    final theme = Theme.of(context);

    final displayName = authState.asData?.value?.displayName;
    final greeting = displayName != null ? 'Olá, $displayName' : 'Olá!';

    // Filtra apenas pendentes
    final pendingTasks =
        tasksAsync.asData?.value.where((t) => !t.completed).toList() ?? [];

    final completedCount =
        tasksAsync.asData?.value.where((t) => t.completed).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        actions: [
          if (completedCount > 0)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Ver concluídas ($completedCount)',
              onPressed: () => context.push('/concluidas'),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push('/configuracoes'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outlined),
            tooltip: 'Meu perfil',
            onPressed: () => context.push('/perfil'),
          ),
        ],
      ),
      body: tasksAsync.when(
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
        data: (_) => pendingTasks.isEmpty
            ? _EmptyState(
                onCreatePressed: () => _showCreateDialog(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: pendingTasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final task = pendingTasks[index];
                  return _TaskCard(
                    task: task,
                    basicMode: basicMode,
                    onToggle: () => _toggleTask(context, ref, task),
                    onDelete: () => _deleteTask(context, ref, task),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
        tooltip: 'Criar nova tarefa',
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateTaskSheet(ref: ref),
    );
  }

  Future<void> _toggleTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    // Dispara a escrita sem esperar — o stream reativo atualiza a UI
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

  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
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
