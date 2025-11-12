import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTourifyScreen extends StatelessWidget {
  const AboutTourifyScreen({super.key});

  static final Uri _websiteUri = Uri.parse('https://trip-curate.vercel.app/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Về Tourify')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E54C8), Color(0xFF8F94FB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tourify',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nền tảng đặt tour thông minh giúp bạn khám phá thế giới dễ dàng hơn với trải nghiệm cá nhân hóa, gợi ý nổi bật và ưu đãi hấp dẫn.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sứ mệnh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Chúng tôi mong muốn mang đến hành trình trọn vẹn cho mỗi khách hàng qua việc kết nối với các đối tác du lịch uy tín, gợi ý tour phù hợp và hỗ trợ tận tâm trong suốt chuyến đi.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            const Text(
              'Khám phá thêm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF4E54C8)),
                title: const Text('Trang web chính thức'),
                subtitle: const Text('https://trip-curate.vercel.app/'),
                trailing: const Icon(Icons.open_in_new),
                onTap: _openWebsite,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Theo dõi Tourify để cập nhật những ưu đãi mới nhất và câu chuyện hành trình truyền cảm hứng mỗi ngày.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openWebsite() async {
    if (await canLaunchUrl(_websiteUri)) {
      await launchUrl(_websiteUri, mode: LaunchMode.externalApplication);
    }
  }
}
