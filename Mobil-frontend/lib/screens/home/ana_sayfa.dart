import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../main.dart';
import '../../widgets/etkinlik_karti.dart';
import '../../widgets/sol_yan_menu.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  String _aramaMetni = '';
  String _seciliKategori = 'Tümü';
  String _seciliEtkinlikTipi = 'Tümü';
  bool _sadeceUcretsiz = false;
  double _maxFiyat = 200;
  String _seciliZaman = 'Tümü';

  List<Map<String, dynamic>> _etkinlikler = [];
  List<Map<String, dynamic>> _populerKulupler = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _etkinlikleriYukle();
  }

  Future<void> _etkinlikleriYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final token = CampusHubApp.tokenNotifier.value;
      final params = <String, String>{};

      if (_aramaMetni.isNotEmpty) params['query'] = _aramaMetni;
      if (_seciliKategori != 'Tümü') params['category'] = _seciliKategori;
      if (_seciliEtkinlikTipi != 'Tümü') {
        params['eventType'] = _seciliEtkinlikTipi == 'Kulüp Etkinlikleri' ? 'club' : 'individual';
      }
      if (_sadeceUcretsiz) params['freeOnly'] = 'true';
      if (!_sadeceUcretsiz && _maxFiyat < 500) params['maxPrice'] = _maxFiyat.toStringAsFixed(0);
      if (_seciliZaman != 'Tümü') params['timePeriod'] = _seciliZaman;

      final url = Uri.parse('${AppConstants.apiUrl}/Events').replace(
        queryParameters: params.isEmpty ? null : params,
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _hata = 'Etkinlikler yuklenemedi (${response.statusCode})';
          _yukleniyor = false;
        });
        return;
      }

      final liste = jsonDecode(response.body) as List<dynamic>;
      final clubsUrl = Uri.parse('${AppConstants.apiUrl}/Clubs/popular').replace(
        queryParameters: {'count': '5'},
      );
      final clubsResponse = await http.get(
        clubsUrl,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final clubs = clubsResponse.statusCode == 200
          ? (jsonDecode(clubsResponse.body) as List<dynamic>).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      setState(() {
        _etkinlikler = liste.cast<Map<String, dynamic>>();
        _populerKulupler = clubs;
        _yukleniyor = false;
      });
    } catch (_) {
      setState(() {
        _hata = 'Sunucuya baglanilamadi';
        _yukleniyor = false;
        _etkinlikler = [];
      });
    }
  }

  void _filtreMenusuAc(BuildContext context) {
    bool modalUcretsiz = _sadeceUcretsiz;
    double modalMaxFiyat = _maxFiyat;
    String modalZaman = _seciliZaman;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Gelismis Filtre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Divider(height: 30),
                  const Text('Fiyat Secenekleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Sadece Ucretsiz Etkinlikler', style: TextStyle(fontWeight: FontWeight.w500)),
                    value: modalUcretsiz,
                    activeThumbColor: const Color(0xFF1D4ED8),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (deger) => setModalState(() => modalUcretsiz = deger),
                  ),
                  if (!modalUcretsiz) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Maksimum Fiyat:'),
                        Text(
                          'TL ${modalMaxFiyat.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: modalMaxFiyat,
                      min: 10,
                      max: 500,
                      divisions: 49,
                      activeColor: const Color(0xFF1D4ED8),
                      onChanged: (deger) => setModalState(() => modalMaxFiyat = deger),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Zaman Dilimi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Tümü', 'Bugün', 'Bu Hafta', 'Bu Ay'].map((tarih) {
                      final isSelected = modalZaman == tarih;
                      return ChoiceChip(
                        label: Text(tarih),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF1D4ED8) : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setModalState(() => modalZaman = tarih),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _sadeceUcretsiz = modalUcretsiz;
                          _maxFiyat = modalMaxFiyat;
                          _seciliZaman = modalZaman;
                        });
                        Navigator.pop(context);
                        _etkinlikleriYukle();
                      },
                      child: const Text('Sonuclari Goster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gosterilenListe = _aramaMetni.isEmpty
        ? _etkinlikler
        : _etkinlikler.where((etkinlik) {
            final baslik = (etkinlik['title'] ?? '').toString().toLowerCase();
            final kulup = (etkinlik['clubName'] ?? etkinlik['organizerName'] ?? '').toString().toLowerCase();
            return baslik.contains(_aramaMetni.toLowerCase()) || kulup.contains(_aramaMetni.toLowerCase());
          }).toList();

    return Scaffold(
      drawer: const SolYanMenu(),
      appBar: AppBar(
        title: const Text('Event Finder', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.tune), onPressed: () => _filtreMenusuAc(context)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _etkinlikleriYukle),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _etkinlikleriYukle,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: (deger) => setState(() => _aramaMetni = deger),
                  decoration: InputDecoration(
                    hintText: 'Etkinlik, kulup ara...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: ['Tümü', 'Spor', 'Teknoloji', 'Müzik', 'Sanat', 'Kariyer'].map((kategori) {
                    final isSelected = kategori == _seciliKategori;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(kategori),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1D4ED8),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() => _seciliKategori = kategori);
                          _etkinlikleriYukle();
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Tümü', 'Kulüp Etkinlikleri', 'Bireysel Etkinlikler'].map((tip) {
                      final isSelected = tip == _seciliEtkinlikTipi;
                      return ChoiceChip(
                        label: Text(tip),
                        selected: isSelected,
                        selectedColor: const Color(0xFF1D4ED8),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setState(() => _seciliEtkinlikTipi = tip);
                          _etkinlikleriYukle();
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Haftanin En Populer Kulupleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _populerKulupler.isEmpty
                      ? [_buildKulupKutusu(context, 'EF', 'Event Finder', isDark, null)]
                      : _populerKulupler.map((club) {
                          final name = club['name']?.toString() ?? 'Kulup';
                          final initials = club['initials']?.toString() ?? _kulupBasHarfleri(name);
                          return _buildKulupKutusu(context, initials, name, isDark, club['id']?.toString());
                        }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yaklasan Etkinlikler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (!_yukleniyor) Text('${gosterilenListe.length} sonuc', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (_yukleniyor)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                )
              else if (_hata != null)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_hata!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _etkinlikleriYukle,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (gosterilenListe.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Aradiginiz kritere uygun etkinlik bulunamadi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: gosterilenListe.length,
                  itemBuilder: (context, index) {
                    final etkinlik = gosterilenListe[index];
                    final fiyat = (etkinlik['price'] as num?) ?? 0;
                    return EtkinlikKarti(
                      baslik: etkinlik['title']?.toString() ?? '',
                      kulup: etkinlik['organizerName']?.toString() ?? etkinlik['clubName']?.toString() ?? 'Kullanici Etkinligi',
                      fiyat: fiyat == 0 ? 'Ucretsiz' : 'TL ${fiyat.toStringAsFixed(0)}',
                      tarih: etkinlik['date'] != null ? _formatTarih(etkinlik['date'].toString()) : 'Tarih belirtilmemis',
                      resimUrl: etkinlik['imageUrl']?.toString() ?? 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400',
                      etkinlikId: etkinlik['id']?.toString(),
                      clubId: etkinlik['clubId']?.toString(),
                      ownerId: etkinlik['ownerId']?.toString(),
                      likeCount: (etkinlik['likeCount'] as num?)?.toInt() ?? 0,
                      isLiked: etkinlik['isLikedByCurrentUser'] == true,
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final sonuc = await Navigator.pushNamed(context, '/create-event');
          if (sonuc == true) _etkinlikleriYukle();
        },
        backgroundColor: const Color(0xFF1D4ED8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatTarih(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} ${_ayAdi(dt.month)} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _ayAdi(int ay) {
    const aylar = ['Oca', 'Sub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Agu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return aylar[ay - 1];
  }

  Widget _buildKulupKutusu(BuildContext context, String harf, String isim, bool isDark, String? clubId) {
    final args = <String, String>{'kulupAdi': isim};
    if (clubId != null) args['clubId'] = clubId;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/club-profile', arguments: args),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
              child: Text(harf, style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(isim, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  String _kulupBasHarfleri(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return 'KL';
    return cleaned.length >= 2 ? cleaned.substring(0, 2).toUpperCase() : cleaned.toUpperCase();
  }
}
