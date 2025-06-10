import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stratum/api.dart';

class ServerDisplay extends StatefulWidget {
  const ServerDisplay({super.key, required this.ser});
  final Server ser;
  @override
  State<ServerDisplay> createState() => _ServerDisplayState();
}

String _getMonthName(int month) {
  switch (month) {
    case 1:
      return 'January';
    case 2:
      return 'February';
    case 3:
      return 'March';
    case 4:
      return 'April';
    case 5:
      return 'May';
    case 6:
      return 'June';
    case 7:
      return 'July';
    case 8:
      return 'August';
    case 9:
      return 'September';
    case 10:
      return 'October';
    case 11:
      return 'November';
    case 12:
      return 'December';
    default:
      return '';
  }
}

// Helper function for date formatting
String _formatDateTime(String? dateTimeString) {
  if (dateTimeString == null) return 'Unknown Date';
  try {
    final dateTime = DateTime.parse(dateTimeString);
    final month = _getMonthName(dateTime.month);
    final day = dateTime.day.toString();
    final year = dateTime.year.toString();
    
    return '$month $day, $year';
  } catch (e) {
    return 'Invalid Date';
  }
}

// Custom SnackBar function (placeholder - implement according to your design)
void showCustomSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}

class _ServerDisplayState extends State<ServerDisplay> {
  int _currentIndex = 0; // Changed from global variable to instance variable

  @override
  Widget build(BuildContext context) {
    final Server server = widget.ser;
    final formattedDateTime = _formatDateTime(server.createdAt);
    final lCapitalized = server.loader != null && server.loader!.isNotEmpty
        ? server.loader![0].toUpperCase() + server.loader!.substring(1)
        : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Server Settings'),),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GNav(
          tabs: const [
            GButton(icon: Icons.settings_rounded, text: 'Settings'),
            GButton(icon: Icons.comment_rounded, text: 'Console'),
            GButton(icon: Icons.download_rounded, text: 'Mods'),
          ],
          gap: 5,
          iconSize: 20,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          duration: const Duration(milliseconds: 400),
          selectedIndex: _currentIndex,
          onTabChange: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          style: GnavStyle.google,
          tabBorderRadius: 50,
        ),
      ),
      body: _buildBody(server, formattedDateTime, lCapitalized),
    );
  }

  Widget _buildBody(
    Server server,
    String formattedDateTime,
    String lCapitalized,
  ) {
    switch (_currentIndex) {
      case 0:
        return Animate(
          effects: const [FadeEffect()],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(server.name ?? 'No Name'),
                      subtitle: Text('Made at $formattedDateTime'),
                      trailing: Text(
                        lCapitalized,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: ServerPropEdit(server: server)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Advanced Info',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jar Path: '),
                            Expanded(
                              child: AutoSizeText(
                                server.jarpath ?? 'something went wrong',
                                style: const TextStyle(fontSize: 30),
                                minFontSize: 8,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Process ID:'),
                            Text(
                              (server.PID ?? 'Only Exists When Server Running')
                                  .toString(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case 1:
        return Serlog(ser: server);
      case 2:
        return SerMods(server: server);
      default:
        return const SizedBox();
    }
  }
}

class ServerPropEdit extends StatefulWidget {
  const ServerPropEdit({super.key, required this.server});
  final Server server;

  @override
  State<ServerPropEdit> createState() => _ServerPropEditState();
}

class _ServerPropEditState extends State<ServerPropEdit> {
  late Future<Map<String, String>> serversFuture;
  bool advancedViewUsed = false;

  @override
  void initState() {
    super.initState();
    serversFuture = _initServerProps();
  }

  Future<Map<String, String>> _initServerProps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('url') ?? '';
      final password = prefs.getString('password') ?? '';
      final result = await widget.server.props(url, password);
      return Map<String, String>.from(result);
    } catch (e) {
      throw Exception('Failed to load server properties: $e');
    }
  }

  void _refreshServerProps() {
    setState(() {
      serversFuture = _initServerProps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Edit mode'),
            Switch(
              value: advancedViewUsed,
              onChanged: (value) {
                setState(() {
                  advancedViewUsed = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: advancedViewUsed
              ? Adview(server: widget.server, onRefresh: _refreshServerProps)
              : SimpleView(
                  serversFuture: serversFuture,
                  onRefresh: _refreshServerProps,
                ),
        ),
      ],
    );
  }
}

class Adview extends StatefulWidget {
  const Adview({super.key, required this.server, required this.onRefresh});
  final Server server;
  final VoidCallback onRefresh;

  @override
  State<Adview> createState() => _AdviewState();
}

class _AdviewState extends State<Adview> {
  late Future<Map<String, String>> serversFuture;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    serversFuture = _initAdViewProps();
  }

  Future<Map<String, String>> _initAdViewProps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('url') ?? '';
      final password = prefs.getString('password') ?? '';
      final result = await widget.server.props(url, password);

      // Dispose old controllers and focus nodes, then clear maps
      for (var controller in _controllers.values) {
        controller.dispose();
      }
      for (var focusNode in _focusNodes.values) {
        focusNode.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();

      // Initialize new controllers and focus nodes
      for (var entry in result.entries) {
        _controllers[entry.key] = TextEditingController(text: entry.value);
        _focusNodes[entry.key] = FocusNode();
      }

      return Map<String, String>.from(result);
    } catch (e) {
      throw Exception('Failed to load advanced properties: $e');
    }
  }

  Future<void> _updateServerProperty(String key, String newValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('url') ?? '';
      final password = prefs.getString('password') ?? '';
      

      widget.server.change(url, password, key, newValue);
      if (mounted) {
        showCustomSnackBar(context, 'Property "$key" updated successfully!');
        // Re-fetch properties to ensure UI is up-to-date
        setState(() {
          serversFuture = _initAdViewProps();
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Error updating property "$key": $e');
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: serversFuture,
      builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      serversFuture = _initAdViewProps();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final props = snapshot.data!;
          if (props.isEmpty) {
            return const Center(child: Text('No properties found'));
          }

          return Animate(
            effects: const [FadeEffect()],
            child: Card(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    serversFuture = _initAdViewProps();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: props.length,
                    itemBuilder: (context, index) {
                      String key = props.keys.elementAt(index);
                      String value = props[key] ?? '';
                      int animLen = index * 50;

                      // Ensure controller and focus node exist for this key
                      if (!_controllers.containsKey(key)) {
                        _controllers[key] = TextEditingController(text: value);
                        _focusNodes[key] = FocusNode();
                      } else {
                        // Update controller text if the value changes from future
                        // Only update if the text is different to avoid cursor jump
                        if (_controllers[key]!.text != value) {
                          _controllers[key]!.text = value;
                        }
                      }

                      return Animate(
                        effects: [
                          FadeEffect(duration: Duration(milliseconds: animLen)),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(flex: 2, child: Text('$key:')),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: (value == 'true' || value == 'false')
                                    ? Switch(
                                        value: value == 'true',
                                        onChanged: (bool newVal) {
                                          _updateServerProperty(
                                            key,
                                            newVal.toString(),
                                          );
                                        },
                                      )
                                    : TextFormField(
                                        controller: _controllers[key],
                                        focusNode: _focusNodes[key],
                                        onFieldSubmitted: (newValue) {
                                          _updateServerProperty(key, newValue);
                                          _focusNodes[key]?.unfocus();
                                        },
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class SimpleView extends StatelessWidget {
  const SimpleView({
    super.key,
    required this.serversFuture,
    required this.onRefresh,
  });
  final Future<Map<String, String>> serversFuture;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: serversFuture,
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: onRefresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              final props = snapshot.data!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPropertyRow('Message of the Day:', props['motd']),
                      _buildPropertyRow('Gamemode:', props['gamemode']),
                      _buildPropertyRow(
                        'Render Distance:',
                        props['view-distance'],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: Text('No server properties found'));
            }
          },
    );
  }

  Widget _buildPropertyRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}

class Serlog extends StatelessWidget {
  const Serlog({super.key, required this.ser});
  final Server ser;

  @override
  Widget build(BuildContext context) {
    return Console(ser: ser);
  }
}

class Console extends StatefulWidget {
  const Console({super.key, required this.ser});
  final Server ser; // The server object for which to display logs

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  late String password; // Stores the loaded password
  late String url; // Stores the loaded URL
  late Stream<List<String>> logsStream;
  StreamController<List<String>>? _streamController;
  final ScrollController _scrollController = ScrollController();
  List<String> _currentLogs = []; // Cache current logs to prevent flashing

  @override
  void initState() {
    super.initState();
    _setupStream();
  }

  /// Sets up the stream that periodically fetches logs every 2 seconds
  void _setupStream() {
    _streamController = StreamController<List<String>>();

    // Create a stream that emits data every 2 seconds
    logsStream = Stream.periodic(Duration(seconds: 1))
        .asyncMap((_) => _loadServers())
        .handleError((error) {
          // Handle errors in the stream

          throw error;
        });
  }

  /// Asynchronously loads the URL and password from SharedPreferences,
  /// and then calls `ServLogs` to fetch the actual server logs.
  Future<List<String>> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    url =
        prefs.getString('url') ??
        ''; // Get URL, default to empty string if not found
    password =
        prefs.getString('password') ??
        ''; // Get password, default to empty string if not found

    // Call the external function to fetch logs using the loaded credentials and server name.
    final logsRaw = await ServLogs(url, password, widget.ser.name!);
    print(logsRaw.map((e) => e.toString()).toList());
    // Convert all entries to String
    return logsRaw.map((e) => e.toString()).toList();
    
  }

  /// Manual refresh function
  void _refreshLogs() {
    // Force a new stream emission by recreating the stream
    _setupStream();
    setState(() {});
  }

  @override
  void dispose() {
    _streamController?.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder is used to asynchronously build the UI based on the stream of logs.
    return StreamBuilder<List<String>>(
      stream: logsStream, // The Stream to monitor
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        // Update cached logs only if we have new data
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          _currentLogs = snapshot.data!;
        }

        // Case 1: The Stream is waiting for the first data (initial load only).
        if (snapshot.connectionState == ConnectionState.waiting &&
            _currentLogs.isEmpty) {
          return Center(
            child: CircularProgressIndicator()
                .animate()
                .scale(delay: 200.ms, duration: 600.ms)
                .fadeIn(duration: 400.ms),
          ); // Show a loading spinner only on initial load
        }
        // Case 2: An error occurred while fetching the data.
        else if (snapshot.hasError && _currentLogs.isEmpty) {
          // Only show error state if we have no cached data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                showCustomSnackBar(context, 'Error: ${snapshot.error}');
              }
            });
          });
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                      onPressed: _refreshLogs,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Logs',
                    )
                    .animate()
                    .scale(delay: 100.ms, duration: 400.ms)
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 8),
                const Text(
                      "Couldn't Connect",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    )
                    .animate()
                    .slideY(begin: 0.3, delay: 200.ms, duration: 400.ms)
                    .fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          );
        }
        // Case 3: No data available and no cached data
        else if (_currentLogs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                // Optionally show a snackbar here if "no logs" is an unexpected state.
                // showCustomSnackBar(context, 'No logs found for this server.');
              }
            });
          });
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                      onPressed: _refreshLogs,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Logs',
                    )
                    .animate()
                    .scale(delay: 100.ms, duration: 400.ms)
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 8),
                const Text(
                      "No logs available.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    )
                    .animate()
                    .slideY(begin: 0.3, delay: 200.ms, duration: 400.ms)
                    .fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 7,
                  top: 7,
                ),
                child: TextField(
                  autocorrect: false,
                  decoration: const InputDecoration(
                    label: Text("Run A Command"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:
                      Card(
                            color: Colors.black,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _currentLogs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child:
                                        Text(
                                          _currentLogs[index],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ).animate().fadeIn(
                                          delay: Duration(
                                            milliseconds: index * 2,
                                          ),
                                          duration: 300.ms,
                                        ),
                                  );
                                },
                              ),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: Offset(0.95, 0.95),
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          )
                          .fadeIn(duration: 500.ms),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class SerMods extends StatefulWidget {
  const SerMods({super.key, required this.server});
  final Server server;
  @override
  State<SerMods> createState() => _SerModsState();
}

class _SerModsState extends State<SerMods> {
  @override
  Widget build(BuildContext context) {
    return widget.server.loader == "paper"? Animate(
      effects: [FadeEffect()],
      child: Text('Mods'),
    ) : Center(child: Text("Mods are only supported on paper"),);
  }
}
