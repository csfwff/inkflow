import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'editor_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onSettingsChanged;

  const HomePage({super.key, this.onSettingsChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.current.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    onSettingsChanged: onSettingsChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 80, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              AppStrings.current.homeTitle,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(AppStrings.current.subtitle),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditorPage()),
                );
              },
              icon: Icon(Icons.add),
              label: Text(AppStrings.current.newArticle),
            ),
          ],
        ),
      ),
    );
  }
}
