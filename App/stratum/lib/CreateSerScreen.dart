import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stratum/api.dart';
import 'package:stratum/HomeScreen.dart';

enum MODLOADERCREATESER { fabric, paper, vanilla }

class CreateSer extends StatelessWidget {
  const CreateSer({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    List<Server> sers;
    sers = args?['sers'] as List<Server>;

    return Scaffold(
      appBar: AppBar(title: Text('Create Server')),
      body: Animate(
        effects: [FadeEffect()],
        child: CreateSerDialog(servers: sers),
      ),
    );
  }
}

class CreateSerDialog extends StatefulWidget {
  final List<Server> servers;
  const CreateSerDialog({super.key, required this.servers});
  @override
  State<CreateSerDialog> createState() => _CreateSerDialogState();
}

class _CreateSerDialogState extends State<CreateSerDialog> {
  late String URL;
  late String Password;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<List<Server>> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    URL = prefs.getString('url') ?? '';
    Password = prefs.getString('password') ?? '';
    print('URL: $URL');
    print('Password: $Password');
    return Servers(URL, Password);
  }

  Set<String> _selectedMaterial = <String>{'fabric'};
  String SerName = '';
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(16),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.all(16),
            child: TextField(
              decoration: InputDecoration(
                label: Text("Server Name"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
              onSubmitted: (value) {
                if (value != '') {
                  SerName = value;
                }
              },
              onChanged: (value) {
                if (value != '') {
                  SerName = value;
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'fabric', label: Text('Fabric')),
                ButtonSegment<String>(value: 'paper', label: Text('Paper')),
                ButtonSegment<String>(value: 'vanilla', label: Text('Vanilla')),
              ],
              selected: _selectedMaterial,
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  if (newSelection.isNotEmpty) {
                    _selectedMaterial = {newSelection.first};
                  }
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.all(16),
            child: OutlinedButton(
              onPressed: () async {
                if (SerName == '') {
                  showCustomSnackBar(context, 'Enter a server name');
                  return;
                }

                bool NameUsed = false;
                for (var i in widget.servers) {
                  if (SerName == i.name!) {
                    NameUsed = true;
                    break;
                  }
                }

                if (NameUsed) {
                  showCustomSnackBar(context, 'Select an unused name');
                  return;
                }
                print(SerName);
                print(_selectedMaterial.first);
                AddSer(URL, Password, SerName, _selectedMaterial.first);
                Navigator.popUntil(context, ModalRoute.withName('/'));
                showCustomSnackBar(
                  context,
                  'Creating $SerName please refresh in 16s',
                );
              },
              child: Text('Create'),
            ),
          ),
        ],
      ),
    );
  }
}
