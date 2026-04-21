import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../main.dart';
import '../../services/api_client.dart';
import '../../widgets/etkinlik_karti.dart';
import 'profili_duzenle_ekrani.dart';

class KulupProfilEkrani extends StatefulWidget {
  const KulupProfilEkrani({super.key});

  @override
  State<KulupProfilEkrani> createState() => _KulupProfilEkraniState();
}

class _KulupProfilEkraniState extends State<KulupProfilEkrani> {
  Map<String, dynamic>? _club;
  List<Map<String, dynamic>> _events = [];
  String? _clubId;
  String? _clubName;
  bool _isCurrentClub = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clubId != null || _clubName != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _clubId = args['clubId']?.toString();
      _clubName = args['kulupAdi']?.toString();
    }
    _resolveCurrentClubState();
    _load();
  }

  void _resolveCurrentClubState() {
    final currentClubId = CampusHubApp.userNotifier.value?['clubId']?.toString();
    final currentUserId = ApiClient.currentUserId;
    _isCurrentClub = CampusHubApp.userTypeNotifier.value == 'club' &&
        ((_clubId != null && _clubId == currentClubId) || (_clubId != null && _clubId == currentUserId));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? id = _clubId;
      if (id == null || id.isEmpty) {
        final currentClubId = CampusHubApp.userNotifier.value?['clubId']?.toString() ?? ApiClient.currentUserId;
        if (CampusHubApp.userTypeNotifier.value == 'club' && currentClubId != null && currentClubId.isNotEmpty) {
          id = currentClubId;
        }
      }
      if (id == null || id.isEmpty) {
        final clubs = await ApiClient.get('/Clubs') as List<dynamic>;
        final match = clubs.cast<Map<String, dynamic>>().where((c) => c['name']?.toString() == _clubName).toList();
        if (match.isEmpty) throw const ApiException('Kulup bulunamadi.');
        id = match.first['id']?.toString();
      }

      final club = await ApiClient.get('/Clubs/$id') as Map<String, dynamic>;
      final events = await ApiClient.get('/Events/club/$id') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _clubId = id;
        _resolveCurrentClubState();
        _club = club;
        _events = events.cast<Map<String, dynamic>>();
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

  Future<void> _toggleFollow() async {
    if (!ApiClient.isAuthenticated) {
      _show('Takip etmek icin giris yapmalisiniz.');
      return;
    }
    if (_clubId == null || _busy) return;

    setState(() => _busy = true);
    try {
      final result = await ApiClient.post('/Clubs/$_clubId/follow') as Map<String, dynamic>;
      final following = result['following'] == true;
      setState(() {
        _club!['isFollowedByCurrentUser'] = following;
        final countFromServer = (result['followerCount'] as num?)?.toInt();
        if (countFromServer != null) {
          _club!['followerCount'] = countFromServer;
        } else {
          final count = (_club?['followerCount'] as num?)?.toInt() ?? 0;
          _club!['followerCount'] = following ? count + 1 : (count > 0 ? count - 1 : 0);
        }
      });
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kulup Profili')),
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

    final club = _club!;
    final name = club['name']?.toString() ?? 'Kulup';
    final cover = (club['coverImageUrl'] ?? '').toString().isEmpty
        ? 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=800'
        : AppConstants.resolveUrl(club['coverImageUrl'].toString());
    final followed = club['isFollowedByCurrentUser'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCurrentClub ? 'Kulup Profilim' : '$name Profili'),
        actions: [
          if (_isCurrentClub)
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
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Image.network(cover, height: 150, width: double.infinity, fit: BoxFit.cover),
                  Positioned(
                    bottom: -40,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: CircleAvatar(
                        radius: 40,
                        child: Text(_initials(club['initials']?.toString() ?? name), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 52),
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(club['description']?.toString() ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              Text('${club['followerCount'] ?? 0} takipci - ${club['eventCount'] ?? 0} etkinlik'),
              const SizedBox(height: 16),
              if (!_isCurrentClub)
                ElevatedButton.icon(
                  onPressed: _busy ? null : _toggleFollow,
                  icon: Icon(followed ? Icons.check : Icons.person_add, size: 18),
                  label: Text(followed ? 'Takip ediliyor' : 'Takip et'),
                )
              else
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilDuzenleEkrani()),
                          );
                          if (changed == true) _load();
                        },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Duzenle'),
                ),
              const Divider(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(alignment: Alignment.centerLeft, child: Text('$name Etkinlikleri', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ),
              if (_events.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(_isCurrentClub ? 'Henuz aktif etkinliginiz yok.' : 'Bu kulubun aktif etkinligi yok.'),
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
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final e = _events[index];
                    final price = (e['price'] as num?) ?? 0;
                    return EtkinlikKarti(
                      baslik: e['title']?.toString() ?? '',
                      kulup: e['clubName']?.toString() ?? name,
                      fiyat: price == 0 ? 'Ucretsiz' : 'TL ${price.toStringAsFixed(0)}',
                      resimUrl: e['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400',
                      tarih: _formatDate(e['date']?.toString()),
                      etkinlikId: e['id']?.toString(),
                      clubId: e['clubId']?.toString() ?? _clubId,
                      ownerId: e['ownerId']?.toString(),
                      likeCount: (e['likeCount'] as num?)?.toInt() ?? 0,
                      isLiked: e['isLikedByCurrentUser'] == true,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'Tarih belirtilmedi';
    try {
      final dt = DateTime.parse(value).toLocal();
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return value;
    }
  }

  String _initials(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return '?';
    return cleaned.length >= 2 ? cleaned.substring(0, 2).toUpperCase() : cleaned.toUpperCase();
  }
}
