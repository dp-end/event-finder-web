import 'package:flutter/material.dart';
import '../services/api_client.dart';

class KulupKesfetEkrani extends StatefulWidget {
  const KulupKesfetEkrani({super.key});

  @override
  State<KulupKesfetEkrani> createState() => _KulupKesfetEkraniState();
}

class _KulupKesfetEkraniState extends State<KulupKesfetEkrani> {
  String _aramaMetni = '';
  List<Map<String, dynamic>> _kulupListesi = [];
  bool _yukleniyor = true;
  String? _hata;
  final Map<String, bool> _busyMap = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final result = await ApiClient.get('/Clubs') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _kulupListesi = result.cast<Map<String, dynamic>>();
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  Future<void> _takipTetikle(Map<String, dynamic> kulup) async {
    final id = kulup['id']?.toString();
    if (id == null || (_busyMap[id] ?? false)) return;
    if (!ApiClient.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Takip etmek için giriş yapmalısınız.')),
      );
      return;
    }

    setState(() => _busyMap[id] = true);
    try {
      final result = await ApiClient.post('/Clubs/$id/follow') as Map<String, dynamic>;
      final following = result['following'] == true;
      final followerCount = (result['followerCount'] as num?)?.toInt();
      if (!mounted) return;
      setState(() {
        kulup['isFollowedByCurrentUser'] = following;
        if (followerCount != null) kulup['followerCount'] = followerCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(following ? '${kulup['name']} takip edildi.' : 'Takipten çıkıldı.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busyMap[id] = false);
    }
  }

  List<Map<String, dynamic>> get _filtrelenmisListe {
    if (_aramaMetni.isEmpty) return _kulupListesi;
    final aranan = _aramaMetni.toLowerCase();
    return _kulupListesi.where((k) {
      final ad = (k['name'] ?? '').toString().toLowerCase();
      final aciklama = (k['description'] ?? '').toString().toLowerCase();
      return ad.contains(aranan) || aciklama.contains(aranan);
    }).toList();
  }

  String _formatSayi(int sayi) {
    if (sayi >= 1000) return '${(sayi / 1000).toStringAsFixed(1)}K';
    return sayi.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kulüpleri Keşfet', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _yukle),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _aramaMetni = v),
              decoration: InputDecoration(
                hintText: 'Kulüp ara...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _govde(isDark)),
        ],
      ),
    );
  }

  Widget _govde(bool isDark) {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: Color(0xFF1D4ED8)));

    if (_hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_hata!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _yukle,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final liste = _filtrelenmisListe;
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Kulüp bulunamadı.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: liste.length,
        itemBuilder: (context, index) => _kulupKarti(liste[index], isDark),
      ),
    );
  }

  Widget _kulupKarti(Map<String, dynamic> kulup, bool isDark) {
    final id = kulup['id']?.toString() ?? '';
    final ad = kulup['name']?.toString() ?? 'Kulüp';
    final kisaltma = kulup['initials']?.toString() ?? ad.substring(0, ad.length >= 2 ? 2 : 1).toUpperCase();
    final aciklama = kulup['description']?.toString() ?? '';
    final takipci = (kulup['followerCount'] as num?)?.toInt() ?? 0;
    final etkinlik = (kulup['eventCount'] as num?)?.toInt() ?? 0;
    final takipEdiliyor = kulup['isFollowedByCurrentUser'] == true;
    final busy = _busyMap[id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          '/club-profile',
          arguments: {'clubId': id, 'kulupAdi': ad},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                child: Text(kisaltma, style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    if (aciklama.isNotEmpty)
                      Text(aciklama, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('${_formatSayi(takipci)} takipçi', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        const SizedBox(width: 12),
                        Icon(Icons.event_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('$etkinlik etkinlik', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              busy
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                      onTap: () => _takipTetikle(kulup),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: takipEdiliyor ? Colors.green.withValues(alpha: 0.12) : const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: takipEdiliyor ? Colors.green : const Color(0xFF1D4ED8), width: 1.5),
                        ),
                        child: Text(
                          takipEdiliyor ? 'Takipte' : 'Takip Et',
                          style: TextStyle(
                            color: takipEdiliyor ? Colors.green : const Color(0xFF1D4ED8),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
