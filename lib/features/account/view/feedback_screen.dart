import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tourify_app/features/account/presenter/account_presenter.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presenter = context.watch<AccountPresenter>();
    return Scaffold(
      appBar: AppBar(title: const Text('Phản hồi Tourify')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (presenter.isSaving) const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chúng tôi rất mong nhận được góp ý của bạn!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hãy chia sẻ trải nghiệm, đề xuất hoặc vấn đề bạn gặp phải để Tourify ngày càng hoàn thiện hơn.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _controller,
                        minLines: 6,
                        maxLines: 12,
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung phản hồi...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập nội dung phản hồi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.send_rounded),
                          label: const Text('Gửi phản hồi'),
                          onPressed:
                              presenter.isSaving
                                  ? null
                                  : () => _submit(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final presenter = context.read<AccountPresenter>();
    final message = _controller.text.trim();
    final success = await presenter.submitFeedback(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Cảm ơn bạn đã gửi phản hồi!' : presenter.errorMessage,
        ),
      ),
    );
    if (success) {
      _controller.clear();
    }
  }
}
