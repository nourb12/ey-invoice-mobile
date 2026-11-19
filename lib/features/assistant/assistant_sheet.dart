import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_texts.dart';
import '../../core/theme/theme_extensions.dart';
import '../auth/controllers/session_controller.dart';
import 'assistant_api_service.dart';

/// Conversation kept only for the lifetime of the signed-in home screen.
class MobileAssistant extends StatefulWidget {
  const MobileAssistant({super.key, required this.messages});
  final List<Map<String, dynamic>> messages;
  @override
  State<MobileAssistant> createState() => _MobileAssistantState();
}

class _MobileAssistantState extends State<MobileAssistant> {
  final input = TextEditingController();
  final scroll = ScrollController();
  List<Map<String, dynamic>> get messages => widget.messages;
  bool busy = false;
  String? failedQuestion;
  final api = AssistantApiService();

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    api.close();
    super.dispose();
  }

  Future<void> send([String? retry]) async {
    final question = (retry ?? input.text).trim();
    if (question.isEmpty || busy) return;
    final token = context.read<SessionController>().session?.accessToken;
    if (token == null) return;
    final history = messages.where((m) => m['error'] != true).toList();
    if (retry != null &&
        history.isNotEmpty &&
        history.last['role'] == 'user' &&
        history.last['text'] == question) {
      history.removeLast();
    }
    setState(() {
      busy = true;
      failedQuestion = null;
      if (retry == null) messages.add({'role': 'user', 'text': question});
      input.clear();
    });
    try {
      final body = await api.ask(
        token: token,
        question: question,
        history: history,
      );
      if (!mounted) return;
      setState(
        () => messages.add({
          'role': 'assistant',
          'text': body['answer'] ?? '',
          'sources': body['sources'] ?? [],
        }),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => failedQuestion = question);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) {
            scroll.animateTo(
              scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final texts = AppTexts.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: context.ey.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height:
                (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    MediaQuery.paddingOf(context).vertical) *
                .78,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          texts.t('assistant.title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: texts.t('common.close'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: scroll,
                      children: [
                        if (messages.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(texts.t('assistant.greeting')),
                          ),
                        ...messages.map(
                          (m) => Align(
                            alignment: m['role'] == 'user'
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SelectableText(m['text'] as String),
                                  if (m['sources'] is List &&
                                      (m['sources'] as List).isNotEmpty)
                                    ExpansionTile(
                                      title: Text(texts.t('assistant.sources')),
                                      children: [
                                        for (final source
                                            in m['sources'] as List)
                                          ListTile(
                                            title: Text(
                                              '${source['title'] ?? ''}',
                                            ),
                                            subtitle: Text(
                                              '${source['heading'] ?? ''}\n${source['excerpt'] ?? ''}',
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (busy) const LinearProgressIndicator(),
                        if (failedQuestion != null)
                          TextButton(
                            onPressed: () => send(failedQuestion),
                            child: Text(texts.t('assistant.retry')),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          maxLength: 1500,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: texts.t('assistant.question'),
                            counterText: '',
                          ),
                          onSubmitted: (_) => send(),
                        ),
                      ),
                      IconButton(
                        tooltip: texts.t('assistant.send'),
                        onPressed: busy ? null : () => send(),
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
