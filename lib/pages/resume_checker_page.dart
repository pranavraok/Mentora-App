import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mentora_app/pages/settings_page.dart';
import 'package:mentora_app/pages/notifications_page.dart';
import 'package:mentora_app/config/supabase_config.dart';

class ResumeCheckerPage extends StatefulWidget {
  const ResumeCheckerPage({super.key});

  @override
  State<ResumeCheckerPage> createState() => _ResumeCheckerPageState();
}

class _ResumeCheckerPageState extends State<ResumeCheckerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isAnalyzing = false;
  bool _hasAnalyzed = false;

  // Real scores from Gemini analysis
  int _scoreOverall = 0;
  int _scoreTech = 0;
  int _scoreReadability = 0;
  List<String> _suggestions = [];
  String? _resumeUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Pick PDF/DOCX file and analyze directly via Edge Function
  Future<void> _pickAndUploadResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('Could not read file');
        return;
      }

      setState(() => _errorMessage = null);

      // Get authenticated user
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        _showError('Not authenticated');
        return;
      }

      // Get user profile ID
      final userRow = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', user.id)
          .single();
      final userId = userRow['id'] as String;

      // Convert bytes to base64 for transmission
      final base64Resume = base64Encode(bytes);
      print('Calling analyzeResume with file: ${file.name}');

      // Call Edge Function directly with file content
      await _analyzeResumeWithBase64(base64Resume, file.name, userId);
    } catch (e) {
      _showError('Error: $e');
    }
  }

  /// Analyze resume by sending base64 content to Edge Function
  Future<void> _analyzeResumeWithBase64(
      String base64Content,
      String fileName,
      String userId,
      ) async {
    setState(() {
      _isAnalyzing = true;
      _hasAnalyzed = false;
      _errorMessage = null;
    });

    try {
      // Call Edge Function with base64 encoded file
      final response = await SupabaseConfig.client.functions.invoke(
        'analyzeResume',
        body: {
          'file_name': fileName,
          'file_content_base64': base64Content,
          'user_id': userId,
        },
      );

      final data = response as Map<String, dynamic>;
      setState(() {
        _scoreOverall = (data['overall_score'] as num?)?.toInt() ?? 0;
        _scoreTech = (data['ats_compatibility'] as num?)?.toInt() ?? 0;
        _scoreReadability = (data['ats_compatibility'] as num?)?.toInt() ?? 0;
        _suggestions = List<String>.from(
          (data['improvements'] as List?) ?? [],
        ).take(3).toList();
        _isAnalyzing = false;
        _hasAnalyzed = true;
      });
      print('Resume analyzed successfully: Overall=$_scoreOverall');
    } catch (e) {
      print('Error analyzing resume: $e');
      _showError('Analysis error: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  /// Call analyzeResume Edge Function with Gemini AI (deprecated - use base64 method)
  Future<void> _analyzeResume(String resumeUrl, String fileName) async {
    setState(() {
      _isAnalyzing = true;
      _hasAnalyzed = false;
      _errorMessage = null;
    });

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        _showError('Not authenticated');
        return;
      }

      // Get user profile ID
      final userRow = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', user.id)
          .single();
      final userId = userRow['id'] as String;

      // Call Edge Function
      final response = await SupabaseConfig.client.functions.invoke(
        'analyzeResume',
        body: {
          'resume_url': resumeUrl,
          'file_name': fileName,
          'user_id': userId,
        },
      );

      final data = response as Map<String, dynamic>;
      setState(() {
        _scoreOverall = (data['overall_score'] as num?)?.toInt() ?? 0;
        _scoreTech = (data['ats_compatibility'] as num?)?.toInt() ?? 0;
        _scoreReadability = (data['ats_compatibility'] as num?)?.toInt() ?? 0;
        _suggestions = List<String>.from(
          (data['improvements'] as List?) ?? [],
        ).take(3).toList();
        _isAnalyzing = false;
        _hasAnalyzed = true;
      });
      print('Resume analyzed successfully: Overall=$_scoreOverall');
    } catch (e) {
      print('Error analyzing resume: $e');
      _showError('Analysis error: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302b63),
                  Color(0xFF24243e),
                ],
              ),
            ),
          ),

          // Floating blur circles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final offset = math.sin(
                  (_animController.value + index * 0.2) * 2 * math.pi,
                );
                return Positioned(
                  left: (index * 50.0) + offset * 20,
                  top: (index * 80.0) + offset * 30,
                  child: Container(
                    width: 60 + (index * 10.0),
                    height: 60 + (index * 10.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main layout with fixed header
          Column(
            children: [
              // FIXED HEADER - Does not scroll
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // LEFT SIDE: Back button + Logo
                            Row(
                              children: [
                                _buildGlassButton(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 60,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            // RIGHT SIDE: Notifications + Settings
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildGlassButton(
                                  icon: Icons.notifications_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const NotificationsPage(),
                                      ),
                                    );
                                  },
                                  hasNotification: true,
                                ),
                                const SizedBox(width: 12),
                                _buildGlassButton(
                                  icon: Icons.settings_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const SettingsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3, end: 0),

              // SCROLLABLE CONTENT - Everything below the header scrolls
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        // Title section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 1.0 +
                                        (math.sin(
                                          _animController.value * 2 * math.pi,
                                        ) *
                                            0.08),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color.lerp(
                                              const Color(0xFFFFD700),
                                              const Color(0xFFf093fb),
                                              _animController.value,
                                            )!,
                                            const Color(0xFFf5576c),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD700)
                                                .withOpacity(0.6),
                                            blurRadius: 20 +
                                                (math.sin(
                                                  _animController.value *
                                                      2 *
                                                      math.pi,
                                                ) *
                                                    5),
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.description_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFFFFD700),
                                            Color(0xFFFFA500),
                                          ],
                                        ).createShader(bounds),
                                    child: const Text(
                                      'RESUME CHECKER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Level up your CV for tech roles',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: -0.2, end: 0),

                        // Main content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUploadCard(),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  _buildTipChip(
                                    icon: Icons.star_rounded,
                                    text: 'Keep it 1–2 pages with clear sections.',
                                  ),
                                  const SizedBox(height: 6),
                                  _buildTipChip(
                                    icon: Icons.bolt_rounded,
                                    text:
                                    'Use measurable impact: "Improved performance by 30%".',
                                  ),
                                  const SizedBox(height: 6),
                                  _buildTipChip(
                                    icon: Icons.search_rounded,
                                    text:
                                    'Include job-description keywords (Flutter, APIs, cloud, CI/CD).',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_isAnalyzing) _buildScanningCard(),
                              if (_hasAnalyzed && !_isAnalyzing) ...[
                                const SizedBox(height: 8),
                                _buildScoreRow(),
                                const SizedBox(height: 20),
                                _buildSuggestions(),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== UI helpers =====
  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withOpacity(0.55),
            const Color(0xFF764ba2).withOpacity(0.55),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload your resume (PDF)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Supports PDF / DOCX. Recommended: 1–2 pages, English only.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _pickAndUploadResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _isAnalyzing
                    ? 'Analyzing...'
                    : _hasAnalyzed
                    ? 'Re-analyze resume'
                    : 'Upload & Analyze',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildScanningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.4),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scanning your resume…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Checking keywords, structure, readability and ATS-friendliness.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
              strokeWidth: 4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildScoreRow() {
    return Row(
      children: [
        Expanded(
          child: _buildScoreCard(
            label: 'Overall Score',
            score: _scoreOverall,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScoreCard(
            label: 'Tech Stack',
            score: _scoreTech,
            gradient: const LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScoreCard(
            label: 'Readability',
            score: _scoreReadability,
            gradient: const LinearGradient(
              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String label,
    required int score,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1D1B38).withOpacity(0.8),
            const Color(0xFF18192D).withOpacity(0.8),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.auto_fix_high_rounded,
                color: Color(0xFFFFD700),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Actionable suggestions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Show real suggestions from Gemini or placeholders
          if (_suggestions.isEmpty)
            Text(
              'Upload a resume to see personalized suggestions from Gemini AI.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._suggestions.map(
                  (suggestion) => Column(
                children: [
                  _buildSuggestionItem(suggestion, ''),
                  if (_suggestions.indexOf(suggestion) <
                      _suggestions.length - 1)
                    const SizedBox(height: 10),
                ],
              ),
            ),
          if (_suggestions.isEmpty) ...[
            const SizedBox(height: 10),
            _buildSuggestionItem(
              'Showcase your best projects first',
              'Put 2–3 impactful Flutter / full-stack projects above older college work.',
            ),
            const SizedBox(height: 10),
            _buildSuggestionItem(
              'Align with job description',
              'Mirror the skills and tools from the JD (state-management, APIs, cloud, CI/CD).',
            ),
            const SizedBox(height: 10),
            _buildSuggestionItem(
              'Clean formatting matters',
              'Use consistent headings, spacing and bullet style for a professional look.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF43e97b),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipChip({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
              ),
              if (hasNotification)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
