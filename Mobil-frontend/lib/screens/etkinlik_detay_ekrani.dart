import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../main.dart';
import '../services/api_client.dart';

class EtkinlikDetayEkrani extends StatefulWidget {
  const EtkinlikDetayEkrani({super.key});

  @override
  State<EtkinlikDetayEkrani> createState() => _EtkinlikDetayEkraniState();
}

class _EtkinlikDetayEkraniState extends State<EtkinlikDetayEkrani> {
  Map<String, dynamic>? _event;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _commentsLoading = false;
  bool _busy = false;
  String? _error;
  String? _eventId;

  final _commentController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_eventId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _eventId = args['etkinlikId']?.toString() ?? args['id']?.toString();
    }

    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_eventId == null || _eventId!.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Etkinlik bulunamadi.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final event = await ApiClient.get('/Events/$_eventId') as Map<String, dynamic>;
      final comments = await ApiClient.get('/Comments/event/$_eventId') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _event = event;
        _comments = comments.cast<Map<String, dynamic>>();
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

  Future<void> _refreshComments() async {
    if (_eventId == null) return;
    setState(() => _commentsLoading = true);
    try {
      final comments = await ApiClient.get('/Comments/event/$_eventId') as List<dynamic>;
      if (mounted) setState(() => _comments = comments.cast<Map<String, dynamic>>());
    } finally {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _toggleLike() async {
    if (!_requireLogin()) return;
    if (_eventId == null || _busy) return;

    setState(() => _busy = true);
    try {
      final result = await ApiClient.post('/Events/$_eventId/like') as Map<String, dynamic>;
      final liked = result['liked'] == true;
      setState(() {
        _event!['isLikedByCurrentUser'] = liked;
        final current = (_event?['likeCount'] as num?)?.toInt() ?? 0;
        _event!['likeCount'] = liked ? current + 1 : (current > 0 ? current - 1 : 0);
      });
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (!_requireLogin()) return;
    final clubId = _event?['clubId']?.toString();
    if (clubId == null || clubId.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      final result = await ApiClient.post('/Clubs/$clubId/follow') as Map<String, dynamic>;
      final following = result['following'] == true;
      setState(() => _event!['isClubFollowedByCurrentUser'] = following);
      _show(following ? 'Kulup takip edildi.' : 'Takip birakildi.');
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchaseTicket() async {
    if (!_requireLogin()) return;
    if (CampusHubApp.userTypeNotifier.value == 'club') {
      _show('Kulup hesaplari bilet alamaz.');
      return;
    }
    if (_eventId == null || _busy) return;

    setState(() => _busy = true);
    try {
      final result = await ApiClient.post('/Tickets/purchase', body: {'eventId': _eventId});
      if (result is Map<String, dynamic>) {
        final remainingQuota = (result['remainingQuota'] as num?)?.toInt();
        if (remainingQuota != null && mounted) {
          setState(() {
            _event!['remainingQuota'] = remainingQuota;
            _event!['hasTicket'] = true;
          });
        }
      }
      await _load();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bilet hazir'),
          content: const Text('Biletiniz olusturuldu. Biletlerim sayfasindan goruntuleyebilirsiniz.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/my-tickets');
              },
              child: const Text('Biletlerim'),
            ),
          ],
        ),
      );
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addComment() async {
    if (!_requireLogin()) return;
    final text = _commentController.text.trim();
    if (text.isEmpty || _eventId == null || _busy) return;

    setState(() => _busy = true);
    try {
      await ApiClient.post('/Comments', body: {'eventId': _eventId, 'content': text});
      _commentController.clear();
      await _refreshComments();
      await _load();
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteComment(String id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ApiClient.delete('/Comments/$id');
      await _refreshComments();
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteEvent() async {
    if (_eventId == null || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Etkinlik silinsin mi?'),
        content: const Text('Bu etkinlik kalici olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgec')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ApiClient.delete('/Events/$_eventId');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Etkinlik silindi.')));
      Navigator.pop(context, true);
    } catch (e) {
      _show(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _requireLogin() {
    if (ApiClient.isAuthenticated) return true;
    _show('Bu islem icin giris yapmalisiniz.');
    return false;
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Etkinlik Detayi')),
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

    final event = _event!;
    final isLiked = event['isLikedByCurrentUser'] == true;
    final hasTicket = event['hasTicket'] == true;
    final isClub = CampusHubApp.userTypeNotifier.value == 'club';
    final isOwner = ApiClient.currentUserId != null && ApiClient.currentUserId == event['ownerId']?.toString();
    final imageUrl = (event['imageUrl'] ?? '').toString().isEmpty
        ? 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800'
        : AppConstants.resolveUrl(event['imageUrl'].toString());
    final price = (event['price'] as num?) ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFFEFF6FF),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined, size: 48, color: Color(0xFF1D4ED8)),
                ),
              ),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  onPressed: () async {
                    final changed = await Navigator.pushNamed(context, '/create-event', arguments: {'event': event});
                    if (changed == true) _load();
                  },
                  icon: const Icon(Icons.edit),
                ),
              if (isOwner)
                IconButton(
                  onPressed: _busy ? null : _deleteEvent,
                  icon: const Icon(Icons.delete_outline),
                ),
              IconButton(
                onPressed: _busy ? null : _toggleLike,
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title']?.toString() ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.calendar_today, text: _formatDate(event['date']?.toString())),
                  _InfoRow(icon: Icons.location_on, text: event['location']?.toString() ?? 'Konum belirtilmedi'),
                  if ((event['address'] ?? '').toString().isNotEmpty)
                    _InfoRow(icon: Icons.map_outlined, text: event['address'].toString()),
                  const Divider(height: 32),
                  Row(
                    children: [
                      CircleAvatar(child: Text(_initials(event['organizerInitials']?.toString() ?? event['clubInitials']?.toString() ?? event['organizerName']?.toString() ?? 'EF'))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openOrganizer(event),
                          child: Text(event['organizerName']?.toString() ?? event['clubName']?.toString() ?? 'Kullanici Etkinligi', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (event['clubId'] != null)
                        OutlinedButton(
                          onPressed: _busy ? null : _toggleFollow,
                          child: Text(event['isClubFollowedByCurrentUser'] == true ? 'Takip ediliyor' : 'Takip et'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('${event['likeCount'] ?? 0} begeni'),
                      const SizedBox(width: 16),
                      Text('${_comments.length} yorum'),
                      const SizedBox(width: 16),
                      Text('${event['remainingQuota'] ?? 0} kontenjan'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Etkinlik Hakkinda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event['description']?.toString() ?? '', style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 28),
                  const Text('Yorumlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_commentsLoading) const LinearProgressIndicator(),
                  if (_comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Henuz yorum yok.'),
                    )
                  else
                    ..._comments.map(_commentTile),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Yorum yaz...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(onPressed: _busy ? null : _addComment, icon: const Icon(Icons.send)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  price == 0 ? 'Ucretsiz' : 'TL ${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_busy || isClub) ? null : (hasTicket ? () => Navigator.pushNamed(context, '/my-tickets') : _purchaseTicket),
                  child: Text(isClub ? 'Kulupler bilet alamaz' : (hasTicket ? 'Bileti gor' : 'Bilet al')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrganizer(Map<String, dynamic> event) {
    final clubId = event['clubId']?.toString();
    if (clubId != null && clubId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/club-profile',
        arguments: {'clubId': clubId, 'kulupAdi': event['organizerName']?.toString() ?? event['clubName']?.toString()},
      );
      return;
    }

    final ownerId = event['ownerId']?.toString();
    if (ownerId != null && ownerId.isNotEmpty) {
      Navigator.pushNamed(context, '/person-profile', arguments: {'userId': ownerId});
    }
  }

  Widget _commentTile(Map<String, dynamic> comment) {
    final ownerId = comment['applicationUserId']?.toString();
    final canDelete = ownerId != null && ownerId == ApiClient.currentUserId;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(_initials(comment['userInitials']?.toString() ?? '?'))),
      title: InkWell(
        onTap: ownerId == null || ownerId.isEmpty
            ? null
            : () => Navigator.pushNamed(context, '/person-profile', arguments: {'userId': ownerId}),
        child: Text(comment['userFullName']?.toString() ?? 'Kullanici'),
      ),
      subtitle: Text(comment['content']?.toString() ?? ''),
      trailing: canDelete
          ? IconButton(
              onPressed: _busy ? null : () => _deleteComment(comment['id'].toString()),
              icon: const Icon(Icons.delete_outline),
            )
          : null,
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

  String _initials(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return '?';
    return cleaned.length >= 2 ? cleaned.substring(0, 2).toUpperCase() : cleaned.toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1D4ED8)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
