import 'package:flutter/material.dart';
import 'package:auth/domain/entities/user.dart';

class ProfileHeader extends StatelessWidget {
  final User? user;
  final VoidCallback onLogout;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onLogout,
  });

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 24,
        24,
        36,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF006E2F),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user != null ? _initials(user!.name) : 'AD',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Quản trị viên',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.email ?? 'admin@xanhev.vn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    ..._buildPhoneSection(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(
                  label: 'MÃ NHÂN VIÊN',
                  value: user != null
                      ? '#${user!.id.substring(0, 8).toUpperCase()}'
                      : '#STAFF01',
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _buildDetailItem(
                  label: 'PHÂN QUYỀN',
                  value: user?.role == UserRole.staff
                      ? 'Quản trị viên'
                      : 'Nhân viên',
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                _buildDetailItem(
                  label: 'TRẠNG THÁI',
                  value: 'Đang hoạt động',
                  isStatus: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneSection() {
    final phone = user?.phoneNumber;
    if (phone == null || phone.isEmpty) return [];
    return [
      const SizedBox(height: 4),
      Text(
        phone,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      ),
    ];
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    bool isStatus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        if (isStatus)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF6BFF8F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6BFF8F),
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}
