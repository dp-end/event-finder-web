import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../services/api_client.dart';
import '../../widgets/etkinlik_karti.dart';
import 'profili_duzenle_ekrani.dart';

class KisiProfilEkrani extends StatefulWidget {
  const KisiProfilEkrani({super.key});

  @override
  State<KisiProfilEkrani> createState() => _KisiProfilEkraniState();
}

class _KisiProfilEkraniState extends State<KisiProfilEkrani> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _createdEvents = [];
  List<Map<String, dynamic>> _attendedEvents = [];
  String? _userId;
  bool _isCurrentUser = false;
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _userId = args['userId']?.toString() ?? args['ownerId']?.toString();
    }
    _userId ??= ApiClient.currentUserId;
    _isCurrentUser = _userId != null && _userId == ApiClient.currentUserId;
    _load();
  }

  Future<void> _load() async {
    if (_userId == null || _userId!.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Kullanici bulunamadi.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await ApiClient.get(_isCurrentUser ? '/Account/me' : '/Account/public/$_userId') as Map<String, dynamic>;
      final created = await ApiClient.get(_isCurrentUser ? '/Events/mine' : '/Events/owner/$_userId') as List<dynamic>;
      final attended = await ApiClient.get('/Events/attendee/$_userId') as List<dynamic>;

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _createdEvents = created.cast<Map<String, dynamic>>();
        _attendedEvents = attended.cast<Map<String, dynamic>>();
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
        appBar: AppBar(title: const Text('Profil')),
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
    final image = profile['profileImageUrl']?.toString() ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isCurrentUser ? 'Profilim' : name),
          actions: [
            if (_isCurrentUser)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilDuzenleEkrani()),
                  );
                  if (changed == true) _load();
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Katildigi'),
              Tab(text: 'Olusturdugu'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTabContent(
                      name: name,
                      image: image,
                      profile: profile,
                      value: '${profile['ticketCount'] ?? _attendedEvents.length}',
                      label: _isCurrentUser ? 'Katildigim Etkinlikler' : 'Katildigi Etkinlikler',
                      events: _attendedEvents,
                      emptyMessage: _isCurrentUser
                          ? 'Henuz katildigin etkinlik yok.'
                          : 'Bu kullanicinin katildigi etkinlik bulunamadi.',
                    ),
                    _buildTabContent(
                      name: name,
                      image: image,
                      profile: profile,
                      value: '${profile['createdEventCount'] ?? _createdEvents.length}',
                      label: _isCurrentUser ? 'Olusturdugum Etkinlikler' : 'Olusturdugu Etkinlikler',
                      events: _createdEvents,
                      emptyMessage: _isCurrentUser
                          ? 'Henuz olusturdugun etkinlik yok.'
                          : 'Bu kullanicinin aktif etkinligi yok.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required String name,
    required String image,
    required Map<String, dynamic> profile,
    required String value,
    required String label,
    required List<Map<String, dynamic>> events,
    required String emptyMessage,
  }) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundImage: image.isNotEmpty ? NetworkImage(AppConstants.resolveUrl(image)) : null,
            child: image.isEmpty ? Text(_initials(name), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)) : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        if ((profile['university'] ?? '').toString().isNotEmpty)
          Center(child: Text(profile['university'].toString(), style: const TextStyle(color: Colors.grey))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stat('${profile['followingClubCount'] ?? 0}', 'Takip'),
            _separator(),
            _stat(value, 'Etkinlik'),
          ],
        ),
        const Divider(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(emptyMessage, textAlign: TextAlign.center),
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
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              final price = (e['price'] as num?) ?? 0;
              return EtkinlikKarti(
                baslik: e['title']?.toString() ?? '',
                kulup: e['organizerName']?.toString() ?? e['clubName']?.toString() ?? name,
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
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );

  Widget _separator() => Container(width: 1, height: 32, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 16));

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
