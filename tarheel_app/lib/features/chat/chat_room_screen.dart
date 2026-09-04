import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? contractId;
  final String? tripRequestId;

  const ChatRoomScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.contractId,
    this.tripRequestId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.contractId != null) {
        context.read<ChatProvider>().loadContractMessages(widget.contractId!);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _currentlyPlayingUrl = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final success = await context.read<ChatProvider>().sendTextMessage(
      receiverId: widget.receiverId,
      content: text,
      contractId: widget.contractId,
      tripRequestId: widget.tripRequestId,
    );

    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _handleSendVoiceNote() async {
    // محاكاة تسجيل صوتي وإرساله
    setState(() => _isRecording = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎙️ جاري تسجيل الرسالة الصوتية...'),
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isRecording = false);
    
    // Send simulated uploaded audio URL
    final success = await context.read<ChatProvider>().sendVoiceNote(
      receiverId: widget.receiverId,
      mediaUrl: 'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
      durationSeconds: 4,
      contractId: widget.contractId,
      tripRequestId: widget.tripRequestId,
    );

    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _handleSendLocation() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.accent),
            SizedBox(width: 8),
            Text('مشاركة الموقع الجغرافي'),
          ],
        ),
        content: const Text(
          'سيتم إرسال إحداثيات موقعك الحالي للطرف الآخر لتسهيل اللقاء وبدء الرحلة بأمان.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<ChatProvider>().sendLocationMessage(
                receiverId: widget.receiverId,
                latitude: 24.7136,
                longitude: 46.6753,
                locationAddress: 'طريق الملك فهد، الرياض',
                content: '📍 موقعي الحالي على الخريطة',
                contractId: widget.contractId,
                tripRequestId: widget.tripRequestId,
              );
              if (success) _scrollToBottom();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('مشاركة موقعي الآن'),
          ),
        ],
      ),
    );
  }

  Future<void> _playVoice(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      _currentlyPlayingUrl = url;
      await _audioPlayer.play(UrlSource(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?['id'];
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surface,
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0] : 'U',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'متصل الآن • محادثة آمنة وموثقة',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.white),
            tooltip: 'ضمان ترحيل',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🛡️ جميع المحادثات مشفرة وموثقة ضمن ضمان ترحيل المالي.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Security Alert Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.warningLight,
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تنبيه الأمان: يمنع تداول أرقام الهواتف أو الاتفاق خارج المنصة لحفظ حقوقك وضمانك المالي.',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد رسائل سابقة بعد',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ابدأ التواصل للتنسيق حول موعد ونقطة الانطلاق',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chat.messages[index];
                          final isMe = msg['senderId'] == currentUserId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    final type = msg['messageType'] ?? 'TEXT';
    final content = msg['content'] ?? '';
    final createdAt = msg['createdAt'] != null
        ? DateFormat('hh:mm a').format(DateTime.parse(msg['createdAt']))
        : '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: isMe ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message Body based on type
            if (type == 'TEXT')
              Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              )
            else if (type == 'VOICE_NOTE')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isPlaying && _currentlyPlayingUrl == msg['mediaUrl']
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: isMe ? Colors.white : AppColors.accent,
                      size: 32,
                    ),
                    onPressed: () {
                      if (msg['mediaUrl'] != null) {
                        _playVoice(msg['mediaUrl']);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تسجيل صوتي (${msg['durationSeconds'] ?? 0} ثانية)',
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white30 : AppColors.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (type == 'LOCATION')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_pin, color: isMe ? Colors.white : AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'موقع مرسل',
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (msg['locationAddress'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      msg['locationAddress'],
                      style: TextStyle(
                        color: isMe ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.15) : AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, size: 16, color: isMe ? Colors.white : AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'فتح الموقع بالخرائط',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 4),
            // Timestamp
            Text(
              createdAt,
              style: TextStyle(
                color: isMe ? Colors.white60 : AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Location Button
            IconButton(
              icon: const Icon(Icons.location_on_outlined, color: AppColors.secondary),
              tooltip: 'إرسال الموقع',
              onPressed: _handleSendLocation,
            ),

            // Voice Note Button
            IconButton(
              icon: Icon(
                _isRecording ? Icons.mic : Icons.mic_none_outlined,
                color: _isRecording ? AppColors.accent : AppColors.textSecondary,
              ),
              tooltip: 'تسجيل صوتي',
              onPressed: _handleSendVoiceNote,
            ),

            // Text Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك بأمان...',
                    hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Send Button
            Container(
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _handleSendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
