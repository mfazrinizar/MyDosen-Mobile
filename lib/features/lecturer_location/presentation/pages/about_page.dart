import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              background: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryOrange,
                        AppTheme.secondaryOrange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/icon-full.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(duration: 600.ms),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'MyDosen',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.08, end: 0),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryOrange.withValues(alpha: 0.2),
                                AppTheme.secondaryOrange.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              final versionText = snapshot.hasData
                                  ? 'Versi ${snapshot.data!.version}'
                                  : 'Versi 0.0.1';
                              return Text(
                                versionText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryOrange,
                                    ),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, delay: 100.ms);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionTitle(
                      context, 'Tentang Aplikasi', Icons.info_rounded),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(
                    context,
                    isDark,
                    'MyDosen adalah aplikasi yang membantu mahasiswa untuk melacak keberadaan dosen pembimbing secara real-time. '
                    'Aplikasi ini menampilkan lokasi terkini dosen pembimbing di berbagai kampus UNSRI atau lokasi lainnya.',
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.04, end: 0, delay: 80.ms),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                      context, 'Fitur Utama', Icons.stars_rounded),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    isDark,
                    icon: Icons.location_on_rounded,
                    title: 'Tracking Lokasi Real-time',
                    description:
                        'Menampilkan lokasi dosen pembimbing saat ini dengan update terkini',
                    color: AppTheme.locationOutside,
                  )
                      .animate()
                      .fadeIn(duration: 420.ms)
                      .slideX(begin: 0.04, end: 0),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    isDark,
                    icon: Icons.map_rounded,
                    title: 'Visualisasi Peta',
                    description:
                        'Menampilkan lokasi pada peta interaktif dengan highlight area kampus',
                    color: AppTheme.locationPalembang,
                  )
                      .animate()
                      .fadeIn(duration: 420.ms, delay: 40.ms)
                      .slideX(begin: 0.04, end: 0),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    isDark,
                    icon: Icons.refresh_rounded,
                    title: 'Auto Refresh',
                    description:
                        'Memperbarui data lokasi dengan mudah melalui tombol atau gesture pull-to-refresh',
                    color: AppTheme.primaryOrange,
                  )
                      .animate()
                      .fadeIn(duration: 420.ms, delay: 80.ms)
                      .slideX(begin: 0.04, end: 0),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    isDark,
                    icon: Icons.update_rounded,
                    title: 'Informasi Update',
                    description:
                        'Menampilkan waktu terakhir data lokasi diperbarui',
                    color: AppTheme.locationIndralaya,
                  )
                      .animate()
                      .fadeIn(duration: 420.ms, delay: 120.ms)
                      .slideX(begin: 0.04, end: 0),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                      context, 'Lokasi yang Didukung', Icons.pin_drop_rounded),
                  const SizedBox(height: 16),
                  _buildLocationCard(
                    context,
                    isDark,
                    icon: Icons.school_rounded,
                    name: 'Kampus Indralaya',
                    description: 'Kampus utama UNSRI',
                    color: AppTheme.locationIndralaya,
                  )
                      .animate()
                      .fadeIn(duration: 480.ms)
                      .slideY(begin: 0.03, end: 0),
                  const SizedBox(height: 12),
                  _buildLocationCard(
                    context,
                    isDark,
                    icon: Icons.business_rounded,
                    name: 'Kampus Palembang',
                    description: 'UNSRI Bukit Besar',
                    color: AppTheme.locationPalembang,
                  )
                      .animate()
                      .fadeIn(duration: 480.ms, delay: 40.ms)
                      .slideY(begin: 0.03, end: 0),
                  const SizedBox(height: 12),
                  _buildLocationCard(
                    context,
                    isDark,
                    icon: Icons.explore_rounded,
                    name: 'Di Luar Kampus',
                    description: 'Lokasi lainnya',
                    color: AppTheme.locationOutside,
                  )
                      .animate()
                      .fadeIn(duration: 480.ms, delay: 80.ms)
                      .slideY(begin: 0.03, end: 0),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryOrange.withValues(alpha: 0.1),
                          AppTheme.secondaryOrange.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Penting',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryOrange,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aplikasi ini menggunakan data dari server UNSRI yang diperbarui secara berkala. '
                                'Pastikan Anda memiliki koneksi internet yang stabil untuk mendapatkan informasi terkini.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 520.ms)
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryOrange.withValues(alpha: 0.2),
                                AppTheme.secondaryOrange.withValues(alpha: 0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.code_rounded,
                            color: AppTheme.primaryOrange,
                            size: 32,
                          ).animate().fadeIn(duration: 520.ms).scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1.0, 1.0)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dibuat oleh',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ).animate().fadeIn(duration: 520.ms, delay: 40.ms),
                        const SizedBox(height: 4),
                        Text(
                          'Fakultas Ilmu Komputer\nUniversitas Sriwijaya',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ).animate().fadeIn(duration: 520.ms, delay: 80.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryOrange,
                AppTheme.secondaryOrange,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ).animate().fadeIn(duration: 380.ms),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String name,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
