
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class IntroductionPage extends StatefulWidget {
  final String name;
  final String studentId;
  final String faculty;
  final String favoriteSubject;
  final String goal;
  final String interest;
  final String hobby;

  const IntroductionPage({
    super.key,
    required this.name,
    required this.studentId,
    required this.faculty,
    required this.favoriteSubject,
    required this.goal,
    required this.interest,
    required this.hobby,
  });

  @override
  State<IntroductionPage> createState() =>
      _IntroductionPageState();
}

class _IntroductionPageState
    extends State<IntroductionPage> {
  bool _isLoading = false;
  String _introduction = '';

  // ใช้ API Key จาก --dart-define เหมือน AI Chat
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  // ใช้ชื่อโมเดลที่ทดสอบแล้วว่าใช้งานได้
  static const String _model = 'gemini-3.8-flash-lite';

  Future<void> _generateIntroduction() async {
    if (_isLoading) return;

    if (_apiKey.isEmpty) {
      setState(() {
        _introduction =
            'ไม่พบ API Key กรุณาตั้งค่า GEMINI_API_KEY';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _introduction = '';
    });

    // รวมข้อมูล Profile เป็น Prompt
    final prompt = '''
ช่วยเขียนข้อความแนะนำตัวจากข้อมูลต่อไปนี้

ชื่อ: ${widget.name}
รหัสนักศึกษา: ${widget.studentId}
คณะ: ${widget.faculty}
วิชาที่ชอบ: ${widget.favoriteSubject}
เป้าหมาย: ${widget.goal}
ความสนใจ: ${widget.interest}
งานอดิเรก: ${widget.hobby}

เงื่อนไข:
1. เขียนเป็นภาษาไทย
2. ใช้สรรพนาม "ฉัน"
3. ใช้ภาษาสุภาพ เป็นธรรมชาติ
4. ความยาวประมาณ 5-7 ประโยค
5. เหมาะสำหรับแนะนำตัวในห้องเรียน
6. ใช้เฉพาะข้อมูลที่ให้มา ไม่แต่งข้อมูลเพิ่มเติม
7. ไม่ต้องใส่หัวข้อหรือคำอธิบาย
''';

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/'
        'v1beta/models/$_model:generateContent',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ],
            }
          ],
        }),
      ).timeout(
        const Duration(seconds: 45),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}: '
          'ไม่สามารถสร้างคำแนะนำตัวได้',
        );
      }

      final data = jsonDecode(response.body)
          as Map<String, dynamic>;

      final candidates = data['candidates'] as List?;

      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI ไม่ได้ส่งคำตอบกลับมา');
      }

      final candidate =
          candidates.first as Map<String, dynamic>;

      final content =
          candidate['content'] as Map<String, dynamic>?;

      final parts = content?['parts'] as List?;

      final result = (parts ?? [])
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join('\n')
          .trim();

      if (result.isEmpty) {
        throw Exception('AI ไม่ได้ส่งข้อความแนะนำตัว');
      }

      if (!mounted) return;

      setState(() {
        _introduction = result;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _introduction =
            'AI ใช้เวลาตอบนานเกินไป '
            'กรุณาลองสร้างใหม่อีกครั้งค่ะ';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _introduction = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Introduction'),
        backgroundColor: const Color(0xFF9DDEF4),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFF768D9),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _generateIntroduction,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'ให้ AI สร้างคำแนะนำตัว',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFFF0E6),
                foregroundColor:
                    const Color(0xFF9B642F),
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFF768D9),
                    ),
                    SizedBox(height: 12),
                    Text('AI กำลังเขียนแนะนำตัว...'),
                  ],
                ),
              ),

            if (_introduction.isNotEmpty)
              Card(
                color:
                    Theme.of(context).brightness ==
                            Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                        : const Color(0xFFFFF0E6),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    _introduction,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
