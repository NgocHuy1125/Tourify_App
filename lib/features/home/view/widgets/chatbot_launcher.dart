import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/home_models.dart';
import '../../presenter/home_presenter.dart';

class ChatbotLauncher extends StatelessWidget {
  const ChatbotLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final isBusy = context.select<HomePresenter, bool>(
      (presenter) => presenter.isSendingChat,
    );

    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          borderRadius: BorderRadius.circular(40),
        ),
        child: FloatingActionButton.extended(
          heroTag: 'chatbot_fab',
          backgroundColor: const Color(0xFF4E54C8),
          foregroundColor: Colors.white,
          onPressed: () => _openChatbot(context),
          icon: Icon(isBusy ? Icons.auto_awesome : Icons.smart_toy_outlined),
          label: Text(isBusy ? 'Đang phản hồi…' : 'Chat tư vấn'),
        ),
      ),
    );
  }

  Future<void> _openChatbot(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChatbotSheet(),
    );
  }
}

class _ChatbotSheet extends StatefulWidget {
  const _ChatbotSheet();

  @override
  State<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<_ChatbotSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 72,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend(HomePresenter presenter) async {
    final text = _controller.text.trim();
    if (text.isEmpty || presenter.isSendingChat) return;
    _controller.clear();
    await presenter.sendChatMessage(text, language: presenter.chatLanguage);
    if (mounted) _scrollToBottom();
  }

  void _prefillSample() {
    const sample =
        'Gợi ý giúp mình tour 3 ngày 2 đêm đi Đà Nẵng cho gia đình 4 người';
    setState(() {
      _controller.text = sample;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: sample.length),
      );
    });
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<HomePresenter>();
    final messages = presenter.chatMessages;
    final isSending = presenter.isSendingChat;
    final chatError = presenter.chatError;

    if (_lastMessageCount != messages.length) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.92,
              child: Material(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Column(
                    children: [
                      _ChatbotHeader(
                        hasHistory: messages.isNotEmpty,
                        onClear: messages.isEmpty ? null : presenter.clearChatSession,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: messages.isEmpty
                            ? _ChatEmptyState(onSample: _prefillSample)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: messages.length + (isSending ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= messages.length) {
                                    return const _TypingIndicator();
                                  }
                                  final message = messages[index];
                                  return _ChatBubble(message: message);
                                },
                              ),
                      ),
                      if (chatError.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  chatError,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _ChatInputBar(
                        controller: _controller,
                        focusNode: _inputFocusNode,
                        isSending: isSending,
                        onSend: () => _handleSend(presenter),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatbotHeader extends StatelessWidget {
  const _ChatbotHeader({
    required this.hasHistory,
    this.onClear,
  });

  final bool hasHistory;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.smart_toy_outlined, color: Color(0xFF4E54C8)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Chatbot tư vấn tour',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          if (hasHistory)
            TextButton(
              onPressed: onClear,
              child: const Text('Xóa hội thoại'),
            ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.onSample});

  final VoidCallback onSample;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF4F5FB),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: Color(0xFF4E54C8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn cần tư vấn tour nào?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hỏi chatbot về tour giảm giá, lịch khởi hành, chính sách hoặc gợi ý lịch trình phù hợp.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onSample,
              icon: const Icon(Icons.tips_and_updates_outlined),
              label: const Text('Gợi ý câu hỏi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            width: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFFFF5B00),
              ),
              onPressed: isSending ? null : onSend,
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = EdgeInsets.only(
      top: 6,
      bottom: 6,
      left: message.isUser ? 60 : 0,
      right: message.isUser ? 0 : 60,
    );
    final bubbleColor =
        message.isUser ? const Color(0xFFFF5B00) : Colors.grey.shade100;
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft:
                    Radius.circular(message.isUser ? 20 : 6),
                bottomRight:
                    Radius.circular(message.isUser ? 6 : 20),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          if (!message.isUser && message.sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nguồn tham khảo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                for (final source in message.sources) ...[
                  _SourceCard(source: source),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Đang phản hồi...'),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final ChatbotSource source;

  @override
  Widget build(BuildContext context) {
    final hasLink = source.url != null && source.url!.isNotEmpty;
    return InkWell(
      onTap: hasLink ? () => _openSource(context, source.url!) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasLink ? const Color(0xFF4E54C8) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: hasLink ? const Color(0xFF4E54C8) : Colors.black87,
              ),
            ),
            if (source.snippet != null && source.snippet!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                source.snippet!,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
            if (hasLink) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Mở nguồn',
                    style: TextStyle(
                      color: Color(0xFF4E54C8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 16, color: Color(0xFF4E54C8)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSource(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liên kết không hợp lệ.')),
        );
      }
      return;
    }
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết.')),
      );
    }
  }
}
