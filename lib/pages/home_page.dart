import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../widgets/responsive.dart';
import 'editor_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final VoidCallback? onSettingsChanged;

  const HomePage({super.key, this.onSettingsChanged});

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

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
      body: Responsive.constrain(
        child: Center(
          child: wide ? _buildWide(context) : _buildNarrow(context),
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Column(
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
          onPressed: () => _openEditor(context),
          icon: Icon(Icons.add),
          label: Text(AppStrings.current.newArticle),
        ),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit_note, size: 120, color: Colors.deepPurple),
        SizedBox(height: 24),
        Text(
          AppStrings.current.homeTitle,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          AppStrings.current.subtitle,
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _openEditor(context),
              icon: Icon(Icons.add),
              label: Text(AppStrings.current.newArticle),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openEditor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorPage()),
    );
  }
}
