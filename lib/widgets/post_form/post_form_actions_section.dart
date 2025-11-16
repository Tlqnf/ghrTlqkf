import 'package:flutter/material.dart';
import 'package:pedal/viewmodels/post_form_viewmodel.dart';
import 'package:provider/provider.dart';

class PostFormActionsSection extends StatelessWidget {
  const PostFormActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostFormViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: viewModel.isEditing
          ? _buildEditButtons(context, viewModel)
          : _buildCreateButton(context, viewModel),
    );
  }

  Widget _buildCreateButton(BuildContext context, PostFormViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isLoading ? null : viewModel.savePost,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledBackgroundColor: Colors.grey[400],
        ),
        child: viewModel.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text('저장', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildEditButtons(BuildContext context, PostFormViewModel viewModel) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: viewModel.isLoading ? null : viewModel.deletePost,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.red, width: 2),
            ),
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.red,
                    strokeWidth: 3,
                  ),
                )
              : const Text('삭제', style: TextStyle(fontSize: 18)),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: viewModel.isLoading ? null : viewModel.updatePost,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 70),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Text('저장', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
