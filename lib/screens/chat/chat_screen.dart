import 'package:flutter/material.dart';
import 'package:ell_ena/services/ai_service.dart';
import 'package:ell_ena/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _isListening = false;
  late AnimationController _waveformController;
  
  // Services
  final AIService _aiService = AIService();
  final SupabaseService _supabaseService = SupabaseService();
  
  // Team members for assignment
  List<Map<String, dynamic>> _teamMembers = [];

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Initialize AI service
      if (!_aiService.isInitialized) {
        await _aiService.initialize();
      }
      
      // Load team members for task assignment
      if (_supabaseService.isInitialized) {
        final userProfile = await _supabaseService.getCurrentUserProfile();
        if (userProfile != null && userProfile['team_id'] != null) {
          await _loadTeamMembers(userProfile['team_id']);
        }
      }
      
      // Add welcome message
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Hello! I'm Ell-ena, your AI assistant. How can I help you today?",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _loadTeamMembers(String teamId) async {
    try {
      final members = await _supabaseService.getTeamMembers(teamId);
      if (mounted) {
        setState(() {
          _teamMembers = members;
        });
      }
    } catch (e) {
      debugPrint('Error loading team members: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_isProcessing) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isProcessing = true;
    });

    _scrollToBottom();
    
    try {
      // Convert chat history to format expected by AI service
      final chatHistory = _getChatHistoryForAI();
      
      // Get response from AI service
      final response = await _aiService.generateChatResponse(
        userMessage, 
        chatHistory,
        _teamMembers,
      );
      
      if (response['type'] == 'function_call') {
        // Handle function call
        await _handleFunctionCall(
          response['function_name'], 
          response['arguments'],
          response['raw_response'],
        );
      } else {
        // Add assistant message
        setState(() {
          _messages.add(
            ChatMessage(
              text: response['content'],
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isProcessing = false;
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error. Please try again later.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isProcessing = false;
      });
    }

    _scrollToBottom();
  }
  
  // Convert chat history to format expected by AI service
  List<Map<String, String>> _getChatHistoryForAI() {
    // Limit to last 10 messages to avoid token limits
    final recentMessages = _messages.length > 10 
        ? _messages.sublist(_messages.length - 10) 
        : _messages;
    
    return recentMessages.map((message) {
      return {
        "role": message.isUser ? "user" : "assistant",
        "content": message.text,
      };
    }).toList();
  }
  
  // Handle function calls from the AI
  Future<void> _handleFunctionCall(
    String functionName, 
    Map<String, dynamic> arguments,
    String rawResponse,
  ) async {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "I'll help you with that. Let me process your request...",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    
    _scrollToBottom();
    
    try {
      Map<String, dynamic> result = {'success': false, 'error': 'Function not implemented'};
      
      // Execute the appropriate function based on the function name
      switch (functionName) {
        case 'create_task':
          result = await _createTask(arguments);
          break;
        case 'create_ticket':
          result = await _createTicket(arguments);
          break;
        case 'create_meeting':
          result = await _createMeeting(arguments);
          break;
        default:
          result = {'success': false, 'error': 'Unknown function'};
      }
      
      // Get a user-friendly response from the AI
      final responseMessage = await _aiService.handleToolResponse(
        functionName: functionName,
        arguments: arguments,
        rawResponse: rawResponse,
        result: result,
      );
      
      // Add the response to the chat
      setState(() {
        _messages.add(
          ChatMessage(
            text: responseMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        
        // Add card if successful
        if (result['success'] == true) {
          _messages.add(
            ChatMessage(
              text: _getCardText(functionName, arguments, result),
              isUser: false,
              timestamp: DateTime.now(),
              isCard: true,
              cardType: _getCardType(functionName),
              cardData: result,
            ),
          );
        }
        
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error handling function call: $e');
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an error while processing your request.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isProcessing = false;
      });
    }
    
    _scrollToBottom();
  }
  
  // Create a task using the Supabase service
  Future<Map<String, dynamic>> _createTask(Map<String, dynamic> arguments) async {
    try {
      if (!_supabaseService.isInitialized) {
        return {'success': false, 'error': 'Service not initialized'};
      }
      
      final title = arguments['title'] as String;
      final description = arguments['description'] as String?;
      
      // Parse due date if provided
      DateTime? dueDate;
      if (arguments['due_date'] != null) {
        try {
          dueDate = DateTime.parse(arguments['due_date']);
        } catch (e) {
          debugPrint('Error parsing due date: $e');
        }
      }
      
      // Get assigned user ID if provided
      String? assignedToUserId;
      final assignedTo = arguments['assigned_to'] as String?;
      
      if (assignedTo != null && assignedTo.isNotEmpty) {
        // Check if the value is already a valid UUID
        final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
        
        if (uuidPattern.hasMatch(assignedTo)) {
          // It's already a UUID
          assignedToUserId = assignedTo;
        } else {
          // Try to find the user by name
          final matchingMember = _teamMembers.firstWhere(
            (member) => member['full_name'].toString().toLowerCase() == assignedTo.toLowerCase(),
            orElse: () => {},
          );
          
          if (matchingMember.isNotEmpty && matchingMember['id'] != null) {
            assignedToUserId = matchingMember['id'];
          }
        }
      }
      
      // Create the task
      final result = await _supabaseService.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        assignedToUserId: assignedToUserId,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error creating task: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Create a ticket using the Supabase service
  Future<Map<String, dynamic>> _createTicket(Map<String, dynamic> arguments) async {
    try {
      if (!_supabaseService.isInitialized) {
        return {'success': false, 'error': 'Service not initialized'};
      }
      
      final title = arguments['title'] as String;
      final description = arguments['description'] as String?;
      final priority = arguments['priority'] as String;
      final category = arguments['category'] as String;
      
      // Get assigned user ID if provided
      String? assignedToUserId;
      final assignedTo = arguments['assigned_to'] as String?;
      
      if (assignedTo != null && assignedTo.isNotEmpty) {
        // Check if the value is already a valid UUID
        final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
        
        if (uuidPattern.hasMatch(assignedTo)) {
          // It's already a UUID
          assignedToUserId = assignedTo;
        } else {
          // Try to find the user by name
          final matchingMember = _teamMembers.firstWhere(
            (member) => member['full_name'].toString().toLowerCase() == assignedTo.toLowerCase(),
            orElse: () => {},
          );
          
          if (matchingMember.isNotEmpty && matchingMember['id'] != null) {
            assignedToUserId = matchingMember['id'];
          }
        }
      }
      
      // Create the ticket
      final result = await _supabaseService.createTicket(
        title: title,
        description: description,
        priority: priority,
        category: category,
        assignedToUserId: assignedToUserId,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Create a meeting using the Supabase service
  Future<Map<String, dynamic>> _createMeeting(Map<String, dynamic> arguments) async {
    try {
      if (!_supabaseService.isInitialized) {
        return {'success': false, 'error': 'Service not initialized'};
      }
      
      final title = arguments['title'] as String;
      final description = arguments['description'] as String?;
      
      // Parse meeting date
      DateTime meetingDate;
      try {
        meetingDate = DateTime.parse(arguments['meeting_date']);
      } catch (e) {
        debugPrint('Error parsing meeting date: $e');
        return {'success': false, 'error': 'Invalid meeting date format'};
      }
      
      final meetingUrl = arguments['meeting_url'] as String?;
      
      // Create the meeting
      final result = await _supabaseService.createMeeting(
        title: title,
        description: description,
        meetingDate: meetingDate,
        meetingUrl: meetingUrl,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  // Get card type based on function name
  String _getCardType(String functionName) {
    switch (functionName) {
      case 'create_task':
        return 'task';
      case 'create_ticket':
        return 'ticket';
      case 'create_meeting':
        return 'meeting';
      default:
        return 'generic';
    }
  }
  
  // Get card text based on function name and arguments
  String _getCardText(String functionName, Map<String, dynamic> arguments, Map<String, dynamic> result) {
    switch (functionName) {
      case 'create_task':
        return arguments['title'] ?? 'New Task';
      case 'create_ticket':
        return arguments['title'] ?? 'New Ticket';
      case 'create_meeting':
        return arguments['title'] ?? 'New Meeting';
      default:
        return 'Item created';
    }
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

  void _navigateToItem(ChatMessage message) {
    if (message.cardType == 'task') {
      // Navigate to workspace screen and select tasks tab
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
        arguments: {'screen': 2, 'tab': 0}, // 2 for workspace, 0 for tasks tab
      );
    } else if (message.cardType == 'ticket') {
      // Navigate to workspace screen and select tickets tab
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
        arguments: {'screen': 2, 'tab': 1}, // 2 for workspace, 1 for tickets tab
      );
    } else if (message.cardType == 'meeting') {
      // Navigate to calendar screen
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
        arguments: {'screen': 1}, // 1 for calendar
      );
    }
  }

  void _showVoiceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              height: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Start speaking...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _waveformController,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 4,
                            height:
                                32 +
                                32 *
                                    (0.5 +
                                            0.5 *
                                                _waveformController.value *
                                                (index % 2 == 0 ? 1 : -1))
                                        .abs(),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _messageController.text =
                            "Create a math assignment for next Tuesday and set the deadline for Wednesday.";
                      });
                    },
                    child: const Text(
                      'Stop Listening',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Chat with Ell-ena',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your AI Assistant',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Start a conversation with Ell-ena',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isProcessing ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_isProcessing && index == _messages.length) {
                          // Show typing indicator
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                          );
                        }
                        
                        final message = _messages[index];
                        if (message.isCard == true) {
                          return _ItemCard(
                            message: message,
                            onViewItem: () => _navigateToItem(message),
                          );
                        }
                        return _ChatBubble(message: message);
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _showVoiceDialog,
                    icon: const Icon(Icons.mic),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _isProcessing ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.green : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(message.text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onViewItem;

  const _ItemCard({required this.message, required this.onViewItem});

  @override
  Widget build(BuildContext context) {
    // Set icon and title based on card type
    IconData icon;
    String title;
    
    switch (message.cardType) {
      case 'task':
        icon = Icons.task_alt;
        title = 'New Task';
        break;
      case 'ticket':
        icon = Icons.confirmation_number;
        title = 'New Ticket';
        break;
      case 'meeting':
        icon = Icons.calendar_today;
        title = 'New Meeting';
        break;
      default:
        icon = Icons.check_circle;
        title = 'Item Created';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (message.cardType == 'task' || message.cardType == 'ticket')
                  Text(
                    'Created just now',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                if (message.cardType == 'meeting' && message.cardData != null && message.cardData!['meeting'] != null)
                  Text(
                    _formatDate(message.cardData!['meeting']['meeting_date']),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onViewItem,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View ${message.cardType?.capitalize() ?? 'Item'}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.green,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isCard;
  final String? cardType; // 'task', 'ticket', 'meeting'
  final Map<String, dynamic>? cardData;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isCard = false,
    this.cardType,
    this.cardData,
  });
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
