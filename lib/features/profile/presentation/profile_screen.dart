import 'package:flutter/material.dart';

import '../../../core/services/messaging_service.dart';
import '../../../core/widgets/feature_page.dart';
import '../../auth/services/auth_service.dart';
import '../../farm_modules/services/farm_module_service.dart';
import '../models/app_user.dart';
import '../services/user_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Profil',
      subtitle: 'Data akun dan utilitas konfigurasi MVP.',
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: widget.profile.photoUrl.isEmpty
                            ? null
                            : NetworkImage(widget.profile.photoUrl),
                        child: widget.profile.photoUrl.isEmpty
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.profile.email,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Chip(label: Text(widget.profile.role)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nama'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => UserProfileService().updateName(
                              widget.profile.uid,
                              _name.text,
                            ),
                            'Profil diperbarui.',
                          ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Simpan profil'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.profile.isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.eco_outlined),
                title: const Text('Siapkan farm_modules'),
                subtitle: const Text(
                  'Buat atau perbarui 5 dokumen modul default di Firestore.',
                ),
                trailing: FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          FarmModuleService().seedDefaults,
                          'Lima farm module berhasil disiapkan.',
                        ),
                  child: const Text('Seed'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Izin notifikasi'),
              subtitle: const Text(
                'Opsional. Meminta izin FCM tanpa mengirim push notification.',
              ),
              trailing: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                        await MessagingService().requestPermissionAndGetToken();
                      }, 'Permintaan izin notifikasi selesai.'),
                child: const Text('Aktifkan'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : AuthService().signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
