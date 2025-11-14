import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pedal/viewmodels/post_form_viewmodel.dart';
import 'package:provider/provider.dart';

class PostFormImageSection extends StatelessWidget {
  const PostFormImageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostFormViewModel>();

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SafeArea(
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView(
              controller: viewModel.pageController,
              onPageChanged: viewModel.onPageChanged,
              children: [
                if (viewModel.mapImagePath != null)
                  viewModel.mapImagePath!.startsWith('http')
                      ? Image.network(
                          viewModel.mapImagePath!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Image.file(
                          File(viewModel.mapImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                else
                  const ColoredBox(
                    color: Colors.grey,
                    child: Center(child: Text('Map Placeholder')),
                  ),
                ...viewModel.additionalImages.map(
                  (image) => Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
                ...viewModel.additionalImageUrls.map(
                  (url) => Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: SizedBox(
            width: 50,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.56),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                iconSize: 25.0,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),

        if (viewModel.imageCount > 1)
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                viewModel.imageCount,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: viewModel.currentImagePage == index
                            ? Colors.red
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
