import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/app_spacing.dart';
import '../../core/entities/task.dart';
import '../adaptive/constrained_content.dart';
import '../providers/confirm_actions_provider.dart';
import '../providers/enhanced_feedback_provider.dart';
import '../providers/tasks_provider.dart';

class CompletedTasksPage extends ConsumerWidget {
  const CompletedTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    final completedTasks =
        tasksAsync.asData?.value.where((t) => t.completed).toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas concluídas')),
      body: ConstrainedContent(
        child: tasksAsync.when(
          loading: () => Center(
            child: Semantics(
              label: 'Carregando tarefas concluídas',
              child: const CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => Center(
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Erro ao carregar tarefas',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          data: (_) => completedTasks.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.checklist,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.md),
                        Text(
                          'Nenhuma tarefa concluída ainda',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(spacing.md),
                  itemCount: completedTasks.length,
                  separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
                  itemBuilder: (context, index) {
                    final task = completedTasks[index];
                    return _CompletedTaskCard(
                      task: task,
                      onUncomplete: () => _uncompleteTask(context, ref, task),
                      onDelete: () => _deleteTask(context, ref, task),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _uncompleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    // Dispara a escrita sem esperar — o stream reativo atualiza a UI
    unawaited(ref.read(taskActionsProvider.notifier).toggleComplete(task));

    final enhanced = ref.read(enhancedFeedbackProvider);
    final message = '"${task.title}" voltou para pendentes';

    if (enhanced) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tarefa restaurada'),
          content: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.undo,
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

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({
    required this.task,
    required this.onUncomplete,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onUncomplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Semantics(
      label: '${task.title}. Concluída',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.xs,
            vertical: spacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  value: true,
                  onChanged: (_) => onUncomplete(),
                  semanticLabel: 'Desmarcar "${task.title}" como concluída',
                ),
              ),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
}
