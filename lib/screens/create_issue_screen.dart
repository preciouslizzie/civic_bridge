import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/issue.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/issues_provider.dart';
import '../utils/constants.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  IssueCategory _selectedCategory = IssueCategory.other;
  String? _selectedState;
  String? _selectedLga;
  bool _isAnonymous = false;
  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitIssue,
            child: Text(
              'Post',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleField(),
                    const SizedBox(height: AppConstants.paddingLarge),

                    _buildDescriptionField(),
                    const SizedBox(height: AppConstants.paddingLarge),

                    _buildCategoryDropdown(),
                    const SizedBox(height: AppConstants.paddingLarge),

                    _buildLocationFields(),
                    const SizedBox(height: AppConstants.paddingLarge),

                    _buildImagePicker(),
                    const SizedBox(height: AppConstants.paddingLarge),

                    _buildAnonymousToggle(),
                    const SizedBox(height: AppConstants.paddingLarge),

                    _buildPreview(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Brief description of the issue',
            counterText: '',
          ),
          maxLength: AppConstants.maxTitleLength,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.length > AppConstants.maxTitleLength) {
              return 'Title too long';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'Detailed description of the issue',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          maxLength: AppConstants.maxDescriptionLength,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            if (value.length > AppConstants.maxDescriptionLength) {
              return 'Description too long';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<IssueCategory>(
          initialValue: _selectedCategory,
          decoration: const InputDecoration(
            hintText: 'Select category',
          ),
          items: IssueCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(_getCategoryDisplayName(category)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedState,
                decoration: const InputDecoration(
                  hintText: 'State',
                ),
                items: AppConstants.nigerianStates.map((state) {
                  return DropdownMenuItem(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                    _selectedLga = null; // Reset LGA when state changes
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a state';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'LGA/Local Area',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter LGA';
                  }
                  return null;
                },
                onChanged: (value) {
                  _selectedLga = value;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images (Optional)',
              style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_selectedImages.length}/${AppConstants.maxImagesPerIssue}',
              style: AppConstants.bodyText2,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        if (_selectedImages.isEmpty)
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      'Add photos',
                      style: AppConstants.bodyText2.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return InkWell(
                        onTap: _selectedImages.length < AppConstants.maxImagesPerIssue
                            ? _pickImage
                            : null,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(left: AppConstants.paddingSmall),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: AppConstants.paddingSmall),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAnonymousToggle() {
    return Row(
      children: [
        const Icon(Icons.visibility_off, size: 20),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Post Anonymously',
                style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                'Hide your identity when posting this issue',
                style: AppConstants.bodyText2,
              ),
            ],
          ),
        ),
        Switch(
          value: _isAnonymous,
          onChanged: (value) {
            setState(() => _isAnonymous = value);
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              _titleController.text.isEmpty ? 'Issue Title' : _titleController.text,
              style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedState != null && _selectedLga != null
                      ? '$_selectedLga, $_selectedState'
                      : 'Location',
                  style: AppConstants.bodyText2.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Icon(
                  Icons.category,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _getCategoryDisplayName(_selectedCategory),
                  style: AppConstants.bodyText2.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                _descriptionController.text,
                style: AppConstants.bodyText2,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile != null) {
        File? croppedFile = await _cropImage(File(pickedFile.path));
        if (!mounted) return;
        if (croppedFile != null) {
          File? compressedFile = await _compressImage(croppedFile);
          if (!mounted) return;
          if (compressedFile != null) {
            setState(() => _selectedImages.add(compressedFile));
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppConstants.primaryColor,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<File?> _compressImage(File imageFile) async {
    final filePath = imageFile.absolute.path;
    final lastIndex = filePath.lastIndexOf('.');
    final extension = filePath.substring(lastIndex);
    final targetPath = filePath.replaceAll(extension, '_compressed$extension');

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 600,
    );

    return compressedFile != null ? File(compressedFile.path) : null;
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<app_auth.AuthProvider>();
    final issuesProvider = context.read<IssuesProvider>();
    final user = authProvider.userProfile;
    final userId = authProvider.firebaseUser?.uid;

    if (user == null || userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your profile first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await issuesProvider.createIssue(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      state: _selectedState!,
      lga: _selectedLga!,
      userId: userId,
      userName: _isAnonymous ? null : user.name,
      isAnonymous: _isAnonymous,
      images: _selectedImages,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issue reported successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to report issue. Please try again.')),
      );
    }
  }

  String _getCategoryDisplayName(IssueCategory category) {
    switch (category) {
      case IssueCategory.roads:
        return 'Roads';
      case IssueCategory.electricity:
        return 'Electricity';
      case IssueCategory.water:
        return 'Water';
      case IssueCategory.security:
        return 'Security';
      case IssueCategory.health:
        return 'Health';
      case IssueCategory.education:
        return 'Education';
      case IssueCategory.environment:
        return 'Environment';
      case IssueCategory.transportation:
        return 'Transportation';
      case IssueCategory.sanitation:
        return 'Sanitation';
      case IssueCategory.other:
        return 'Other';
    }
  }
}