import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/api_client.dart';

class ProfilDuzenleEkrani extends StatefulWidget {
  const ProfilDuzenleEkrani({super.key});

  @override
  State<ProfilDuzenleEkrani> createState() => _ProfilDuzenleEkraniState();
}

class _ProfilDuzenleEkraniState extends State<ProfilDuzenleEkrani> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _universityController = TextEditingController();
  final _departmentController = TextEditingController();
  final _profileImageController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _clubDescriptionController = TextEditingController();
  final _clubCoverController = TextEditingController();
  final _clubInstagramController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _userType = 'student';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _universityController.dispose();
    _departmentController.dispose();
    _profileImageController.dispose();
    _clubNameController.dispose();
    _clubDescriptionController.dispose();
    _clubCoverController.dispose();
    _clubInstagramController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!ApiClient.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Profili duzenlemek icin tekrar giris yapmalisiniz.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await ApiClient.get('/Account/me') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _userType = profile['userType']?.toString() ?? 'student';
        _firstNameController.text = profile['firstName']?.toString() ?? '';
        _lastNameController.text = profile['lastName']?.toString() ?? '';
        _universityController.text = profile['university']?.toString() ?? '';
        _departmentController.text = profile['department']?.toString() ?? '';
        _profileImageController.text = profile['profileImageUrl']?.toString() ?? '';
        _clubNameController.text = profile['clubName']?.toString() ?? profile['firstName']?.toString() ?? '';
        _clubDescriptionController.text = profile['clubDescription']?.toString() ?? '';
        _clubCoverController.text = profile['clubCoverImageUrl']?.toString() ?? '';
        _clubInstagramController.text = profile['clubInstagramHandle']?.toString() ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException && e.statusCode == 401
            ? 'Oturum dogrulanamadi. Giris yaptiginiz hesabi tekrar deneyin.'
            : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = _userType == 'club'
          ? {
              'clubName': _clubNameController.text.trim(),
              'clubDescription': _clubDescriptionController.text.trim(),
              'clubCoverImageUrl': _clubCoverController.text.trim(),
              'clubInstagramHandle': _clubInstagramController.text.trim(),
              'university': _universityController.text.trim(),
              'department': _departmentController.text.trim(),
              'profileImageUrl': _profileImageController.text.trim(),
            }
          : {
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'university': _universityController.text.trim(),
              'department': _departmentController.text.trim(),
              'profileImageUrl': _profileImageController.text.trim(),
            };

      final updated = await ApiClient.put('/Account/profile', body: body) as Map<String, dynamic>;
      CampusHubApp.userNotifier.value = {
        ...?CampusHubApp.userNotifier.value,
        'id': updated['id'],
        'firstName': updated['firstName'],
        'lastName': updated['lastName'],
        'email': updated['email'],
        'userName': updated['userName'],
        'userType': updated['userType'],
        'clubId': updated['clubId'],
      };
      CampusHubApp.userTypeNotifier.value = updated['userType']?.toString() ?? _userType;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil guncellendi.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException && e.statusCode == 401
          ? 'Oturum dogrulanamadi. Giris yaptiginiz hesabi tekrar deneyin.'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Duzenle'),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Kaydet'),
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ApiClient.isAuthenticated ? _load : () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                child: Text(ApiClient.isAuthenticated ? 'Tekrar dene' : 'Giris yap'),
              ),
            ],
          ),
        ),
      );
    }

    final isClub = _userType == 'club';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (isClub) ...[
          _field('Kulup adi', Icons.groups_outlined, _clubNameController),
          const SizedBox(height: 16),
          _field('Kulup aciklamasi', Icons.info_outline, _clubDescriptionController, maxLines: 3),
          const SizedBox(height: 16),
          _field('Kapak fotograf URL', Icons.image_outlined, _clubCoverController),
          const SizedBox(height: 16),
          _field('Instagram', Icons.alternate_email, _clubInstagramController),
        ] else ...[
          _field('Ad', Icons.person_outline, _firstNameController),
          const SizedBox(height: 16),
          _field('Soyad', Icons.person_outline, _lastNameController),
        ],
        const SizedBox(height: 16),
        _field('Universite', Icons.school_outlined, _universityController),
        const SizedBox(height: 16),
        _field('Bolum', Icons.book_outlined, _departmentController),
        const SizedBox(height: 16),
        _field('Profil fotograf URL', Icons.image_outlined, _profileImageController),
      ],
    );
  }

  Widget _field(String label, IconData icon, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
