import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'client_detail_screen.dart';

/// Add / edit client form.
class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.existing});

  final Client? existing;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessName =
      TextEditingController(text: widget.existing?.businessName ?? '');
  late final TextEditingController _contactPerson =
      TextEditingController(text: widget.existing?.contactPerson ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final TextEditingController _email =
      TextEditingController(text: widget.existing?.email ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.existing?.address ?? '');
  late final TextEditingController _notes =
      TextEditingController(text: widget.existing?.notes ?? '');

  late BusinessCategory _category =
      widget.existing?.category ?? BusinessCategory.restaurant;
  late ProjectStatus _status =
      widget.existing?.status ?? ProjectStatus.lead;

  @override
  void dispose() {
    for (final c in [
      _businessName, _contactPerson, _phone, _email, _address, _notes
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    if (widget.existing != null) {
      final c = widget.existing!
        ..businessName = _businessName.text.trim()
        ..contactPerson = _contactPerson.text.trim()
        ..phone = _phone.text.trim()
        ..email = _email.text.trim()
        ..category = _category
        ..address = _address.text.trim()
        ..notes = _notes.text.trim()
        ..status = _status;
      state.updateClient(c);
      Navigator.of(context).pop();
    } else {
      final client = state.addClient(
        businessName: _businessName.text.trim(),
        contactPerson: _contactPerson.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        category: _category,
        address: _address.text.trim(),
        notes: _notes.text.trim(),
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ClientDetailScreen(clientId: client.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit client' : 'Add client')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(title: 'Business details'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessName,
                decoration: const InputDecoration(
                    labelText: 'Business name',
                    prefixIcon: Icon(Icons.storefront_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Business name is required'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<BusinessCategory>(
                value: _category,
                dropdownColor: DVColors.surfaceRaised,
                decoration: const InputDecoration(
                    labelText: 'Business category',
                    prefixIcon: Icon(Icons.category_outlined)),
                items: BusinessCategory.values
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          Icon(c.icon, size: 16, color: DVColors.orange),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ])))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Contact'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactPerson,
                decoration: const InputDecoration(
                    labelText: 'Contact person',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Contact person is required'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Project'),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProjectStatus>(
                value: _status,
                dropdownColor: DVColors.surfaceRaised,
                decoration: const InputDecoration(
                    labelText: 'Project status',
                    prefixIcon: Icon(Icons.flag_outlined)),
                items: ProjectStatus.values
                    .map((s) => DropdownMenuItem(
                        value: s, child: Text(s.label)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _notes,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined)),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(editing ? 'Save changes' : 'Add client'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
