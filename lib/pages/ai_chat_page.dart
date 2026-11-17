
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // ข้อความที่แสดงบนหน้าจอ
  final List<Map<String, String>> _messages = [];

  // ประวัติที่ส่งไปให้ Gemini
  final List<Map<String, dynamic>> _chatHistory = [];

  bool _isLoading = false;

  // API Key อ่านจาก --dart-define
  static const String _apiKey =
      String.fromEnvironment('GEMINI_API_KEY');

  // เลือกโมเดลที่ API Key ของเรารองรับ
  static const String _model = 'gemini-3.8-flash-lite';

  // Challenge 2: System Prompt
  static const String _systemPrompt = '''
คุณคือผู้ช่วย AI สำหรับนักศึกษาที่กำลังเรียน Flutter
และภาษา Dart

บุคลิกของคุณ:
1. พูดภาษาไทย สุภาพ เป็นกันเอง
2. อธิบายด้วยคำง่าย ๆ เข้าใจไม่ยาก
3. ตอบคำถามให้กระชับและตรงประเด็น
4. หากเป็นคำถามเกี่ยวกับโค้ด ให้ยกตัวอย่างประกอบ
5. หากผู้ใช้ไม่เข้าใจ ให้ช่วยอธิบายใหม่ทีละขั้นตอน
6. สามารถตอบคำถามทั่วไปได้
7. หากไม่แน่ใจในคำตอบ ให้บอกตามตรง
''';

  // เลื่อนหน้าจอไปข้อความล่าสุด
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // Challenge 2: ส่งข้อความพร้อม Chat History
  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty || _isLoading) return;

    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กรุณาตั้งค่า GEMINI_API_KEY ก่อนรันแอป',
          ),
        ),
      );
      return;
    }

    setState(() {
      _messages.add({
        'role': 'user',
        'text': message,
      });

      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    // เตรียมประวัติที่สำเร็จแล้ว
    // และเพิ่มข้อความล่าสุดของผู้ใช้
    final contents = [
      ..._chatHistory,
      {
        'role': 'user',
        'parts': [
          {'text': message}
        ],
      },
    ];

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/'
        'v1beta/models/$_model:generateContent',
      );

      http.Response? response;

      // Retry เมื่อเซิร์ฟเวอร์ไม่พร้อม
      for (int attempt = 0; attempt < 3; attempt++) {
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            // Challenge 2: กำหนดบุคลิก AI
            'systemInstruction': {
              'parts': [
                {'text': _systemPrompt}
              ],
            },

            // Challenge 2: ส่งประวัติทั้งหมด
            'contents': contents,
          }),
        ).timeout(
          const Duration(seconds: 45),
        );

        // ลองใหม่เฉพาะ 503
        if (response.statusCode != 503) {
          break;
        }

        if (attempt < 2) {
          await Future.delayed(
            Duration(seconds: 2 * (1 << attempt)),
          );
        }
      }

      if (response == null) {
        throw Exception('ไม่สามารถเชื่อมต่อ API ได้');
      }

      if (response.statusCode == 404) {
        throw Exception(
          'ไม่พบโมเดล AI หรือโมเดลไม่รองรับ API นี้ '
          'กรุณาตรวจสอบชื่อโมเดล',
        );
      }

      if (response.statusCode == 429) {
        throw Exception(
          'ใช้งาน API เกินขีดจำกัด '
          'กรุณาลองใหม่ภายหลัง',
        );
      }

      if (response.statusCode == 503) {
        throw Exception(
          'ขณะนี้ Gemini AI มีผู้ใช้งานจำนวนมาก '
          'กรุณาลองใหม่ภายหลัง',
        );
      }

      if (response.statusCode != 200) {
        debugPrint(
          'Gemini API error ${response.statusCode}: '
          '${response.body}',
        );

        throw Exception(
          'เชื่อมต่อ AI ไม่สำเร็จ '
          '(HTTP ${response.statusCode})',
        );
      }

      final data = jsonDecode(response.body)
          as Map<String, dynamic>;

      final candidates = data['candidates'] as List?;

      String answer = '';

      if (candidates != null && candidates.isNotEmpty) {
        final candidate =
            candidates.first as Map<String, dynamic>;

        final content =
            candidate['content'] as Map<String, dynamic>?;

        final parts = content?['parts'] as List?;

        if (parts != null) {
          answer = parts
              .whereType<Map<String, dynamic>>()
              .map((part) => part['text'])
              .whereType<String>()
              .join('\n');
        }
      }

      if (answer.trim().isEmpty) {
        throw Exception(
          'AI ไม่ได้ส่งข้อความตอบกลับ',
        );
      }

      if (!mounted) return;

      setState(() {
        // แสดงคำตอบบนหน้าจอ
        _messages.add({
          'role': 'assistant',
          'text': answer,
        });

        // บันทึกเฉพาะบทสนทนาที่สำเร็จ
        _chatHistory.add({
          'role': 'user',
          'parts': [
            {'text': message}
          ],
        });

        _chatHistory.add({
          'role': 'model',
          'parts': [
            {'text': answer}
          ],
        });
      });

      _scrollToBottom();
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'error',
          'text': 'AI ใช้เวลาตอบนานเกินไป '
              'กรุณาลองใหม่อีกครั้งค่ะ',
        });
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'error',
          'text': e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        });
      });

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Challenge 2: Clear Chat
  void _clearChat() {
    if (_isLoading) return;

    setState(() {
      _messages.clear();
      _chatHistory.clear();
      _controller.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล้างประวัติการสนทนาแล้ว'),
      ),
    );
  }

  // ถามยืนยันก่อนลบประวัติ
  Future<void> _confirmClearChat() async {
    if (_isLoading || _messages.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ล้างประวัติแชต'),
          content: const Text(
            'ต้องการลบข้อความสนทนาทั้งหมดหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ล้างแชต'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      _clearChat();
    }
  }

  // แสดงข้อความแต่ละฝั่ง
  Widget _buildMessageBubble(
    Map<String, String> item,
  ) {
    final role = item['role'];
    final isUser = role == 'user';
    final isError = role == 'error';

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF9DE4FC)
              : isError
                  ? const Color(0xFFFFE0E0)
                  : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          item['text'] ?? '',
          style: TextStyle(
            color: isError
                ? Colors.red.shade900
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFFFF8F5),

      appBar: AppBar(
        title: const Text('Gemini AI Chat'),
        backgroundColor: const Color(0xFFEF9AE6),
        foregroundColor: Colors.white,

        // ปุ่มล้างประวัติ
        actions: [
          IconButton(
            tooltip: 'Clear Chat',
            onPressed:
                _isLoading || _messages.isEmpty
                    ? null
                    : _confirmClearChat,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),

      body: Column(
        children: [
          // รายการข้อความ
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'สวัสดีค่ะ!\n'
                      'ลองพิมพ์ข้อความหา Gemini AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(
                        _messages[index],
                      );
                    },
                  ),
          ),

          // Loading
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(
                color: Color(0xFFEF9AE6),
              ),
            ),

          // ช่องพิมพ์ข้อความ
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ข้อความ...',
                      filled: true,
                      fillColor: isDark
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainer
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton.filled(
                  onPressed:
                      _isLoading ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF9AE6),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
