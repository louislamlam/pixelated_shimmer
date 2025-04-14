import 'package:flutter/material.dart';
import 'package:pixelated_shimmer/pixelated_shimmer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixelated Shimmer Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  // Example image URL (replace with a reliable one if needed)
  final String imageUrl =
      'https://images.unsplash.com/photo-1742590794310-04fc4d2025f2?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxmZWF0dXJlZC1waG90b3MtZmVlZHw1fHx8ZW58MHx8fHx8';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixelated Shimmer Example'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Image loading with PixelatedShimmer:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Example usage
              PixelatedShimmer(
                imageProvider: NetworkImage(imageUrl),
                width: 300,
                height: 300,
                pixelSize: 12.0,
                borderRadius: BorderRadius.circular(8),
                fit: BoxFit.cover,
                // Optional: Customize shimmer/placeholder
                // baseColor: Colors.grey[300],
                // variation: 0.2,
                // lightnessBias: 0.1,
              ),
              const SizedBox(height: 40),
              const Text(
                'Placeholder shimmer without image:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Example usage (shimmer only)
              PixelatedShimmer(
                showShimmer: true,
                width: 200,
                height: 200,
                pixelSize: 10.0,
                borderRadius: BorderRadius.circular(8),
                baseColor: Theme.of(context).colorScheme.primaryContainer,
                variation: 0.1,
                lightnessBias: 0.3,
                transition: 0.7,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
