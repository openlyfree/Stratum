// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for jsonDecode

class Server {
  String? name;
  String? state;
  String? createdAt;
  String? loader;
  String? jarpath;
  int? PID; // Assuming PID is an integer

  // Default unnamed constructor
  Server();

  // Factory constructor to create a Server object from a JSON map
  factory Server.fromJson(Map<String, dynamic> json) {
    return Server()
      ..name = json['name'] as String?
      ..state = json['state'] as String?
      ..createdAt = json['createdAt'] as String?
      ..loader = json['loader'] as String?
      ..jarpath = json['jarPath'] as String?
      ..PID = json['pid'] as int?;
  }
  @override
  String toString() {
    return '(Name: ${name ?? 'N/A'}, State: ${state ?? 'N/A'}, PID: ${PID ?? 'N/A'}, Jarpath: ${jarpath ?? 'N/A'})';
  }

  void delete(String URL, String Password) async {
    String name = this.name!;
    final url = Uri.parse('http://$URL/del/$name'); // Use the provided URL
    final headers = {
      'Key': Password, // Use the provided Password as the Key
      'Content-Type': 'application/json', // Often good practice for APIs
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        print("Cant delete $name");
      } else {
        final Map<String, dynamic> bodyJson = jsonDecode(response.body);
        print('From Del Ser: ' + bodyJson['Message']);
      }
    } catch (e) {
      print('Error $e');
      return;
    }
  }

  void change(
    String URL,
    String Password,

    String PropToEdit,
    String NewVal,
  ) async {
    String Name = name!;
    final url = Uri.parse(
      'http://$URL/server/$Name/$PropToEdit/$NewVal',
    ); // Use the provided URL
    final headers = {
      'Key': Password, // Use the provided Password as the Key
      'Content-Type': 'application/json', // Often good practice for APIs
    };

    try {
      final response = await http.get(url, headers: headers);
      final Map<String, dynamic> bodyJson = jsonDecode(response.body);
      print('From Prop Edit: ' + bodyJson['Message']);
    } catch (e) {
      print('Error $e');
      return;
    }
  }

  void stop(String URL, String Password) async {
    String name = this.name!;
    final url = Uri.parse('http://$URL/stop/$name'); // Use the provided URL
    final headers = {
      'Key': Password, // Use the provided Password as the Key
      'Content-Type': 'application/json', // Often good practice for APIs
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        print("Cant stop $name");
      } else {
        final Map<String, dynamic> bodyJson = jsonDecode(response.body);
        print('From Stop Ser: ' + bodyJson['Message']);
      }
    } catch (e) {
      print('Error $e');
      return;
    }
  }

  void run(String URL, String Password) async {
    String name = this.name!;
    final url = Uri.parse('http://$URL/run/$name'); // Use the provided URL
    final headers = {
      'Key': Password, // Use the provided Password as the Key
      'Content-Type': 'application/json', // Often good practice for APIs
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        print("Cant run $name");
      } else {
        final Map<String, dynamic> bodyJson = jsonDecode(response.body);
        print('From Run Ser: ' + bodyJson['Message']);
      }
    } catch (e) {
      print('Error $e');
      return;
    }
  }

  Future<Map> props(String URL, String Password) async {
    final url = Uri.parse(
      'http://$URL/server/${name!}',
    ); // Use the provided URL
    final headers = {
      'Key': Password, // Use the provided Password as the Key
      'Content-Type': 'application/json', // Often good practice for APIs
    };
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        print("Something went wrong");
      } else {
        final Map<String, dynamic> bodyJson = jsonDecode(response.body);
        return bodyJson;
      }
    } catch (e) {
      print('Error $e');
    }
    // Always return an empty map if something goes wrong
    return {};
  }
}

Future<List<Server>> Servers(String URL, String Password) async {
  final url = Uri.parse('http://$URL/'); // Use the provided URL
  final headers = {
    'Key': Password, // Use the provided Password as the Key
    'Content-Type': 'application/json', // Often good practice for APIs
  };

  try {
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // Decode the JSON response body
      final List<dynamic> jsonList = jsonDecode(response.body);

      // Map each JSON object in the list to a Server object
      return jsonList.map((json) => Server.fromJson(json)).toList();
    } else {
      print('Request failed with status: ${response.statusCode}');
      print('Response Body: ${response.body}'); // Often contains error details
      return []; // Return an empty list on failure
    }
  } catch (e) {
    print('Error during HTTP request: $e');
    return []; // Return an empty list if an exception occurs
  }
}

void AddSer(
  String URL,
  String Password,
  String ServerName,
  String modloader,
) async {
  String name = ServerName;
  final url = Uri.parse(
    'http://$URL/add/$name/$modloader',
  ); // Use the provided URL
  final headers = {
    'Key': Password, // Use the provided Password as the Key
    'Content-Type': 'application/json', // Often good practice for APIs
  };

  try {
    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      print("Cant create $name");
    } else {
      final Map<String, dynamic> bodyJson = jsonDecode(response.body);
      print('From Add Ser: ' + bodyJson['Message']);
    }
  } catch (e) {
    print('Error $e');
    return;
  }
}

Future<String> ServerList(String URL, String Password) async {
  var serverList = await Servers(URL, Password);
  return serverList.toString();
}

Future<List> ServLogs(String URL, String Password, String SerName) async {
  final url = Uri.parse(
    'http://$URL/server/$SerName/console',
  ); // Use the provided URL
  final headers = {
    'Key': Password, // Use the provided Password as the Key
    'Content-Type': 'application/json', // Often good practice for APIs
  };
  try {
    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      print("Something went wrong");
    } else {
      final List bodyJson = jsonDecode(response.body);
      print(bodyJson);
      return bodyJson;
    }
  } catch (e) {
    print('Error $e');
  }
  return [];
}
