import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../service/bot_service.dart';

class AppColors {
  static const bgTop = Color(0xFF0B0B12);
  static const bgBottom = Color(0xFF0F1220);

  static const panel = Color(0xFF121426);
  static const panel2 = Color(0xFF0F1120);

  static const card = Color(0xFF161A2E);
  static const stroke = Color(0x22FFFFFF);

  static const primary = Color(0xFF6C63FF);
  static const primary2 = Color(0xFF8A7DFF);

  static const text = Color(0xFFF2F3FF);
  static const textMuted = Color(0xB3C7C9FF);
}

class ChatbotLauncherButton extends StatelessWidget {
  const ChatbotLauncherButton({super.key, required Null Function() onTap});

  void _openChatPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        final size = MediaQuery.of(ctx).size;
        final double dialogWidth = size.width < 520 ? size.width * 0.95 : 520;
        final double dialogHeight = size.height < 720
            ? size.height * 0.88
            : 680;

        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: const ChatScreen(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  offset: Offset(0, 14),
                  color: Color(0x55000000),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => _openChatPopup(context),
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text("Chat"),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];

  final _bot = GroqChatService();
  bool _botTyping = false;

  @override
  void initState() {
    super.initState();
    _pushBot(_greeting());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _greeting() {
    return "Hi, I’m Doctor Assist AI 👋\n\n"
        "Ask me anything about heart health, risk, or lifestyle.\n"
        "I’ll give general guidance only — confirm with your doctor.";
  }

  void _pushBot(String text) {
    setState(() {
      _messages.add(
        ChatMessage(id: UniqueKey().toString(), role: "assistant", text: text),
      );
    });
    _jumpToEnd();
  }

  void _pushUser(String text) {
    setState(() {
      _messages.add(
        ChatMessage(id: UniqueKey().toString(), role: "user", text: text),
      );
    });
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 140,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _pushUser(text);
    setState(() => _botTyping = true);

    try {
      final reply = await _bot.sendMessage(userInput: text, history: _messages);
      if (!mounted) return;
      setState(() => _botTyping = false);
      _pushBot(reply);
    } catch (e) {
      if (!mounted) return;
      setState(() => _botTyping = false);
      _pushBot("Sorry, I couldn’t reach the assistant right now.\n\nError: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: Column(
          children: [
            // ---------- Modern Glass App Bar ----------
            SafeArea(
              bottom: false,
              child: _GlassBar(
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Doctor Assist AI",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "General guidance • Not a diagnosis",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white70,
                      tooltip: "Close",
                    ),
                  ],
                ),
              ),
            ),

            // ---------- Chat List ----------
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _messages.length + (_botTyping ? 1 : 0),
                itemBuilder: (ctx, i) {
                  final m = _messages[i];
                  final isUser = m.role == "user";

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isUser) ...[const SizedBox(width: 8)],
                        Flexible(
                          child: _ChatBubble(text: m.text, isUser: isUser),
                        ),
                        if (isUser) ...const [
                          SizedBox(width: 8),
                          _UserAvatar(size: 34),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // ---------- Input ----------
            _InputBar(controller: _controller, onSend: _send),
          ],
        ),
      ),
    );
  }
}

// ======================= UI PARTS =======================

class _GlassBar extends StatelessWidget {
  final Widget child;
  const _GlassBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.panel.withOpacity(0.72),
            border: const Border(
              bottom: BorderSide(color: AppColors.stroke, width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary2],
              )
            : null,
        color: isUser ? null : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUser ? Colors.transparent : AppColors.stroke,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : AppColors.text,
          height: 1.35,
          fontSize: 14.5,
        ),
      ),
    );
  }
}

/// Professional Avatar:
/// - gradient circle + border + shadow
/// - inner contrast circle so cloud always visible
/// - image uses "centerSlice" feel with BoxFit.contain
class _BotAvatar extends StatelessWidget {
  final String assetPath;
  final double size;

  const _BotAvatar({required this.assetPath, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final double innerPad = size <= 34 ? 5 : 7;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary2],
        ),
        border: Border.all(color: AppColors.stroke),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 10),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.14),
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final double size;
  const _UserAvatar({this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF20244A),
        border: Border.all(color: AppColors.stroke),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 8),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white.withOpacity(0.75),
          size: size * 0.48,
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar>
    with SingleTickerProviderStateMixin {
  bool _userTyping = false;

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _syncTyping();
    widget.controller.addListener(_syncTyping);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTyping);
    _float.dispose();
    super.dispose();
  }

  void _syncTyping() {
    final nowTyping = widget.controller.text.trim().isNotEmpty;
    if (nowTyping == _userTyping) return;
    setState(() => _userTyping = nowTyping);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Glass container
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.panel.withOpacity(0.70),
                    border: Border.all(color: AppColors.stroke),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 10),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            height: 1.35,
                          ),
                          decoration: InputDecoration(
                            hintText: "Message…",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: AppColors.panel2.withOpacity(0.9),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => widget.onSend(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 46,
                        width: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: widget.onSend,
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Cloud "sticker" (always visible + subtle float)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: _userTyping ? -10 : -18,
              left: _userTyping ? 8 : 12,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _float,
                  builder: (_, __) {
                    final dy = lerpDouble(-1.2, 1.2, _float.value)!;
                    final scale = _userTyping ? 0.95 : 1.0;

                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(opacity: 0.98),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingRow extends StatelessWidget {
  final String cloudAssetPath;
  const _TypingRow({required this.cloudAssetPath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _BotAvatar(assetPath: cloudAssetPath, size: 34),
          const SizedBox(width: 8),
          const _TypingBubble(),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          int dots = 1 + ((t * 3).floor() % 3);
          return Text(
            "Typing${"." * dots}",
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          );
        },
      ),
    );
  }
}
