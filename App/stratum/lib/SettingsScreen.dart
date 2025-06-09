import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stratum/HomeScreen.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Animate(effects: [FadeEffect()],child: SettingsMenu(),),
    );
  }
}

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({super.key});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  late Future<void> _initPrefsFuture;

  // Controllers for the TextFields
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  // State for the self-host switch
  bool _selfHost = false;

  @override
  void initState() {
    super.initState();
    _initPrefsFuture = _initPrefs();
  }

  // Dispose controllers when the widget is removed from the tree
  @override
  void dispose() {
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Load values into controllers and self-host state
    _passwordController.text = prefs.getString('password') ?? '';
    _urlController.text = prefs.getString('url') ?? '';
    _selfHost = prefs.getBool('selfhost') ?? false;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('url', _urlController.text);
    await prefs.setBool('selfhost', _selfHost);

    // Optionally show a confirmation message
    showCustomSnackBar(context, "Saved");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // Add a Scaffold for better material design structure
      children: [
        FutureBuilder<void>(
          future: _initPrefsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error loading settings: ${snapshot.error}'),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 20,

                  children: [
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url, // Suggest URL keyboard
                      decoration: const InputDecoration(
                        label: Text("URL"),
                        
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                    ),

                    TextField(
                      controller: _passwordController,
                      obscureText: true, // Hide password input
                      decoration: const InputDecoration(
                        label: Text("Password"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                      ),
                      autocorrect: false,
                    ),

                    if (Theme.of(context).platform == TargetPlatform.windows ||
                        Theme.of(context).platform == TargetPlatform.linux ||
                        Theme.of(context).platform == TargetPlatform.macOS)
                      Row(
                        children: [
                          const Text('Self-Host:'),
                          Switch(
                            value: _selfHost,
                            onChanged: (newValue) {
                              setState(() {
                                _selfHost = newValue;
                              });
                            },
                          ),
                        ],
                      ),

                    ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text('Save Settings'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
