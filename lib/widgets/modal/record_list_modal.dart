import 'package:flutter/material.dart';
import 'package:pedal/widgets/card/record_card.dart'; // Import RecordCard

class RecordListModal extends StatelessWidget {
  const RecordListModal({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6, // Increased default height
      minChildSize: 0.4,
      maxChildSize: 0.9, // Allow dragging up to 90% of the available height
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Draggable handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '내 경로',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // List of records
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: 5, // Dummy count for now
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: RecordCard(
                        routeName: '경로 ${index + 1}',
                        distance: '${(index + 1) * 5.5} km',
                        time: '${(index + 1) * 30} 분',
                        date: '2023.0${index + 1}.15',
                        onTap: () {
                          // Handle tap on record card
                          print('Record Card ${index + 1} tapped!');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
