import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stratum/ServerScreen.dart';
import 'package:stratum/api.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stratum"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/setting');
            },
            icon: Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: Animate(effects: [FadeEffect()],child: ServerLS(),),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final url = prefs.getString('url') ?? '';
          final password = prefs.getString('password') ?? '';
          final servers = await Servers(url, password);
          Navigator.pushNamed(
            // ignore: use_build_context_synchronously
            context,
            '/add',
            arguments: {'sers': servers},
          );
        },
        elevation: 1,
        child: Icon(Icons.add_rounded),
      ),
    );
  }
}

class ServerLS extends StatefulWidget {
  const ServerLS({super.key});

  @override
  State<ServerLS> createState() => _ServerLSState();
}

class _ServerLSState extends State<ServerLS> {
  late Future<List<Server>> serversFuture;

  late String URL;
  late String Password;

  @override
  void initState() {
    super.initState();
    serversFuture = _loadServers();
  }

  Future<List<Server>> _loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    URL = prefs.getString('url') ?? '';
    Password = prefs.getString('password') ?? '';
    print('URL: $URL');
    print('Password: $Password');
    return Servers(URL, Password);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          serversFuture = _loadServers();
        });
      },
      triggerMode: RefreshIndicatorTriggerMode.anywhere,

      child: FutureBuilder<List<Server>>(
        future: serversFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Server>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show snackbar with error message
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Future.delayed(Duration(seconds: 1));
              // ignore: use_build_context_synchronously
              showCustomSnackBar(context, 'Error: ${snapshot.error}');
            });
            return Center(
              child: Column(
                children: [
                  IconButton(
                    onPressed: () async {
                      setState(() {
                        serversFuture = _loadServers();
                      });
                    },
                    icon: Icon(Icons.refresh),
                  ),
                  Text("Couldn't Connect")
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await Future.delayed(Duration(seconds: 1));
            });
            return Center(
              child: IconButton(
                onPressed: () async {
                  setState(() {
                    serversFuture = _loadServers();
                  });
                },
                icon: Icon(Icons.refresh),
              ),
            );
          } else {
            print(snapshot.data.toString());
            final servers = snapshot.data!;
            return ListView.builder(
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final a = index + 1;
                final animlength = a * 200;
                final server = servers[index];
                final l = server.loader;
                final lCapitalized = l != null && l.isNotEmpty
                    ? l[0].toUpperCase() + l.substring(1)
                    : l;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServerDisplay(ser: server),
                        ),
                      );
                    },
                    child: Animate(
                      effects: [
                        FadeEffect(
                          duration: Duration(milliseconds: animlength),
                        ), // Fixed duration for fade effect
                      ],
                      autoPlay: true,
                      child: Card(
                        elevation: 2,

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              server.name ?? 'Try Refreshing',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            dense: false,
                            subtitle: Text(lCapitalized!),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (server.state == 'D')
                                  IconButton(
                                    onPressed: () async {
                                      snapshot.data![index].run(URL, Password);
                                      await Future.delayed(
                                        Duration(seconds: 1),
                                      );
                                      setState(() {
                                        serversFuture = _loadServers();
                                      });
                                    },
                                    icon: Icon(Icons.play_arrow_rounded),
                                  ),
                                if (server.state == 'U')
                                  IconButton(
                                    onPressed: () async {
                                      snapshot.data![index].stop(URL, Password);
                                      await Future.delayed(
                                        Duration(seconds: 1),
                                      );
                                      setState(() {
                                        serversFuture = _loadServers();
                                      });
                                    },
                                    icon: Icon(Icons.stop_rounded),
                                  ),
                                IconButton(
                                  onPressed: () async {
                                    snapshot.data![index].delete(URL, Password);
                                    await Future.delayed(Duration(seconds: 1));
                                    setState(() {
                                      serversFuture = _loadServers();
                                    });
                                  },
                                  icon: Icon(Icons.delete_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

void showCustomSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Animate(effects: [FadeEffect()],child: Text(message),),
      // How long it stays visible
      duration: Duration(seconds: 2),
    ),
  );
}
