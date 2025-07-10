import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  final String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  String? _apiKey;
  bool _isInitialized = false;
  
  factory AIService() {
    return _instance;
  }
  
  AIService._internal();
  
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load API key from .env file
      await dotenv.load().catchError((e) {
        debugPrint('Error loading .env file: $e');
      });
      
      _apiKey = dotenv.env['GEMINI_API_KEY'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('Missing Gemini API key. Please check your .env file.');
      }
      
      _isInitialized = true;
      debugPrint('AI Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AI Service: $e');
      rethrow;
    }
  }
  
  // Function to generate a chat response
  Future<Map<String, dynamic>> generateChatResponse(
    String userMessage, 
    List<Map<String, String>> chatHistory,
    List<Map<String, dynamic>> teamMembers,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Define function declarations for the model
      final List<Map<String, dynamic>> functionDeclarations = [
        {
          "name": "create_task",
          "description": "Create a new task in the system",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string",
                "description": "The title of the task"
              },
              "description": {
                "type": "string",
                "description": "The description of the task"
              },
              "due_date": {
                "type": "string",
                "description": "The due date of the task in ISO format (YYYY-MM-DD)"
              },
              "assigned_to": {
                "type": "string",
                "description": "The user ID to assign the task to"
              }
            },
            "required": ["title"]
          }
        },
        {
          "name": "create_ticket",
          "description": "Create a new support ticket in the system",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string",
                "description": "The title of the ticket"
              },
              "description": {
                "type": "string",
                "description": "The description of the ticket"
              },
              "priority": {
                "type": "string",
                "enum": ["low", "medium", "high", "critical"],
                "description": "The priority level of the ticket"
              },
              "category": {
                "type": "string",
                "enum": ["Bug", "Feature Request", "UI/UX", "Performance", "Documentation", "Security", "Other"],
                "description": "The category of the ticket"
              },
              "assigned_to": {
                "type": "string",
                "description": "The user ID to assign the ticket to"
              }
            },
            "required": ["title", "priority", "category"]
          }
        },
        {
          "name": "create_meeting",
          "description": "Schedule a new meeting",
          "parameters": {
            "type": "object",
            "properties": {
              "title": {
                "type": "string",
                "description": "The title of the meeting"
              },
              "description": {
                "type": "string",
                "description": "The description of the meeting"
              },
              "meeting_date": {
                "type": "string",
                "description": "The date and time of the meeting in ISO format (YYYY-MM-DDTHH:MM:SS)"
              },
              "meeting_url": {
                "type": "string",
                "description": "The URL for the virtual meeting (optional)"
              }
            },
            "required": ["title", "meeting_date"]
          }
        }
      ];

      // Create the contents array with chat history
      final List<Map<String, dynamic>> contents = [];
      
      // Create team member context for the model
      String teamMemberContext = "Available team members:\n";
      for (var member in teamMembers) {
        teamMemberContext += "- ${member['full_name']} (${member['role']}): ${member['id']}\n";
      }
      
      // Add system message as the first message with role "model"
      contents.add({
        "role": "model",
        "parts": [
          {
            "text": "You are a helpful assistant for a team collaboration app. You can help users create tasks, tickets, and schedule meetings. When appropriate, call the relevant function to help users.\n\n" +
                    "Current date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\n\n" +
                    "$teamMemberContext\n\n" +
                    "Guidelines for creating tasks and tickets:\n" +
                    "1. Create descriptive, clear titles that summarize the task/ticket purpose\n" +
                    "2. Provide detailed descriptions with all relevant information\n" +
                    "3. When users mention dates like 'tomorrow', 'next week', etc., convert them to proper ISO date format (YYYY-MM-DD)\n" +
                    "4. For tickets, choose the appropriate priority and category based on the request\n" +
                    "5. If the user doesn't specify who to assign the task/ticket to, leave it unassigned\n" +
                    "6. If the user mentions a team member by name, assign it to that person\n" +
                    "7. Always confirm with the user before creating a task or ticket\n" +
                    "8. If the user provides minimal information, ask follow-up questions to get necessary details before creating a task/ticket"
          }
        ]
      });
      
      // Add chat history
      for (var message in chatHistory) {
        String role = message["role"] ?? "user";
        // Ensure role is either "user" or "model", not "system"
        if (role != "user" && role != "model") {
          role = "user";
        }
        
        contents.add({
          "role": role,
          "parts": [
            {
              "text": message["content"] ?? ""
            }
          ]
        });
      }
      
      // Add the current user message
      contents.add({
        "role": "user",
        "parts": [
          {
            "text": userMessage
          }
        ]
      });
      
      // Create the request body
      final Map<String, dynamic> requestBody = {
        "contents": contents,
        "tools": [
          {
            "functionDeclarations": functionDeclarations
          }
        ],
        "toolConfig": {
          "functionCallingConfig": {
            "mode": "AUTO"
          }
        },
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 1024
        }
      };
      
      // Make the API request
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Check if the response contains a function call
        final candidates = responseData['candidates'] as List<dynamic>;
        if (candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>;
          
          for (var part in parts) {
            if (part.containsKey('functionCall')) {
              final functionCall = part['functionCall'];
              final functionName = functionCall['name'];
              final arguments = functionCall['args'];
              
              return {
                'type': 'function_call',
                'function_name': functionName,
                'arguments': arguments,
                'raw_response': jsonEncode(responseData),
              };
            }
          }
          
          // If no function call is detected, return as regular message
          return {
            'type': 'message',
            'content': candidates[0]['content']['parts'][0]['text'] ?? '',
          };
        }
        
        return {
          'type': 'error',
          'content': 'No response generated',
        };
      } else {
        debugPrint('Error from Gemini API: ${response.statusCode} ${response.body}');
        return {
          'type': 'error',
          'content': 'Sorry, I encountered an error while processing your request.',
        };
      }
    } catch (e) {
      debugPrint('Error generating chat response: $e');
      return {
        'type': 'error',
        'content': 'Sorry, I encountered an error while processing your request.',
      };
    }
  }
  
  // Function to handle tool responses
  Future<String> handleToolResponse({
    required String functionName,
    required Map<String, dynamic> arguments,
    required String rawResponse,
    required Map<String, dynamic> result,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Parse the raw response to extract the model's message
      final parsedRawResponse = jsonDecode(rawResponse);
      final modelContent = parsedRawResponse['candidates'][0]['content'];
      
      // Create the contents array for the follow-up request
      final List<Map<String, dynamic>> contents = [];
      
      // Add the original model response with the function call
      contents.add({
        "role": "model",
        "parts": [
          {
            "functionCall": {
              "name": functionName,
              "args": arguments
            }
          }
        ]
      });
      
      // Add the function response as a user turn
      contents.add({
        "role": "user",
        "parts": [
          {
            "functionResponse": {
              "name": functionName,
              "response": {
                "content": result
              }
            }
          }
        ]
      });
      
      // Create the request body
      final Map<String, dynamic> requestBody = {
        "contents": contents,
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 512
        }
      };
      
      // Make the API request
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final candidates = responseData['candidates'] as List<dynamic>;
        if (candidates.isNotEmpty) {
          return candidates[0]['content']['parts'][0]['text'] ?? 'Function executed successfully.';
        }
        return 'Function executed successfully.';
      } else {
        debugPrint('Error from Gemini API: ${response.statusCode} ${response.body}');
        return 'The operation was completed, but I encountered an error while generating a response.';
      }
    } catch (e) {
      debugPrint('Error handling tool response: $e');
      return 'The operation was completed successfully.';
    }
  }
} 