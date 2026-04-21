import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class BildirimlerEkrani extends StatefulWidget {
  const BildirimlerEkrani({super.key});

  @override
  State<BildirimlerEkrani> createState() => _BildirimlerEkraniState();
}

class _BildirimlerEkraniState extends State<BildirimlerEkrani> {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
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
      final list = await ApiClient.get('/Notifications') as List<dynamic>;
      final count = await ApiClient.get('/Notifications/unread-count') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _notifications = list.cast<Map<String, dynamic>>();
        _unreadCount = (count['unreadCount'] as num?)?.toInt() ?? 0;
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

  Future<void> _markAllRead() async {
    try {
      await ApiClient.put('/Notifications/read-all');
      await _load();
    } catch (e) {
      _show(e.toString());
    }
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id != null && notification['isRead'] != true) {
      try {
        await ApiClient.put('/Notifications/$id/read');
      } catch (_) {}
    }

    if (!mounted) return;
    final type = notification['type']?.toString() ?? '';
    final relatedEntityId = notification['relatedEntityId']?.toString();
    final eventId = notification['relatedEventId']?.toString();
    final clubId = notification['relatedClubId']?.toString();

    if (type == 'ClubFollowed' && relatedEntityId != null && relatedEntityId.isNotEmpty) {
      Navigator.pushNamed(context, '/club-profile', arguments: {'clubId': relatedEntityId});
    } else if (relatedEntityId != null &&
        relatedEntityId.isNotEmpty &&
        (type == 'EventCommented' || type == 'EventLiked' || type == 'TicketPurchased')) {
      Navigator.pushNamed(context, '/event-detail', arguments: {'etkinlikId': relatedEntityId});
    } else if (eventId != null && eventId.isNotEmpty) {
      Navigator.pushNamed(context, '/event-detail', arguments: {'etkinlikId': eventId});
    } else if (clubId != null && clubId.isNotEmpty) {
      Navigator.pushNamed(context, '/club-profile', arguments: {'clubId': clubId});
    }

    _load();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_unreadCount > 0 ? 'Bildirimler ($_unreadCount)' : 'Bildirimler'),
        actions: [
          IconButton(onPressed: _markAllRead, icon: const Icon(Icons.done_all)),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _body()),
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

    if (_notifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 120),
          Icon(Icons.notifications_none, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text('Henuz bildiriminiz yok.', textAlign: TextAlign.center),
        ],
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final n = _notifications[index];
        final unread = n['isRead'] != true;
        return Material(
          color: unread ? const Color(0xFF1D4ED8).withValues(alpha: 0.06) : Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _iconColor(n).withValues(alpha: 0.12),
              child: Icon(_icon(n), color: _iconColor(n)),
            ),
            title: Text(
              _title(n),
              style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
            ),
            subtitle: Text(_message(n)),
            trailing: unread ? const CircleAvatar(radius: 5, backgroundColor: Color(0xFF1D4ED8)) : null,
            onTap: () => _openNotification(n),
          ),
        );
      },
    );
  }

  IconData _icon(Map<String, dynamic> n) {
    final type = n['type']?.toString() ?? '';
    if (type.contains('Ticket')) return Icons.confirmation_num_outlined;
    if (type.contains('Comment')) return Icons.chat_bubble_outline;
    if (type.contains('Like')) return Icons.favorite_border;
    if (type.contains('Follow')) return Icons.person_add_alt_1_outlined;
    return Icons.notifications_outlined;
  }

  Color _iconColor(Map<String, dynamic> n) {
    final type = n['type']?.toString() ?? '';
    if (type.contains('Ticket')) return Colors.green;
    if (type.contains('Comment')) return Colors.blue;
    if (type.contains('Like')) return Colors.red;
    if (type.contains('Follow')) return Colors.purple;
    return Colors.orange;
  }

  String _title(Map<String, dynamic> notification) {
    final title = notification['title']?.toString();
    if (title != null && title.isNotEmpty) return title;

    final type = notification['type']?.toString() ?? '';
    if (type == 'ClubFollowed') return 'Yeni takipci';
    if (type == 'EventCommented') return 'Yeni yorum';
    if (type == 'EventLiked') return 'Yeni begeni';
    return 'Bildirim';
  }

  String _message(Map<String, dynamic> notification) {
    final message = notification['message']?.toString();
    if (message != null && message.isNotEmpty) return message;

    final body = notification['body']?.toString();
    if (body != null && body.isNotEmpty) return body;

    return 'Detaya gitmek icin dokunun.';
  }
}
