import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/api_client.dart';

class EtkinlikKarti extends StatefulWidget {
  final String baslik;
  final String kulup;
  final String fiyat;
  final String resimUrl;
  final String tarih;
  final String? etkinlikId;
  final String? clubId;
  final String? ownerId;
  final int likeCount;
  final bool isLiked;

  const EtkinlikKarti({
    super.key,
    required this.baslik,
    required this.kulup,
    required this.fiyat,
    required this.resimUrl,
    required this.tarih,
    this.etkinlikId,
    this.clubId,
    this.ownerId,
    this.likeCount = 0,
    this.isLiked = false,
  });

  @override
  State<EtkinlikKarti> createState() => _EtkinlikKartiState();
}

class _EtkinlikKartiState extends State<EtkinlikKarti> {
  late bool _liked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.isLiked;
    _likeCount = widget.likeCount;
  }

  Future<void> _toggleLike() async {
    if (widget.etkinlikId == null || widget.etkinlikId!.isEmpty) return;
    if (!ApiClient.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Begenmek icin giris yapmalisiniz.')));
      return;
    }

    final oldLiked = _liked;
    final oldCount = _likeCount;
    setState(() {
      _liked = !_liked;
      _likeCount = _liked ? _likeCount + 1 : (_likeCount > 0 ? _likeCount - 1 : 0);
    });

    try {
      final result = await ApiClient.post('/Events/${widget.etkinlikId}/like') as Map<String, dynamic>;
      final liked = result['liked'] == true;
      if (!mounted) return;
      setState(() {
        _liked = liked;
        _likeCount = liked ? oldCount + 1 : (oldCount > 0 ? oldCount - 1 : 0);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = oldLiked;
        _likeCount = oldCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: {
        if (widget.etkinlikId != null) 'etkinlikId': widget.etkinlikId,
      }),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  AppConstants.resolveUrl(widget.resimUrl),
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _imageFallback(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.fiyat == 'Ucretsiz' ? Colors.green : const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.fiyat, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _openOrganizer,
                      child: Text(widget.kulup, style: TextStyle(fontSize: 10, color: Colors.blue[700], fontWeight: FontWeight.bold), maxLines: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.baslik, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(widget.tarih, style: TextStyle(fontSize: 11, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _toggleLike,
                          child: Row(
                            children: [
                              Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 16, color: _liked ? Colors.red : Colors.grey),
                              const SizedBox(width: 4),
                              Text('$_likeCount', style: TextStyle(fontSize: 11, color: _liked ? Colors.red : Colors.grey[700])),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: {'etkinlikId': widget.etkinlikId}),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 4),
                              Text('Yorum', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                            ],
                          ),
                        ),
                        Icon(Icons.share, size: 16, color: Colors.grey[700]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openOrganizer() {
    if (widget.clubId != null && widget.clubId!.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/club-profile',
        arguments: {'clubId': widget.clubId, 'kulupAdi': widget.kulup},
      );
      return;
    }

    if (widget.ownerId != null && widget.ownerId!.isNotEmpty) {
      Navigator.pushNamed(context, '/person-profile', arguments: {'userId': widget.ownerId});
    }
  }

  Widget _imageFallback() {
    return Container(
      height: 110,
      width: double.infinity,
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF1D4ED8)),
    );
  }
}
