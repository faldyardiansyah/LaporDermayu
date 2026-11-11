import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:lapordermayu/utils/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:lapordermayu/utils/widgets/mega_mendung.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  TextStyle get jakarta => GoogleFonts.plusJakartaSans();

  bool _isLoading = false;

  // Data Statis / Placeholder UI
  String _name = 'Pengguna Saferuas';
  final String _email = 'pengguna@email.com';
  String _phone = 'Belum ditambahkan';

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.slate100,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.homeBlue,
          backgroundColor: Colors.white,
          child: Skeletonizer(
            enabled: _isLoading,
            effect: const ShimmerEffect(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: 125),
              child: Column(
                children: [
                  _buildHeader(),

                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildProfileCard(),
                          _buildSectionTitle(
                            'INFORMASI AKUN',
                            'Informasi pribadi kamu',
                          ),
                          _buildAccountCard(),
                          _buildSectionTitle(
                            'PENGATURAN',
                            'Kelola akun dan aplikasi',
                          ),
                          _buildSettingsCard(),
                          _buildSectionTitle(
                            'INFORMASI LAINNYA',
                            'Kami siap membantu kamu',
                          ),
                          _buildHelpCard(),
                          const SizedBox(height: 15),
                          _buildLogoutButton(),
                          const SizedBox(height: 15),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.homeBlue, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(38),
              bottomRight: Radius.circular(38),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: -6,
                right: -135,
                child: MegaMendung(
                  width: 345,
                  color: Colors.white.withValues(alpha: 0.24),
                ),
              ),
              Positioned(
                bottom: -18,
                left: -160,
                child: MegaMendung(
                  width: 310,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              height: 21,
                              width: 21,
                            ),
                          ),
              
                          const SizedBox(width: 12),
                          Text(
                            'Profil Pengguna',
                            style: jakarta.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.17),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'AKUN SAYA',
                              style: jakarta.copyWith(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(
          begin: -0.08,
          end: 0,
          duration: 550.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildProfileCard() {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.homeCardBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.homeBlue.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            color: AppColors.homeCardTint,
                            child: Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: AppColors.homeBlue,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          key: ValueKey(_name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta.copyWith(
                            color: AppColors.slate900,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ).animate().fadeIn(duration: 250.ms),
                        const SizedBox(height: 5),
                        Text(
                          _email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta.copyWith(
                            color: AppColors.slate500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.homeBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_rounded,
                                color: AppColors.homeBlue,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'PENGGUNA',
                                style: jakarta.copyWith(
                                  color: AppColors.homeBlue,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: AppColors.homeCardTint,
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: _showEditProfileDialog,
                      child: Padding(
                        padding: const EdgeInsets.all(11),
                        child: Icon(
                          Icons.edit_rounded,
                          color: AppColors.homeBlue,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              Divider(color: AppColors.slate100, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: AppColors.slate500,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _phone,
                      style: jakarta.copyWith(
                        color: AppColors.slate600,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Edit profil',
                    style: jakarta.copyWith(
                      color: AppColors.homeBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 150.ms, duration: 500.ms)
        .slideY(
          begin: 0.12,
          end: 0,
          delay: 150.ms,
          duration: 550.ms,
          curve: Curves.easeOutCubic,
        );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _name);
    final phoneCtrl = TextEditingController(
      text: _phone == 'Belum ditambahkan' ? '' : _phone,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor telepon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _name = newName;
                  _phone = newPhone.isEmpty ? 'Belum ditambahkan' : newPhone;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 25, bottom: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              textAlign: TextAlign.left,
              style: jakarta.copyWith(
                color: AppColors.slate500,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.left,
              style: jakarta.copyWith(
                color: AppColors.slate900,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildInfoRow(
                icon: Icons.person_outline_rounded,
                label: 'Nama lengkap',
                value: _name,
              ),
              _divider(),
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Alamat email',
                value: _email,
              ),
              _divider(),
              _buildInfoRow(
                icon: Icons.phone_outlined,
                label: 'Nomor telepon',
                value: _phone,
                isLast: true,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, delay: 300.ms, duration: 500.ms);
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: jakarta.copyWith(
                    color: AppColors.slate500,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: jakarta.copyWith(
                    color: AppColors.slate900,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.shield_outlined,
                title: 'Keamanan akun',
                subtitle: 'Pengaturan keamanan akun',
                onTap: () {},
              ),
              _divider(),
              _buildMenuItem(
                icon: Icons.tune_rounded,
                title: 'Pengaturan aplikasi',
                subtitle: 'Atur preferensi aplikasi',
                onTap: () {},
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, delay: 400.ms, duration: 500.ms);
  }

  Widget _buildHelpCard() {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Pusat bantuan',
                subtitle: 'Temukan bantuan penggunaan aplikasi',
                onTap: () {},
              ),
              _divider(),
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Saferuas',
                subtitle: 'Informasi mengenai aplikasi',
                onTap: () {},
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 500.ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, delay: 500.ms, duration: 500.ms);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              _iconBox(icon),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: jakarta.copyWith(
                        color: AppColors.slate900,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: jakarta.copyWith(
                        color: AppColors.slate500,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.slate400,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _showLogoutDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.red.withValues(alpha: 0.13)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Keluar dari akun',
                    style: jakarta.copyWith(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 600.ms, duration: 450.ms)
        .slideY(begin: 0.08, end: 0, delay: 600.ms, duration: 500.ms);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 26,
                ),
              ),
              const SizedBox(height: 17),
              Text(
                'Keluar dari akun?',
                style: jakarta.copyWith(
                  color: AppColors.slate900,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah kamu yakin ingin keluar dari aplikasi Saferuas?',
                textAlign: TextAlign.center,
                style: jakarta.copyWith(
                  color: AppColors.slate500,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate600,
                        side: BorderSide(color: AppColors.slate200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'Batal',
                        style: jakarta.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'Keluar',
                        style: jakarta.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, color: AppColors.homeBlue, size: 14),
            const SizedBox(width: 6),
            Text(
              'SAFERUAS',
              style: jakarta.copyWith(
                color: AppColors.slate500,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Mewujudkan perjalanan yang lebih aman.',
          style: jakarta.copyWith(
            color: AppColors.slate400,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms, duration: 500.ms);
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 41,
      height: 41,
      decoration: BoxDecoration(
        color: AppColors.homeCardTint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppColors.homeBlue, size: 19),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.slate100,
      indent: 54,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: AppColors.homeCardBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.035),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}