import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_config.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';

/// Build line items and generate/share the professional proposal PDF.
class ProposalScreen extends StatefulWidget {
  const ProposalScreen({super.key, required this.client});

  final Client client;

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  late final List<ProposalLineItem> _items = [
    ProposalLineItem(
      description: '55" Commercial LED Display',
      dimensions: '55" (1218 × 685 mm)',
      location: 'Main wall',
      quantity: 1,
      unitPrice: 68500,
    ),
    ProposalLineItem(
      description: 'Vinyl Window Branding',
      dimensions: '1.8 m × 2.0 m',
      location: 'Front glass',
      quantity: 1,
      unitPrice: 8500,
    ),
  ];

  bool _building = false;

  static final _currency = NumberFormat.currency(
      locale: 'en_IN', symbol: AppConfig.currencySymbol, decimalDigits: 0);

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.total);

  Future<void> _generate() async {
    setState(() => _building = true);
    try {
      final bytes = await PdfService.buildProposal(
        client: widget.client,
        items: _items,
        mockupImages:
            widget.client.projects.map((p) => p.afterBytes).toList(),
      );
      await PdfService.sharePdf(bytes,
          'DisplayVision-${widget.client.businessName.replaceAll(' ', '-')}.pdf');
    } finally {
      if (mounted) setState(() => _building = false);
    }
  }

  Future<void> _editItem([ProposalLineItem? existing]) async {
    final description =
        TextEditingController(text: existing?.description ?? '');
    final dimensions =
        TextEditingController(text: existing?.dimensions ?? '');
    final location = TextEditingController(text: existing?.location ?? '');
    final quantity =
        TextEditingController(text: '${existing?.quantity ?? 1}');
    final price = TextEditingController(
        text: existing == null ? '' : existing.unitPrice.toStringAsFixed(0));

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DVColors.surfaceRaised,
        title: Text(existing == null ? 'Add item' : 'Edit item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: description,
                  decoration:
                      const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(
                  controller: dimensions,
                  decoration:
                      const InputDecoration(labelText: 'Dimensions')),
              const SizedBox(height: 10),
              TextField(
                  controller: location,
                  decoration: const InputDecoration(
                      labelText: 'Installation location')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextField(
                      controller: quantity,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Qty')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Unit price (₹)')),
                ),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (saved == true) {
      setState(() {
        final qty = int.tryParse(quantity.text) ?? 1;
        final unitPrice = double.tryParse(price.text) ?? 0;
        if (existing == null) {
          _items.add(ProposalLineItem(
            description: description.text.trim(),
            dimensions: dimensions.text.trim(),
            location: location.text.trim(),
            quantity: qty,
            unitPrice: unitPrice,
          ));
        } else {
          existing
            ..description = description.text.trim()
            ..dimensions = dimensions.text.trim()
            ..location = location.text.trim()
            ..quantity = qty
            ..unitPrice = unitPrice;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final gst = _subtotal * AppConfig.gstRate;

    return Scaffold(
      appBar: AppBar(title: const Text('Proposal Generator')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-item',
        onPressed: () => _editItem(),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: GlassCard(
                child: Row(
                  children: [
                    Icon(widget.client.category.icon,
                        color: DVColors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.client.businessName,
                              style: text.titleMedium),
                          Text(
                              '${widget.client.projects.length} mockup(s) will be attached',
                              style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Line items'),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  onTap: () => _editItem(item),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.description,
                                style: text.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                                '${item.dimensions} • ${item.location} • Qty ${item.quantity}',
                                style: text.bodySmall),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_currency.format(item.total),
                              style: text.titleMedium!
                                  .copyWith(color: DVColors.orange)),
                          InkWell(
                            onTap: () =>
                                setState(() => _items.remove(item)),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline,
                                  size: 18, color: DVColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  _totalRow('Subtotal', _currency.format(_subtotal)),
                  _totalRow(
                      'GST (${(AppConfig.gstRate * 100).toStringAsFixed(0)}%)',
                      _currency.format(gst)),
                  const Divider(height: 20),
                  _totalRow('Grand total',
                      _currency.format(_subtotal + gst),
                      bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _building || _items.isEmpty ? null : _generate,
              icon: _building
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                  _building ? 'Generating PDF…' : 'Generate & share PDF'),
            ),
            const SizedBox(height: 8),
            Text(
              'The PDF includes client details, attached mockups, dimensions, '
              'quantities, pricing with GST, your company logo and a '
              'signature section. Share it via WhatsApp, email or save it.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final text = Theme.of(context).textTheme;
    final style = bold
        ? text.titleMedium!.copyWith(color: DVColors.orange)
        : text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
