import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isEditing = false;

  // Mock data
  final TextEditingController _nameController =
      TextEditingController(text: 'Nguyễn Văn A');
  String _gender = 'Nam';
  final String _phone = '0973973267';
  final String _email = 'nguyenvan.a@gmail.com';

  // Interests
  final List<String> _allInterests = [
    'Biển',
    'Núi',
    'Thành phố',
    'Văn hóa',
    'Ẩm thực',
    'Mua sắm',
    'Nghỉ dưỡng',
    'Thể thao mạo hiểm'
  ];
  final List<String> _selectedInterests = [
    'Biển',
    'Núi',
    'Văn hóa',
    'Ẩm thực',
  ];

  String _getIconForInterest(String interest) {
    switch (interest) {
      case 'Biển': return '🌴';
      case 'Núi': return '🏔️';
      case 'Thành phố': return '🏙️';
      case 'Văn hóa': return '🏛️';
      case 'Ẩm thực': return '🥣';
      case 'Mua sắm': return '🛍️';
      case 'Nghỉ dưỡng': return '💆';
      case 'Thể thao mạo hiểm': return '🧗';
      default: return '📍';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: CachedNetworkImage(
              imageUrl:
                  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
              fit: BoxFit.cover,
            ),
          ),

          // 2. AppBar (Over the image)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Hồ sơ',
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
                IconButton(
                  icon: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
                ),
              ],
            ),
          ),

          // 3. Content Area
          Positioned.fill(
            top: 180,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSizes.s24, 60, AppSizes.s24, AppSizes.s40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
                  children: [
                    // Profile Fields
                    _buildProfileField(
                      label: 'Tên hiển thị',
                      controller: _nameController,
                      isEditing: _isEditing,
                    ),
                    _buildGenderField(isEditing: _isEditing),
                    _buildReadOnlyField(
                      label: 'Số điện thoại',
                      value: _phone,
                      isEditing: _isEditing,
                    ),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: _email,
                      isEditing: _isEditing,
                    ),

                    const SizedBox(height: AppSizes.s32),

                    // Interests Section
                    Text(
                      'Sở thích du lịch',
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 20,
                        color: AppColorsExt.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSizes.s8),
                    Text(
                      'Giúp chúng tôi gợi ý chuyến đi phù hợp hơn cho bạn',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s16),

                    // Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: (_isEditing ? _allInterests : _selectedInterests)
                          .map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return _buildInterestChip(
                          icon: _getIconForInterest(interest),
                          label: interest,
                          isSelected: isSelected,
                          onTap: _isEditing
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedInterests.remove(interest);
                                    } else {
                                      _selectedInterests.add(interest);
                                    }
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Avatar (Overlapping everything)
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: const NetworkImage(
                    'https://i.pravatar.cc/150?u=user123',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (isEditing)
            TextField(
              controller: controller,
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                color: const Color(0xFF1A6EBD),
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            )
          else
            Text(
              controller.text,
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                color: AppColorsExt.profileBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderField({required bool isEditing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giới tính',
            style: AppTextStyles.caption.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (isEditing)
            Row(
              children: [
                _buildGenderOption('Nam'),
                const SizedBox(width: 16),
                _buildGenderOption('Nữ'),
              ],
            )
          else
            Text(
              _gender,
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                color: const Color(0xFF50B5D9),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label) {
    bool isSelected = _gender == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = label;
        });
      },
      child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s20, vertical: AppSizes.s8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required bool isEditing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (isEditing) ...[
                const SizedBox(width: 8),
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[400]),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              color: isEditing ? Colors.grey[400] : const Color(0xFF50B5D9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestChip({
    required String icon,
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColorsExt.chipActive : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.r24),
          border: Border.all(
            color: AppColorsExt.chipActive,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF113D3C),
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
