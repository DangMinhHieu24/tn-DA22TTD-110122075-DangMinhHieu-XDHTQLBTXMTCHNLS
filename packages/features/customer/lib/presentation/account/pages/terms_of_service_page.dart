import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Điều khoản sử dụng',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF006E2F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF006E2F), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Điều Khoản & Chính Sách',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cập nhật lần cuối: 30/06/2026',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _buildSectionCard(
                    icon: Icons.gavel_rounded,
                    title: '1. Chấp thuận điều khoản',
                    content: 'Bằng việc đăng ký tài khoản và sử dụng dịch vụ trên ứng dụng Xanh EV Repair, bạn đồng ý tuân thủ tất cả các điều khoản, điều kiện và chính sách sử dụng được quy định tại đây. Nếu bạn không đồng ý, vui lòng ngừng sử dụng dịch vụ.',
                  ),
                  _buildSectionCard(
                    icon: Icons.person_pin_rounded,
                    title: '2. Quyền và Trách nhiệm của bạn',
                    content: 'Bạn cam kết cung cấp thông tin cá nhân và thông tin xe điện chính xác khi đăng ký tài khoản. Bạn chịu trách nhiệm bảo mật mật khẩu của mình và mọi hoạt động diễn ra dưới tài khoản của bạn. Tuyệt đối không tự ý can thiệp làm sai lệch dữ liệu định vị chỉ đường của hệ thống.',
                  ),
                  _buildSectionCard(
                    icon: Icons.verified_user_rounded,
                    title: '3. Cam kết dịch vụ từ Xanh EV Repair',
                    content: 'Chúng tôi nỗ lực cung cấp dịch vụ sửa chữa chất lượng cao, đúng hẹn và đúng báo giá. Xanh EV Repair cam kết sử dụng linh kiện chính hãng, bảo hành kỹ thuật theo tiêu chuẩn của nhà sản xuất xe điện.',
                  ),
                  _buildSectionCard(
                    icon: Icons.lock_outline_rounded,
                    title: '4. Chính sách bảo mật & Dữ liệu',
                    content: 'Chúng tôi thu thập dữ liệu định vị (GPS) chỉ khi có sự đồng ý của bạn và chỉ dùng để thực hiện chức năng dẫn đường từ vị trí của bạn tới trạm dịch vụ. Dữ liệu của bạn được mã hóa và bảo mật tuyệt đối, cam kết không cung cấp cho bên thứ ba vì mục đích thương mại.',
                  ),
                  _buildSectionCard(
                    icon: Icons.eco_rounded,
                    title: '5. Chương trình Cam kết Xanh',
                    content: 'Chúng tôi cam kết thay mặt bạn đóng góp 1 cây xanh tại Việt Nam cho mỗi đơn đặt lịch sửa chữa thành công. Điểm loyalty (điểm quà tặng) được tích lũy dựa trên số lần sửa chữa và có thể quy đổi sang các ưu đãi dịch vụ đặc biệt.',
                  ),
                ],
              ),
            ),

            // Bottom brand label
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco, color: const Color(0xFF006E2F).withValues(alpha: 0.6), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Xanh EV Repair - Vì hành tinh xanh',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF006E2F).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phiên bản 1.0.0 © 2026',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF006E2F).withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006E2F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF006E2F),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C1E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
