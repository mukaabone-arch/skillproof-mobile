import 'package:flutter/material.dart';

/// Placeholder — profile editing (name, headline, years of experience,
/// skill claims) is built out separately. Jobs already link here from the
/// PROFILE_INCOMPLETE apply prompt once this screen does something.
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile editing is coming soon.')),
    );
  }
}
