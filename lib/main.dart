
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pages/ai_chat_page.dart';
import 'pages/introduction_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Profile',

      // Light Mode
      theme: ThemeData(
        scaffoldBackgroundColor:
            const Color(0xFFFFF8F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              const Color.fromARGB(255, 168, 239, 255),
        ),
        useMaterial3: true,
      ),

      // Dark Mode
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              const Color.fromARGB(255, 255, 184, 234),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode:
          isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: ProfilePage(
        isDarkMode: isDarkMode,
        onThemeChanged: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeChanged;

  const ProfilePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isExpanded = false;

  // ข้อมูลโปรไฟล์
  static const String studentName =
      'ศรัณยาภัทร ขนันเนือง';

  static const String studentId = '67030223';

  static const String faculty =
      'ครุศาสตร์อุตสาหกรรมและเทคโนโลยี';

  static const String favoriteSubject =
      'Mobile Development';

  static const String goal =
      'พัฒนาแอปให้ใช้งานได้จริง';

  static const String interest = 'UX/UI Design';

  static const String hobby =
      'ออกแบบแอปพลิเคชัน';

  // เปิดลิงก์ Social Media
  Future<void> openLink(String url) async {
    final uri = Uri.parse(url);

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเปิดลิงก์ได้'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการเปิดลิงก์',
          ),
        ),
      );
    }
  }

  // สร้างแถวข้อมูลโปรไฟล์
  Widget buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color.fromARGB(
              255,
              255,
              183,
              238,
            ),
          ),

          const SizedBox(width: 12),

          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  // เปิดหน้า AI Chat
  void openAiChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AiChatPage(),
      ),
    );
  }

  // เปิดหน้า AI Introduction
  void openIntroduction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IntroductionPage(
          name: studentName,
          studentId: studentId,
          faculty: faculty,
          favoriteSubject: favoriteSubject,
          goal: goal,
          interest: interest,
          hobby: hobby,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // ส่วนหัวของแอป
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        backgroundColor: const Color.fromARGB(
          255,
          255,
          173,
          235,
        ),
        foregroundColor: Colors.white,

        // ปุ่มเปลี่ยน Dark Mode
        actions: [
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Light Mode'
                : 'Dark Mode',
            onPressed: widget.onThemeChanged,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Challenge 1: Animation รูปโปรไฟล์
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 400,
                  ),
                  curve: Curves.easeInOut,
                  width: isExpanded ? 150 : 120,
                  height: isExpanded ? 150 : 120,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(
                      255,
                      192,
                      239,
                      255,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 65,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ชื่อ
              const Text(
                studentName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // รหัสนักศึกษา
              const Text(
                'รหัสนักศึกษา: $studentId',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              // Card ข้อมูลส่วนตัว
              Card(
                color: isDark
                    ? Theme.of(context)
                        .colorScheme
                        .surfaceContainer
                    : const Color(0xFFFFF0E6),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildInfoRow(
                        Icons.school,
                        'คณะ',
                        faculty,
                      ),

                      const Divider(),

                      buildInfoRow(
                        Icons.code,
                        'วิชาที่ชอบ',
                        favoriteSubject,
                      ),

                      const Divider(),

                      buildInfoRow(
                        Icons.star,
                        'เป้าหมาย',
                        goal,
                      ),

                      const Divider(),

                      buildInfoRow(
                        Icons.computer,
                        'ความสนใจ',
                        interest,
                      ),

                      const Divider(),

                      buildInfoRow(
                        Icons.favorite,
                        'งานอดิเรก',
                        hobby,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Challenge 1: Social Media
              const Text(
                'Social Media',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      openLink(
                        'https://github.com/saranyapat3368',
                      );
                    },
                    icon: const Icon(Icons.code),
                    label: const Text('GitHub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFFF0E6),
                      foregroundColor:
                          const Color(0xFF9B642F),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      openLink(
                        'https://www.facebook.com/',
                      );
                    },
                    icon: const Icon(Icons.language),
                    label: const Text('Facebook'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFFF0E6),
                      foregroundColor:
                          const Color(0xFF9B642F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Challenge 3: AI Introduction
              ElevatedButton.icon(
                onPressed: openIntroduction,
                icon: const Icon(
                  Icons.auto_awesome,
                ),
                label: const Text(
                  'ให้ AI แนะนำตัวฉัน',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFFF0E6),
                  foregroundColor:
                      const Color(0xFF9B642F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Challenge 2: AI Chat
              ElevatedButton.icon(
                onPressed: openAiChat,
                icon: const Icon(
                  Icons.smart_toy,
                ),
                label: const Text(
                  'ทดลอง AI Chat',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFFF0E6),
                  foregroundColor:
                      const Color(0xFF9B642F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
