import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_text_field.dart';

class SifremiUnuttumEkrani extends StatefulWidget {
  const SifremiUnuttumEkrani({super.key});

  @override
  State<SifremiUnuttumEkrani> createState() => _SifremiUnuttumEkraniState();
}

class _SifremiUnuttumEkraniState extends State<SifremiUnuttumEkrani> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _gonderildi = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta adresinizi girin.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiClient.post('/Account/forgot-password', body: {'email': email});
      if (!mounted) return;
      setState(() => _gonderildi = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _gonderildi ? _basariliGorunum() : _formGorunum(),
      ),
    );
  }

  Widget _formGorunum() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_reset, size: 80, color: Color(0xFF1D4ED8)),
        const SizedBox(height: 24),
        const Text(
          'Şifrenizi sıfırlamak için kayıtlı e-posta adresinizi girin.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _emailController,
          hint: 'E-posta Adresi',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _loading ? null : _gonder,
            child: _loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sıfırlama İsteği Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _basariliGorunum() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Şifre sıfırlama isteği alındı!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Eğer bu e-posta adresiyle kayıtlı bir hesap varsa, sıfırlama bağlantısı gönderilecektir.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Giriş Sayfasına Dön', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}