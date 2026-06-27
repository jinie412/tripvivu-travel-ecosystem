import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:travel_advisor_mobile/core/constants/app_colors.dart';
import 'package:travel_advisor_mobile/core/constants/app_sizes.dart';
import 'package:travel_advisor_mobile/core/theme/app_theme.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:travel_advisor_mobile/features/profile/presentation/cubit/profile_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _hasSyncedInitialProfile = false;
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  String _gender = '';
  String _phoneNumber = '';
  String _email = '';
  String _avatarUrl = '';

  // Interests
  final List<String> _allInterests = [
    'Biển',
    'Núi',
    'Thành phố',
    'Văn hóa',
    'Ẩm thực',
    'Mua sắm',
    'Nghỉ dưỡng',
    'Thể thao mạo hiểm',
  ];
  List<String> _selectedInterests = [];

  String _getIconForInterest(String interest) {
    switch (interest) {
      case 'Biển':
        return '🌴';
      case 'Núi':
        return '🏔️';
      case 'Thành phố':
        return '🏙️';
      case 'Văn hóa':
        return '🏛️';
      case 'Ẩm thực':
        return '🥣';
      case 'Mua sắm':
        return '🛍️';
      case 'Nghỉ dưỡng':
        return '💆';
      case 'Thể thao mạo hiểm':
        return '🧗';
      default:
        return '📍';
    }
  }

  String _mapGenderFromBackend(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
      case 'FEMAIL':
      case 'FEMAILE':
        return 'Nữ';
      default:
        return gender == null || gender.trim().isEmpty ? 'Nam' : gender;
    }
  }

  String _mapGenderToBackend(String gender) {
    switch (gender) {
      case 'Nam':
        return 'MALE';
      case 'Nữ':
        return 'FEMALE';
      default:
        return gender;
    }
  }

  bool _samePreferences(List<String>? current, List<String> next) {
    final currentSet = (current ?? const <String>[]).toSet();
    final nextSet = next.toSet();
    return currentSet.length == nextSet.length &&
        currentSet.containsAll(nextSet);
  }

  void _syncProfileFields(
    ProfileLoaded state, {
    required bool overwriteEditable,
  }) {
    final profile = state.profile;
    if (overwriteEditable) {
      _nameController.text = profile.name;
      _gender = _mapGenderFromBackend(profile.gender);
      _selectedInterests = List<String>.from(profile.travelPreferences ?? []);
    }
    _phoneNumber = profile.phoneNumber ?? '';
    _email = profile.email;
    _avatarUrl = profile.avatarUrl;
  }

  String _profileSaveErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('connection timeout') ||
        message.contains('receive timeout')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.';
    }
    return 'Cập nhật hồ sơ thất bại. Vui lòng thử lại.';
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final state = context.read<ProfileCubit>().state;
    if (state is! ProfileLoaded) return;

    final displayName = _nameController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên hiển thị không được để trống')),
      );
      return;
    }

    final gender = _mapGenderToBackend(_gender);
    final currentGender = _mapGenderToBackend(
      _mapGenderFromBackend(state.profile.gender),
    );
    final preferencesChanged = !_samePreferences(
      state.profile.travelPreferences,
      _selectedInterests,
    );
    final displayNameChanged = displayName != state.profile.name;
    final genderChanged = gender != currentGender;
    final hasChanges =
        displayNameChanged || genderChanged || preferencesChanged;

    if (!hasChanges) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<ProfileCubit>().updateProfile(
        displayName: displayNameChanged ? displayName : null,
        gender: genderChanged ? gender : null,
        travelPreferences: preferencesChanged
            ? List<String>.from(_selectedInterests)
            : null,
      );
      if (!mounted) return;

      final updatedState = context.read<ProfileCubit>().state;
      setState(() {
        if (updatedState is ProfileLoaded) {
          _syncProfileFields(updatedState, overwriteEditable: true);
        }
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_profileSaveErrorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasSyncedInitialProfile) return;

    final state = context.read<ProfileCubit>().state;
    if (state is ProfileLoaded) {
      _syncProfileFields(state, overwriteEditable: true);
      _hasSyncedInitialProfile = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          setState(() {
            _syncProfileFields(
              state,
              overwriteEditable: !_isEditing || _isSaving,
            );
            _hasSyncedInitialProfile = true;
          });
        } else if (state is ProfileError && _isSaving) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isAvatarUploading =
            state is ProfileLoaded && state.isAvatarUploading;

        if (state is ProfileInitial || state is ProfileLoading) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: Colors.red),
                ),
              ),
            ),
          );
        }

        // ProfileLoaded — hiện giao diện đầy đủ
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
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Hồ sơ',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isEditing ? Icons.check : Icons.edit,
                              color: Colors.white,
                            ),
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_isEditing) {
                                _saveProfile();
                              } else {
                                setState(() {
                                  _isEditing = true;
                                });
                              }
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppSizes.r32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.s24,
                      60,
                      AppSizes.s24,
                      AppSizes.s40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          value: _phoneNumber,
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
                          children:
                              (_isEditing ? _allInterests : _selectedInterests)
                                  .map((interest) {
                                    final isSelected = _selectedInterests
                                        .contains(interest);
                                    return _buildInterestChip(
                                      icon: _getIconForInterest(interest),
                                      label: interest,
                                      isSelected: isSelected,
                                      onTap: _isEditing
                                          ? () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedInterests.remove(
                                                    interest,
                                                  );
                                                } else {
                                                  _selectedInterests.add(
                                                    interest,
                                                  );
                                                }
                                              });
                                            }
                                          : null,
                                    );
                                  })
                                  .toList(),
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
                  child: GestureDetector(
                    onTap: (_isEditing && !isAvatarUploading)
                        ? _pickAndUploadAvatar
                        : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _avatarUrl.isNotEmpty
                                ? NetworkImage(_avatarUrl)
                                : null,
                            child: _avatarUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 46,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                        ),
                        if (isAvatarUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (!_isEditing) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1000,
    );

    if (image == null || !mounted) return;
    try {
      await context.read<ProfileCubit>().uploadNewAvatar(image);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật ảnh đại diện. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s20,
          vertical: AppSizes.s8,
        ),
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
          border: Border.all(color: AppColorsExt.chipActive, width: 1),
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
