import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pedal/viewmodels/post_form_viewmodel.dart';
import 'package:provider/provider.dart';

class PostFormMainSection extends StatelessWidget {
  const PostFormMainSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostFormViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Name
          const SizedBox(height: 8),
          _buildSectionTitle('경로 이름', isRequired: true),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.routeNameController,
            decoration: const InputDecoration(
              hintText: '경로 이름을 입력해주세요.',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tags
          _buildSectionTitle('태그'),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.tagController,
            onSubmitted: viewModel.addTag,
            decoration: const InputDecoration(
              hintText: '추가할 태그를 입력해주세요. (최대 3개)',
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: viewModel.tags
                .map(
                  (tag) => Chip(
                    label: Text('#$tag'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    onDeleted: () => viewModel.removeTag(tag),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // Additional Photos
          _buildSectionTitle('추가 사진'),
          const SizedBox(height: 8),
          _buildImagePicker(context, viewModel),
          const SizedBox(height: 8),
          const Text(
            '상단에서 추가된 사진을 드래그로 확인 가능',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Community Upload
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('커뮤니티 업로드'),
              Switch(
                value: viewModel.isCommunityUploadEnabled,
                onChanged: viewModel.toggleCommunityUpload,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            "*",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context, PostFormViewModel viewModel) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount:
            viewModel.additionalImages.length +
            viewModel.additionalImageUrls.length +
            (viewModel.additionalImages.length +
                        viewModel.additionalImageUrls.length <
                    2
                ? 1
                : 0),
        itemBuilder: (context, index) {
          final localImageCount = viewModel.additionalImages.length;
          final totalImageCount =
              localImageCount + viewModel.additionalImageUrls.length;

          if (index == totalImageCount) {
            return _buildAddPhotoButton(context, viewModel);
          }

          if (index < localImageCount) {
            return _buildLocalImageItem(context, viewModel, index);
          } else {
            final urlIndex = index - localImageCount;
            return _buildNetworkImageItem(context, viewModel, urlIndex);
          }
        },
      ),
    );
  }

  Widget _buildAddPhotoButton(
    BuildContext context,
    PostFormViewModel viewModel,
  ) {
    return GestureDetector(
      onTap: viewModel.pickImage,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: SizedBox(
          width: 100,
          height: 100,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  color: Colors.grey,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text('사진 추가', style: const TextStyle(color: Colors.grey)),
                Text(
                  '(${viewModel.additionalImages.length + viewModel.additionalImageUrls.length}/2)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalImageItem(
    BuildContext context,
    PostFormViewModel viewModel,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(viewModel.additionalImages[index].path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => viewModel.removeAdditionalImage(index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImageItem(
    BuildContext context,
    PostFormViewModel viewModel,
    int urlIndex,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              viewModel.additionalImageUrls[urlIndex],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => viewModel.removeAdditionalImageUrl(urlIndex),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
