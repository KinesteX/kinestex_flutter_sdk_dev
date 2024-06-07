
import 'package:flutter/material.dart';
import 'package:kinestex_sdk_flutter/kinestex_sdk_flutter.dart';
import 'package:kinestex_sdk_flutter/models/plan_category.dart';
import 'package:kinestex_sdk_flutter/models/work_out_category.dart';

// import 'package:lottie/lottie.dart';
// import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String url = "https://kineste-x-w.vercel.app/";

  bool showWebView = false; // Flag to control WebView visibility
  List<String> workoutLogs = [];


  // void _checkCameraPermission() async {
  //   if (await Permission.camera.request() != PermissionStatus.granted) {
  //     _showCameraAccessDeniedAlert();
  //   }
  //}

  // void _showCameraAccessDeniedAlert() {
  //   showDialog(
  //     context: context, // Now using the build context of the widget
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Camera Permission Denied"),
  //         content: const Text(
  //             "Camera access is required for this app to function properly."),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("OK"),
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  void initState() {
    super.initState();
   // _checkCameraPermission();
  }


  @override
  Widget build(BuildContext context) {
    if (showWebView) {
      // Fullscreen WebView without AppBar
      return SafeArea(
        child: Stack(
          children: [
            _buildWebView(),

          ],
        ),
      );
    } else {
      // Regular UI with AppBar
      return Scaffold(
        appBar: AppBar(
          title: const Text("KinesteX"),

        ),
        body: _buildOpenButton(),
      );
    }
  }

  Widget _buildWebView() {
    return KinesteXWebView(
      apiKey: 'YOUR API KEY',
      userId:  "testUser",
      workOutCategory: CustomWorkOutCategory(""),
      planCategory: WeightManagementPlanCategory(),
      companyName: 'YOUR COMPANY NAME',
      onLoadStop: () {},
      onHandleMessage: _handleMessage,
    );
  }

  void _handleMessage(Map<String, dynamic> message) {
    print("RECEIVED A MESSAGE: $message");
    String currentTime =
        "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";
//data handling. HTTP post communication
    switch (message['type']) {
      case "kinestex_launched":
        print("Successfully launched the app. @${message['data']}");
        break;
      case "workout_opened":
        print("Workout opened. ${message['data']}");
        break;
      case "workout_started":
        print("Workout started. ${message['data']}");
        break;
      case "plan_unlocked":
        print("User unlocked plan. Data: ${message['data']}");
        break;
      case "finished_workout":
        print("Workout finished. Data: ${message['data']}");
        break;
      case "error_occured":
        print("There was an error: ${message['data']}");
        break;
      case "exercise_completed":
        print("Exercise completed: ${message['data']}");
        break;
      case "exitApp":
        if (mounted) {
          setState(() {
            showWebView = false;
          });
        }
        print("User closed KinesteX window @$currentTime");
        break;
      default:
        print("Received: ${message['type']} ${message['data']}");
        break;
    }
  }

  void showLogsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: workoutLogs.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(workoutLogs[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildOpenButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
           showWebView = true;
          });
        },
        child: const Text('Open KinesteX'),
      ),
    );
  }



}
