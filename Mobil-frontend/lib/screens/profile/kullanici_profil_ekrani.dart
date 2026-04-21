import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../services/api_client.dart';
import '../../widgets/etkinlik_karti.dart';

class KullaniciProfilEkrani extends StatefulWidget {
  const KullaniciProfilEkrani({super.key});

  @override
  State<KullaniciProfilEkrani> createState() => _KullaniciProfilEkraniState();
}

class _KullaniciProfilEkraniState extends State<KullaniciProfilEkrani> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _tickets = [];
  List<Map<String, dynamic>> _createdEvents = [];
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
      final profile = await ApiClient.get('/Account/me') as Map<String, dynamic>;
      final tickets = await ApiClient.get('/Tickets') as List<dynamic>;
      final created = await ApiClient.get('/Events/mine') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _tickets = tickets.cast<Map<String, dynamic>>();
        _createdEvents = created.cast<Map<String, dynamic>>();
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profilim')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Tekrar dene')),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final fullName = '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    final name = fullName.isEmpty ? profile['userName']?.toString() ?? 'Kullanici' : fullName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final changed = await Navigator.pushNamed(context, '/settings');
              if (changed == true) _load();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: -48,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundImage: (profile['profileImageUrl'] ?? '').toString().isNotEmpty
                          ? NetworkImage(AppConstants.resolveUrl(profile['profileImageUrl'].toString()))
                          : null,
                      child: (profile['profileImageUrl'] ?? '').toString().isEmpty
                          ? Text(_initials(name), style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 58),
            Center(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            Center(child: Text(profile['email']?.toString() ?? '', style: const TextStyle(color: Colors.grey))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat('${profile['ticketCount'] ?? _tickets.length}', 'Katildigi'),
                _separator(),
                _stat('${profile['followingClubCount'] ?? 0}', 'Takip'),
                _separator(),
                _stat('${profile['createdEventCount'] ?? _createdEvents.length}', 'Etkinlik'),
              ],
            ),
            const Divider(height: 40),
            _sectionTitle('Katildigim Etkinlikler'),
            if (_tickets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Henuz bilet aldigin etkinlik yok.', textAlign: TextAlign.center),
              )
            else
              ..._tickets.map((ticket) => ListTile(
                    leading: const Icon(Icons.confirmation_num_outlined),
                    title: Text(ticket['eventTitle']?.toString() ?? 'Etkinlik'),
                    subtitle: Text(_formatDate(ticket['eventDate']?.toString())),
                    onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: {'etkinlikId': ticket['eventId']?.toString()}),
                  )),
            const Divider(height: 40),
            _sectionTitle('Yukledigim Etkinlikler'),
            if (_createdEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Henuz etkinlik yuklemedin.', textAlign: TextAlign.center),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.70,
                ),
                itemCount: _createdEvents.length,
                itemBuilder: (context, index) {
                  final e = _createdEvents[index];
                  final price = (e['price'] as num?) ?? 0;
                  return EtkinlikKarti(
                    baslik: e['title']?.toString() ?? '',
                    kulup: e['clubName']?.toString() ?? e['organizerName']?.toString() ?? name,
                    fiyat: price == 0 ? 'Ucretsiz' : 'TL ${price.toStringAsFixed(0)}',
                    tarih: _formatDate(e['date']?.toString()),
                    resimUrl: e['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400',
                    etkinlikId: e['id']?.toString(),
                    clubId: e['clubId']?.toString(),
                    ownerId: e['ownerId']?.toString(),
                    likeCount: (e['likeCount'] as num?)?.toInt() ?? 0,
                    isLiked: e['isLikedByCurrentUser'] == true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );

  Widget _separator() => Container(width: 1, height: 32, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 16));

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      );

  String _initials(String value) {
    final parts = value.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return value.isEmpty ? '?' : value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final dt = DateTime.parse(value).toLocal();
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return value;
    }
  }
}
