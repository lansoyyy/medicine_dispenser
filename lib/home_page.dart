import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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

    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });

      print(selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          _selectTime(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
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
            Text(
              'Notifications',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),
            StreamBuilder<DatabaseEvent>(
              stream: FirebaseDatabase.instance.ref().onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print(snapshot.error);
                  return const Center(child: Text('Error'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }

                final dynamic cardata = snapshot.data!.snapshot.value;

                if (cardata == null || cardata is! Map) {
                  return const Center(child: Text('No data available'));
                }

                final pillList = (cardata).entries.toList();

                return Expanded(
                  child: ListView.builder(
                    itemCount: pillList.length,
                    itemBuilder: (context, index) {
                      final pillData = pillList[index].value;

                      final timestamp = pillData['timestamp'] ?? 'No timestamp';

                      return Card(
                        child: ListTile(
                          title: Text('Reminder to take Pill ${index + 1}'),
                          subtitle: Text('Timestamp: $timestamp'),
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
