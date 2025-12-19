import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mentora_app/pages/settings_page.dart';
import 'package:mentora_app/pages/notifications_page.dart';
import 'package:mentora_app/services/gemini_resume_service.dart';
import 'package:mentora_app/models/resume_analysis_result.dart';

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

  // Gemini resume service
  final GeminiResumeService _resumeService = GeminiResumeService();

  // Analysis results from Gemini
  ResumeAnalysisResult? _analysisResult;
  String? _errorMessage;

  // Scores for display (derived from _analysisResult)
  int get _scoreOverall => _analysisResult?.overallScore ?? 0;
  int get _scoreSkills => _analysisResult?.skillsScore ?? 0;
  int get _scoreExperience => _analysisResult?.experienceScore ?? 0;
  int get _scoreReadability => _analysisResult?.readabilityScore ?? 0;
  List<ResumeSuggestion> get _suggestions => _analysisResult?.suggestions ?? [];

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

  /// Pick PDF file and analyze with Gemini (pure client-side)
  Future<void> _pickAndUploadResume() async {
    try {
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        _showError('Could not read file');
        return;
      }

      // Start analyzing
      setState(() {
        _isAnalyzing = true;
        _hasAnalyzed = false;
        _errorMessage = null;
        _analysisResult = null;
      });

      print('📄 Selected file: ${file.name} (${bytes.length} bytes)');

      // Analyze resume using Gemini (client-side)
      await _analyzeResumeWithGemini(Uint8List.fromList(bytes));
    } catch (e) {
      print('Error picking file: $e');
      _showError('Error selecting file: $e');
      setState(() => _isAnalyzing = false);
    }
  }

  /// Analyze resume using Gemini AI (pure client-side)
  ///
  /// This method:
  /// 1. Extracts text from PDF bytes
  /// 2. Sends text to Gemini API
  /// 3. Parses structured JSON response
  /// 4. Updates UI with results
  ///
  /// NO Supabase Edge Functions are used
  Future<void> _analyzeResumeWithGemini(Uint8List pdfBytes) async {
    try {
      print('🔍 Starting resume analysis with Gemini...');

      // Analyze PDF using Gemini service
      final result = await _resumeService.analyzePdfResume(pdfBytes);

      // Update UI with results
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
        _hasAnalyzed = true;
      });

      print('✓ Resume analyzed successfully!');
      print('  Overall Score: ${result.overallScore}');
      print('  Skills Score: ${result.skillsScore}');
      print('  Experience Score: ${result.experienceScore}');
      print('  Readability Score: ${result.readabilityScore}');
      print('  Suggestions: ${result.suggestions.length}');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Resume analyzed successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('✗ Error analyzing resume: $e');

      // Provide helpful error messages
      String errorMessage;
      if (e.toString().contains('API key')) {
        errorMessage =
            'Please configure your Gemini API key in lib/config/gemini_config.dart';
      } else if (e.toString().contains('extract')) {
        errorMessage =
            'Could not read PDF. Please ensure it\'s a text-based PDF.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = 'Analysis failed: ${e.toString()}';
      }

      _showError(errorMessage);

      setState(() {
        _isAnalyzing = false;
        _hasAnalyzed = false;
      });
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
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                16,
                              ),
                              child: Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale:
                                            1.0 +
                                            (math.sin(
                                                  _animController.value *
                                                      2 *
                                                      math.pi,
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
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFFD700,
                                                ).withOpacity(0.6),
                                                blurRadius:
                                                    20 +
                                                    (math.sin(
                                                          _animController
                                                                  .value *
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    text:
                                        'Keep it 1–2 pages with clear sections.',
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
            label: 'Skills',
            score: _scoreSkills,
            gradient: const LinearGradient(
              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildScoreCard(
            label: 'Experience',
            score: _scoreExperience,
            gradient: const LinearGradient(
              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
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
            ..._suggestions.asMap().entries.map(
              (entry) => Column(
                children: [
                  _buildSuggestionItem(entry.value.title, entry.value.detail),
                  if (entry.key < _suggestions.length - 1)
                    const SizedBox(height: 10),
                ],
              ),
            ),
          if (!_hasAnalyzed) ...[
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
