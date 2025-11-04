import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pedal/widgets/report/card/stat_card.dart';




class WeeklyTimeStat extends StatelessWidget {
  const WeeklyTimeStat({super.key});

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: '이번 주 시간',
      value: '69:21:34',
      color: Colors.blueAccent,
      textColor: Colors.black,
    );
  }
}
