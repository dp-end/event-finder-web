import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../services/api_client.dart';

class BiletlerimEkrani extends StatefulWidget {
  const BiletlerimEkrani({super.key});

  @override
  State<BiletlerimEkrani> createState() => _BiletlerimEkraniState();
}

class _BiletlerimEkraniState extends State<BiletlerimEkrani> {
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiClient.get('/Tickets') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _tickets = result.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biletlerim')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Tekrar dene')),
        ],
      );
    }

    if (_tickets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.confirmation_num_outlined, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text('Henuz biletiniz yok.', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _ticketCard(_tickets[index]),
    );
  }

  Widget _ticketCard(Map<String, dynamic> ticket) {
    final imageUrl = (ticket['eventImageUrl'] ?? '').toString().isEmpty
        ? 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=200'
        : AppConstants.resolveUrl(ticket['eventImageUrl'].toString());

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFEFF6FF),
                  child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF1D4ED8)),
                ),
              ),
            ),
            title: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                '/event-detail',
                arguments: {'etkinlikId': ticket['eventId']?.toString()},
              ),
              child: Text(
                ticket['eventTitle']?.toString() ?? 'Etkinlik',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(_formatDate(ticket['eventDate']?.toString())),
                Text(ticket['eventLocation']?.toString() ?? ''),
                if ((ticket['clubName'] ?? '').toString().isNotEmpty)
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/club-profile',
                      arguments: {
                        if (ticket['clubId'] != null) 'clubId': ticket['clubId']?.toString(),
                        'kulupAdi': ticket['clubName']?.toString(),
                      },
                    ),
                    child: Text(
                      ticket['clubName']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showQr(ticket),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2, size: 36, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ticket['ticketNumber']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(ticket['isUsed'] == true ? 'Kullanildi' : 'Gecerli', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/event-detail',
                    arguments: {'etkinlikId': ticket['eventId']?.toString()},
                  ),
                  child: const Text('Etkinlik'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQr(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket['ticketNumber']?.toString() ?? 'QR Kod', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 180),
            const SizedBox(height: 12),
            SelectableText(ticket['qrCode']?.toString() ?? ''),
            const SizedBox(height: 12),
            const Text('Giris gorevlisine bu kodu gosterin.', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
        ],
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Tarih belirtilmedi';
    try {
      final dt = DateTime.parse(value).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }
}
