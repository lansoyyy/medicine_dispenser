import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay? selectedTime;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      helpText: 'Adding a reminder',
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });

      // Ask how many minutes before the reminder should trigger
      _askMinutesBeforeReminder();
    }
  }

  void _askMinutesBeforeReminder() {
    final TextEditingController minutesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Reminder Time'),
          content: TextField(
            controller: minutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes before',
              hintText: 'Enter minutes before the picked time',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int? minutesBefore = int.tryParse(minutesController.text);
                if (minutesBefore != null && selectedTime != null) {
                  Navigator.of(context).pop();
                  _setReminder(minutesBefore);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid number.')),
                  );
                }
              },
              child: const Text('Set Reminder'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setReminder(int minutesBefore) async {
    final DateTime now = DateTime.now();
    final DateTime pickedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Calculate the reminder time (minutes before the picked time)
    final DateTime reminderDateTime =
        pickedDateTime.subtract(Duration(minutes: minutesBefore));

    // Format both times
    final String formattedPickedTime =
        TimeOfDay.fromDateTime(pickedDateTime).format(context);
    final String formattedReminderTime =
        TimeOfDay.fromDateTime(reminderDateTime).format(context);

    // Save to Firestore
    addReminder(formattedPickedTime, formattedReminderTime, minutesBefore);
    // final alarmSettings = AlarmSettings(
    //   id: Random().nextInt(1000),
    //   dateTime: reminderDateTime,
    //   assetAudioPath: 'assets/mixkit-morning-clock-alarm-1003.wav',
    //   loopAudio: true,
    //   vibrate: true,
    //   androidFullScreenIntent: true,
    //   notificationSettings: const NotificationSettings(
    //     title: 'Reminder for taking your medicine',
    //     body: 'Reminder for taking your medicine',
    //     stopButton: 'Stop the alarm',
    //     icon: 'notification_icon',
    //   ),
    // );
    // await Alarm.set(alarmSettings: alarmSettings);

    FlutterAlarmClock.createAlarm(
        hour: reminderDateTime.hour,
        minutes: reminderDateTime.minute,
        title: 'Reminder to take your Medicine!');
  }

  void addReminder(String pickedTime, String reminderTime, int minutesBefore) {
    FirebaseFirestore.instance
        .collection('Reminders')
        .doc(DateTime.now().toString())
        .set({
      'pickedTime': pickedTime,
      'reminderTime': reminderTime,
      'minutesBefore': minutesBefore,
      'dateTime': DateTime.now(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Reminder set for $pickedTime, with alert at $reminderTime')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add reminder: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          _selectTime(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Medicine Dispenser',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Reminders')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print(snapshot.error);
                  return const Center(child: Text('Error'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                final data = snapshot.requireData;

                return Expanded(
                  child: ListView.builder(
                    itemCount: data.docs.length,
                    itemBuilder: (context, index) {
                      final reminder = data.docs[index];
                      return Card(
                        child: ListTile(
                          title: Text('Reminder to take Pill ${index + 1}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                  'Picked Time: ${reminder['pickedTime']}\nReminder Time: ${reminder['reminderTime']} (${reminder['minutesBefore']} minutes before)'),
                              Text(
                                  'Timestamp: ${DateFormat.yMMMd().add_jm().format(reminder['dateTime'].toDate())}'),
                            ],
                          ),
                          leading: const Icon(Icons.medication),
                          trailing: const Icon(
                            Icons.notifications,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
