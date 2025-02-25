import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future addReminder(TimeOfDay time, String timeFormatted) async {
  final docUser = FirebaseFirestore.instance
      .collection('Reminders')
      .doc(DateTime.now().toString());

  final json = {
    'time': time,
    'timeFormatted': timeFormatted,
    'dateTime': DateTime.now(),
  };

  await docUser.set(json);
}
