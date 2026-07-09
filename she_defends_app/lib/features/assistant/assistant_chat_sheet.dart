import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

class AssistantChatSheet extends ConsumerStatefulWidget {
  const AssistantChatSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<AssistantChatSheet> createState() => _AssistantChatSheetState();
}

class _AssistantChatSheetState extends ConsumerState<AssistantChatSheet> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  
  final _apiClient = ApiClient();

  final List<String> _quickPrompts = [
    "I have headaches.",
    "I'm walking home.",
    "I feel anxious.",
    "I forgot my medicine."
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message to provider list
    ref.read(chatProvider.notifier).addMessage(text, true);
    _messageController.clear();
    setState(() => _isTyping = true);
    _scrollToBottom();

    // Collect current chat history from provider
    final history = ref.read(chatProvider).map((msg) => {
      "role": msg.isUser ? "user" : "model",
      "content": msg.text
    }).toList();

    try {
      final response = await _apiClient.post("/assistant/chat", data: {
        "message": text,
        "history": history,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        ref.read(chatProvider.notifier).addMessage(
          data["response"] ?? "I'm processing that for you.",
          false,
          route: data["route"],
        );
      }
    } catch (e) {
      debugPrint("AI chatbot API failed: $e");
      ref.read(chatProvider.notifier).addMessage(
        "I'm having trouble connecting to my cognitive services, but I'm here to support you offline.",
        false,
      );
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _handleDeepLinkRoute(String route) {
    Navigator.pop(context); // Close chat drawer sheet

    if (route == "/health/symptoms") {
      ref.read(currentTabProvider.notifier).state = 1; // Open Health Tab
    } else if (route == "/safety/guardian") {
      ref.read(currentTabProvider.notifier).state = 2; // Open Safety Tab
    } else if (route == "/wellness/meditate") {
      ref.read(currentTabProvider.notifier).state = 3; // Open Wellness Tab
    } else if (route == "/safety/sos") {
      ref.read(currentTabProvider.notifier).state = 2; // Open Safety Tab
      ref.read(sosProvider.notifier).startCountdown(); // Start immediate SOS countdown
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // Grab handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                const Text("✨", style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("SheDefends AI Helper", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                    Text("Warm. Empathetic. Protective.", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(),

          // Chat messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // In-progress typing skeletal loader
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.lavender.withOpacity(0.5),
                    child: const Text("✨", style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  const Text("Thinking...", style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // Quick chips suggestions
          if (messages.length == 1)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(_quickPrompts[index], style: const TextStyle(fontSize: 13)),
                      backgroundColor: AppColors.lightGray,
                      side: BorderSide.none,
                      onPressed: () => _sendMessage(_quickPrompts[index]),
                    ),
                  );
                },
              ),
            ),
            
          const SizedBox(height: 12),

          // Bottom input panel
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Type or ask your companion...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) => _sendMessage(text),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () => _sendMessage(_messageController.text),
                  icon: const Icon(Icons.send, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final align = msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.isUser ? AppColors.primary : AppColors.lightGray;
    final textColor = msg.isUser ? Colors.white : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.lavender,
                  child: const Text("✨", style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                      topLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
          
          // Deep-link routing action shortcuts (if returned by Flask AI route advice)
          if (msg.route != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 44.0),
              child: ElevatedButton.icon(
                onPressed: () => _handleDeepLinkRoute(msg.route!),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(_getRouteButtonLabel(msg.route!)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryActive,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  String _getRouteButtonLabel(String route) {
    if (route == "/health/symptoms") return "Launch Symptom Checker";
    if (route == "/safety/guardian") return "Open Guardian Maps";
    if (route == "/wellness/meditate") return "Go to Wellness Sanctuary";
    if (route == "/safety/sos") return "Activate Emergency Alarm";
    return "Open Action Module";
  }
}
