import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/api_client.dart';
import 'profili_duzenle_ekrani.dart';

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});

  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  bool _bildirimlerAcik = true;

  Future<void> _profiliDuzenleAc() async {
    final changed = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilDuzenleEkrani()));
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil bilgileri yenilendi.'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    }
  }

  void _sifreDegistirAc(bool isEng) {
    final mevcutController = TextEditingController();
    final yeniController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEng ? 'Change Password' : 'Şifre Değiştir', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: mevcutController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: isEng ? 'Current Password' : 'Mevcut Şifreniz',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yeniController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: isEng ? 'New Password (min 6 chars)' : 'Yeni Şifreniz (en az 6 karakter)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: Text(isEng ? 'Cancel' : 'İptal', style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white),
                  onPressed: saving
                      ? null
                      : () async {
                          if (mevcutController.text.isEmpty || yeniController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEng ? 'Please fill in all fields.' : 'Lütfen tüm alanları doldurun.')),
                            );
                            return;
                          }
                          if (yeniController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEng ? 'New password must be at least 6 characters.' : 'Yeni şifre en az 6 karakter olmalıdır.')),
                            );
                            return;
                          }
                          setDialogState(() => saving = true);
                          try {
                            await ApiClient.post('/Account/change-password', body: {
                              'currentPassword': mevcutController.text,
                              'newPassword': yeniController.text,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEng ? 'Password changed successfully!' : 'Şifreniz başarıyla değiştirildi!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => saving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          }
                        },
                  child: saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEng ? 'Update' : 'Güncelle'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      mevcutController.dispose();
      yeniController.dispose();
    });
  }

  void _dilSecimiAc(bool isEng) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEng ? 'Select Language' : 'Dil Seçimi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Türkçe'),
                trailing: !isEng ? const Icon(Icons.check, color: Color(0xFF1D4ED8)) : null,
                onTap: () {
                  CampusHubApp.langNotifier.value = 'Türkçe';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                trailing: isEng ? const Icon(Icons.check, color: Color(0xFF1D4ED8)) : null,
                onTap: () {
                  CampusHubApp.langNotifier.value = 'English';
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _cikisYapOnay(bool isEng) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEng ? 'Log Out' : 'Çıkış Yap'),
        content: Text(isEng ? 'Are you sure you want to log out?' : 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEng ? 'Cancel' : 'İptal', style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              CampusHubApp.userNotifier.value = null;
              CampusHubApp.userTypeNotifier.value = 'student';
              CampusHubApp.tokenNotifier.value = null;
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/'); 
            },
            child: Text(isEng ? 'Log Out' : 'Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([CampusHubApp.themeNotifier, CampusHubApp.langNotifier]),
      builder: (context, child) {
        final isDark = CampusHubApp.themeNotifier.value == ThemeMode.dark;
        final isEng = CampusHubApp.langNotifier.value == 'English';

        return Scaffold(
          appBar: AppBar(
            title: Text(isEng ? 'Settings' : 'Ayarlar', style: const TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(isEng ? 'Account' : 'Hesap', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline, color: Color(0xFF1D4ED8)),
                      title: Text(isEng ? 'Edit Profile' : 'Profili Düzenle'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _profiliDuzenleAc,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline, color: Color(0xFF1D4ED8)),
                      title: Text(isEng ? 'Change Password' : 'Şifre Değiştir'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _sifreDegistirAc(isEng),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(isEng ? 'Application' : 'Uygulama', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(isEng ? 'Dark Mode' : 'Karanlık Mod'),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      activeThumbColor: const Color(0xFF1D4ED8),
                      value: isDark,
                      onChanged: (deger) {
                        CampusHubApp.themeNotifier.value = deger ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: Text(isEng ? 'Notifications' : 'Bildirimler'),
                      secondary: const Icon(Icons.notifications_none),
                      activeThumbColor: const Color(0xFF1D4ED8),
                      value: _bildirimlerAcik,
                      onChanged: (deger) => setState(() => _bildirimlerAcik = deger),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(isEng ? 'Language' : 'Dil'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(CampusHubApp.langNotifier.value, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _dilSecimiAc(isEng),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                icon: const Icon(Icons.logout),
                label: Text(isEng ? 'Log Out' : 'Hesaptan Çıkış Yap', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () => _cikisYapOnay(isEng),
              ),
            ],
          ),
        );
      },
    );
  }
}
