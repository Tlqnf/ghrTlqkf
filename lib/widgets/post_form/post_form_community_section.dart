import 'package:flutter/material.dart';
import 'package:pedal/viewmodels/post_form_viewmodel.dart';
import 'package:provider/provider.dart';

class PostFormCommunitySection extends StatelessWidget {
  const PostFormCommunitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostFormViewModel>();

    if (!viewModel.isCommunityUploadEnabled) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const SizedBox(height: 16),
          _buildSectionTitle('게시글 제목', isRequired: true),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.titleController,
            decoration: const InputDecoration(
              hintText: '게시글 제목을 입력해주세요.',
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
          const SizedBox(height: 16),

          // Body
          _buildSectionTitle('게시글 내용', isRequired: true),
          const SizedBox(height: 8),
          TextField(
            controller: viewModel.bodyController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: '게시글에 올릴 내용을 입력해주세요.',
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
          const SizedBox(height: 32),
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
}
