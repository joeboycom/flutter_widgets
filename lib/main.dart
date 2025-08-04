import 'package:flutter/material.dart';
import 'demos/signature_pad/signature_pad_demo.dart';
import 'demos/signature_pad/interactive_signature_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Widget Demos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<DemoItem> demos = [
      DemoItem(
        title: 'Syncfusion Signature Pad',
        subtitle: 'Sign PDF documents with digital signatures',
        icon: Icons.edit,
        route: const SignaturePadDemo(),
      ),
      DemoItem(
        title: 'Interactive PDF Signature',
        subtitle: 'View PDF and click to sign at specific areas',
        icon: Icons.touch_app,
        route: const InteractiveSignatureDemo(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Widget Demos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        itemBuilder: (context, index) {
          final demo = demos[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  demo.icon,
                  color: Colors.white,
                ),
              ),
              title: Text(
                demo.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(demo.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => demo.route),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget route;

  DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}