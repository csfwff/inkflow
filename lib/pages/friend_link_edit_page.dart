import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/friend_link.dart';

class FriendLinkEditPage extends StatefulWidget {
  final FriendLink? friendLink;

  const FriendLinkEditPage({super.key, this.friendLink});

  @override
  State<FriendLinkEditPage> createState() => _FriendLinkEditPageState();
}

class _FriendLinkEditPageState extends State<FriendLinkEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _avatarCtrl;
  late final TextEditingController _descrCtrl;
  late bool _enabled;

  bool get _isEditing => widget.friendLink != null;

  @override
  void initState() {
    super.initState();
    final link = widget.friendLink;
    _nameCtrl = TextEditingController(text: link?.name ?? '');
    _linkCtrl = TextEditingController(text: link?.link ?? '');
    _avatarCtrl = TextEditingController(text: link?.avatar ?? '');
    _descrCtrl = TextEditingController(text: link?.descr ?? '');
    _enabled = link == null || !link.isCommented;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _linkCtrl.dispose();
    _avatarCtrl.dispose();
    _descrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final friendLink = FriendLink(
      id: widget.friendLink?.id,
      name: _nameCtrl.text.trim(),
      link: _linkCtrl.text.trim(),
      avatar: _avatarCtrl.text.trim(),
      descr: _descrCtrl.text.trim(),
      isCommented: !_enabled,
      isDev: widget.friendLink?.isDev ?? false,
      createdAt: widget.friendLink?.createdAt ?? DateTime.now(),
    );

    Navigator.pop(context, friendLink);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editFriendLink : s.addFriendLink),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(s.done),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              _buildLabel(s.friendLinkName),
              const SizedBox(height: 4),
              TextFormField(
                controller: _nameCtrl,
                decoration: _buildInputDecoration(s.friendLinkName),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.friendLinkName : null,
              ),
              const SizedBox(height: 16),

              // Link
              _buildLabel(s.friendLinkLink),
              const SizedBox(height: 4),
              TextFormField(
                controller: _linkCtrl,
                decoration: _buildInputDecoration('https://example.com'),
                keyboardType: TextInputType.url,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.friendLinkLink : null,
              ),
              const SizedBox(height: 16),

              // Avatar
              _buildLabel(s.friendLinkAvatar),
              const SizedBox(height: 4),
              TextFormField(
                controller: _avatarCtrl,
                decoration: _buildInputDecoration(
                  'https://example.com/avatar.png',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel(s.friendLinkDescr),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descrCtrl,
                decoration: _buildInputDecoration(s.friendLinkDescr),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Enabled switch
              SwitchListTile(
                title: Text(
                  _enabled ? s.friendLinkEnabled : s.friendLinkDisabled,
                ),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    );
  }
}
