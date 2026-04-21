import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../main.dart';
import '../core/constants.dart';

class EtkinlikOlusturEkrani extends StatefulWidget {
  const EtkinlikOlusturEkrani({super.key});

  @override
  State<EtkinlikOlusturEkrani> createState() => _EtkinlikOlusturEkraniState();
}

class _EtkinlikOlusturEkraniState extends State<EtkinlikOlusturEkrani> {
  final _formKey = GlobalKey<FormState>();
  bool _yukleniyor = false;
  String _seciliKategori = 'Teknoloji';
  bool _fotoSecildi = false;
  XFile? _seciliFoto;
  Uint8List? _seciliFotoBytes;
  String? _editEventId;
  String? _existingImageUrl;
  bool _argsLoaded = false;

  // Form kontrolcüleri
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  final _konumController = TextEditingController();
  final _tarihController = TextEditingController();
  final _saatController = TextEditingController();
  final _fiyatController = TextEditingController(text: '0');
  final _kontenjanController = TextEditingController();

  // Kategori ID eşlemesi (backend seed'e göre)
  static const Map<String, String> _kategoriIdler = {
    'Spor':       '11111111-0000-0000-0000-000000000001',
    'Teknoloji':  '11111111-0000-0000-0000-000000000002',
    'Müzik':      '11111111-0000-0000-0000-000000000003',
    'Sanat':      '11111111-0000-0000-0000-000000000004',
    'Kariyer':    '11111111-0000-0000-0000-000000000005',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['event'] is Map<String, dynamic>) {
      final event = args['event'] as Map<String, dynamic>;
      _editEventId = event['id']?.toString();
      _existingImageUrl = event['imageUrl']?.toString();
      _fotoSecildi = (_existingImageUrl ?? '').isNotEmpty;
      _baslikController.text = event['title']?.toString() ?? '';
      _aciklamaController.text = event['description']?.toString() ?? '';
      _konumController.text = event['location']?.toString() ?? '';
      _fiyatController.text = ((event['price'] as num?) ?? 0).toString();
      _kontenjanController.text = ((event['quota'] as num?) ?? 100).toString();

      final categoryId = event['categoryId']?.toString().toLowerCase();
      for (final entry in _kategoriIdler.entries) {
        if (entry.value.toLowerCase() == categoryId) {
          _seciliKategori = entry.key;
          break;
        }
      }

      final dt = DateTime.tryParse(event['date']?.toString() ?? '')?.toLocal();
      if (dt != null) {
        _tarihController.text = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        _saatController.text = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    _konumController.dispose();
    _tarihController.dispose();
    _saatController.dispose();
    _fiyatController.dispose();
    _kontenjanController.dispose();
    super.dispose();
  }

  Future<void> _etkinlikKaydet() async {
    if (!_fotoSecildi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir etkinlik afişi yükleyin!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _yukleniyor = true);

    try {
      // Tarih ve saat birleştir
      final tarihMetni = _tarihController.text.trim();   // "GG/AA/YYYY"
      final saatMetni = _saatController.text.trim();     // "HH:MM"
      DateTime? etkinlikTarihi;

      try {
        final parcalar = tarihMetni.split('/');
        if (parcalar.length == 3) {
          final gun = int.parse(parcalar[0]);
          final ay  = int.parse(parcalar[1]);
          final yil = int.parse(parcalar[2]);
          final saatParcalar = saatMetni.split(':');
          final saat   = saatParcalar.isNotEmpty ? int.tryParse(saatParcalar[0]) ?? 0 : 0;
          final dakika = saatParcalar.length > 1  ? int.tryParse(saatParcalar[1]) ?? 0 : 0;
          etkinlikTarihi = DateTime(yil, ay, gun, saat, dakika);
        }
      } catch (_) {
        etkinlikTarihi = DateTime.now().add(const Duration(days: 7));
      }

      final token = CampusHubApp.tokenNotifier.value;
      final url = Uri.parse('${AppConstants.apiUrl}/Events');
      final imageUrl = _seciliFoto == null ? (_existingImageUrl ?? '') : await _fotoYukle();

      final body = {
        'title':       _baslikController.text.trim(),
        'description': _aciklamaController.text.trim(),
        'date':        (etkinlikTarihi ?? DateTime.now()).toIso8601String(),
        'location':    _konumController.text.trim(),
        'address':     _konumController.text.trim(),
        'price':       double.tryParse(_fiyatController.text.trim()) ?? 0.0,
        'quota':       int.tryParse(_kontenjanController.text.trim()) ?? 100,
        'imageUrl':    imageUrl,
        'categoryId':  _kategoriIdler[_seciliKategori],
        // Kulüp girişiyse login'den gelen clubId'yi gönder, öğrenciyse null
        'clubId':      CampusHubApp.userNotifier.value?['clubId'],
      };

      final response = _editEventId == null
          ? await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
          : await http.put(
              Uri.parse('${AppConstants.apiUrl}/Events/$_editEventId'),
              headers: {
                'Content-Type': 'application/json',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({...body, 'isActive': true}),
            );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editEventId == null ? 'Etkinlik başarıyla oluşturuldu!' : 'Etkinlik başarıyla güncellendi!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // true = yenileme sinyali
      } else {
        final hata = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${hata['message'] ?? response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sunucuya bağlanılamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _fotoSec() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _seciliFoto = picked;
      _seciliFotoBytes = bytes;
      _fotoSecildi = true;
    });
  }

  Future<String> _fotoYukle() async {
    if (_seciliFoto == null || _seciliFotoBytes == null) {
      throw Exception('Lutfen bir fotograf secin.');
    }

    final token = CampusHubApp.tokenNotifier.value;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.apiUrl}/Events/upload-image'),
    );
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        _seciliFotoBytes!,
        filename: _seciliFoto!.name,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(response.body.isEmpty ? 'Fotograf yuklenemedi.' : response.body);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['imageUrl']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editEventId == null ? 'Yeni Etkinlik Oluştur' : 'Etkinliği Düzenle', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _yukleniyor
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                  SizedBox(height: 16),
                  Text('Etkinlik yayınlanıyor...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ETKİNLİK AFİŞİ
                    const Text('Etkinlik Afişi', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _fotoSec,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _fotoSecildi ? const Color(0xFF1D4ED8) : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: _fotoSecildi
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: _seciliFotoBytes != null
                                        ? Image.memory(_seciliFotoBytes!, fit: BoxFit.cover)
                                        : Image.network(AppConstants.resolveUrl(_existingImageUrl!), fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor:
                                          Theme.of(context).brightness == Brightness.dark
                                              ? Colors.grey[900]
                                              : Colors.white,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => setState(() {
                                          _fotoSecildi = false;
                                          _seciliFoto = null;
                                          _seciliFotoBytes = null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text('Afiş veya Fotoğraf Yükle',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text('PNG, JPG (Maks. 5MB)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BAŞLIK
                    const Text('Etkinlik Başlığı', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _baslikController,
                      decoration: InputDecoration(
                        hintText: 'Örn: Yapay Zeka Zirvesi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Lütfen bir başlık girin' : null,
                    ),
                    const SizedBox(height: 20),

                    // KATEGORİ
                    const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _seciliKategori,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _kategoriIdler.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                      onChanged: (v) => setState(() => _seciliKategori = v!),
                    ),
                    const SizedBox(height: 20),

                    // TARİH VE SAAT
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tarih', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _tarihController,
                                decoration: InputDecoration(
                                  hintText: 'GG/AA/YYYY',
                                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    _tarihController.text =
                                        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                  }
                                },
                                readOnly: true,
                                validator: (v) => (v == null || v.isEmpty) ? 'Tarih seçin' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saat', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _saatController,
                                decoration: InputDecoration(
                                  hintText: '00:00',
                                  prefixIcon: const Icon(Icons.access_time, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    _saatController.text =
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  }
                                },
                                readOnly: true,
                                validator: (v) => (v == null || v.isEmpty) ? 'Saat seçin' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // KONUM
                    const Text('Konum', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _konumController,
                      decoration: InputDecoration(
                        hintText: 'Örn: Mühendislik Fak. Konferans Salonu',
                        prefixIcon: const Icon(Icons.location_on, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Lütfen bir konum belirtin' : null,
                    ),
                    const SizedBox(height: 20),

                    // FİYAT VE KONTENJAN
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fiyat (₺)', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fiyatController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0 = Ücretsiz',
                                  prefixIcon: const Icon(Icons.attach_money, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Boş bırakılamaz';
                                  if (double.tryParse(v) == null) return 'Geçerli sayı girin';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kontenjan', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _kontenjanController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Örn: 100',
                                  prefixIcon: const Icon(Icons.people_outline, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Boş bırakılamaz';
                                  if (int.tryParse(v) == null) return 'Geçerli sayı girin';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // AÇIKLAMA
                    const Text('Açıklama', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _aciklamaController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Etkinlik hakkında detaylı bilgi verin...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Lütfen bir açıklama girin' : null,
                    ),
                    const SizedBox(height: 40),

                    // YAYINLA BUTONU
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _etkinlikKaydet,
                        child: Text(_editEventId == null ? 'Etkinliği Yayınla' : 'Değişiklikleri Kaydet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
