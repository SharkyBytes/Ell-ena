import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  AppwriteService._internal();

  // Appwrite client
  late final Client client;
  late final Account account;
  late final Databases databases;

  // Collection IDs - these match the ones you've already created in Appwrite
  static const String teamsCollectionId = 'teams';
  static const String teamMembersCollectionId = 'team_members';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      client = Client();
      
      // Configure the client with endpoint and project ID
      client
        .setEndpoint(dotenv.get('APPWRITE_ENDPOINT'))
        .setProject(dotenv.get('APPWRITE_PROJECT_ID'));
      
      // Only set self-signed in debug mode
      if (kDebugMode) {
        client.setSelfSigned(status: true);
      }

      account = Account(client);
      databases = Databases(client);
      _isInitialized = true;
      
      if (kDebugMode) {
        print('Appwrite client initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Appwrite client: $e');
      }
      rethrow;
    }
  }

  // Generate a random 6-character alphanumeric team ID
  String generateTeamId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      List.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Create a new user account
  Future<User> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await init();
      
      if (kDebugMode) {
        print('Creating account for email: $email');
      }
      
      final result = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      
      if (kDebugMode) {
        print('Account created successfully: ${result.$id}');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating account: $e');
      }
      rethrow;
    }
  }

  // Create a session (login)
  Future<Session> createSession({
    required String email,
    required String password,
  }) async {
    try {
      await init();
      
      if (kDebugMode) {
        print('Creating session for email: $email');
      }
      
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      
      // Verify the session was created successfully
      if (kDebugMode) {
        print('Session created successfully: ${session.$id}');
      }
      
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating session: $e');
      }
      rethrow;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      await init();
      final user = await account.get();
      return user.$id.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('User not logged in: $e');
      }
      return false;
    }
  }

  // Get all active sessions
  Future<List<Session>> getSessions() async {
    try {
      await init();
      final sessions = await account.listSessions();
      return sessions.sessions;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting sessions: $e');
      }
      return [];
    }
  }

  // Delete the current session (logout)
  Future<void> deleteSession() async {
    try {
      await init();
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting session: $e');
      }
      rethrow;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      await init();
      return await account.get();
    } catch (e) {
      // If no session exists, this will throw an exception
      if (kDebugMode) {
        print('Error getting current user: $e');
      }
      return null;
    }
  }

  // Create a new team (admin user)
  Future<void> createTeam({
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      await init();
      
      // Generate a unique team ID
      final teamId = generateTeamId();
      
      // Create team document
      await databases.createDocument(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamsCollectionId,
        documentId: ID.unique(),
        data: {
          'teamId': teamId,
          'teamName': 'Team $name', // Default team name
          'adminUserId': userId,
          'adminName': name,
          'adminEmail': email,
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(userId)), // Admin can read
          Permission.update(Role.user(userId)), // Admin can update
          Permission.delete(Role.user(userId)), // Admin can delete
        ],
      );
      
      // Add admin to team_members collection
      await databases.createDocument(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamMembersCollectionId,
        documentId: ID.unique(),
        data: {
          'memberUserId': userId,
          'name': name,
          'email': email,
          'teamId': teamId,
          'isAdmin': true,
          'joinedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(userId)), // Admin can read own document
          Permission.update(Role.user(userId)), // Admin can update own document
        ],
      );
      
      return;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating team: $e');
      }
      rethrow;
    }
  }
  
  // Join an existing team (team member)
  Future<void> joinTeam({
    required String teamId,
    required String userId,
    required String name,
    required String email,
  }) async {
    try {
      await init();
      
      // Verify the team exists
      final teamDocs = await databases.listDocuments(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamsCollectionId,
        queries: [
          Query.equal('teamId', teamId),
        ],
      );
      
      if (teamDocs.documents.isEmpty) {
        throw Exception('Team not found. Please check the team ID and try again.');
      }
      
      final teamDoc = teamDocs.documents.first;
      final adminUserId = teamDoc.data['adminUserId'] as String;
      
      // Add user to team_members collection
      await databases.createDocument(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamMembersCollectionId,
        documentId: ID.unique(),
        data: {
          'memberUserId': userId,
          'name': name,
          'email': email,
          'teamId': teamId,
          'isAdmin': false,
          'joinedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(userId)), // User can read own document
          Permission.update(Role.user(userId)), // User can update own document
          Permission.read(Role.user(adminUserId)), // Admin can read
          Permission.update(Role.user(adminUserId)), // Admin can update
          Permission.delete(Role.user(adminUserId)), // Admin can delete
        ],
      );
      
      return;
    } catch (e) {
      if (kDebugMode) {
        print('Error joining team: $e');
      }
      rethrow;
    }
  }
  
  // Check if a team ID exists
  Future<bool> checkTeamExists(String teamId) async {
    try {
      await init();
      
      final teamDocs = await databases.listDocuments(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamsCollectionId,
        queries: [
          Query.equal('teamId', teamId),
        ],
      );
      
      return teamDocs.documents.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking team: $e');
      }
      rethrow;
    }
  }
  
  // Get user's team information
  Future<List<Map<String, dynamic>>> getUserTeams({required String userId}) async {
    try {
      await init();
      
      // First check if the user is an admin of any team
      final adminTeamDocs = await databases.listDocuments(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamsCollectionId,
        queries: [
          Query.equal('adminUserId', userId),
        ],
      );
      
      // Then check the team_members collection
      final memberDocs = await databases.listDocuments(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamMembersCollectionId,
        queries: [
          Query.equal('memberUserId', userId),
        ],
      );
      
      final result = <Map<String, dynamic>>[];
      
      // If the user is an admin of any team
      for (final doc in adminTeamDocs.documents) {
        result.add({
          'teamId': doc.data['teamId'],
          'teamName': doc.data['teamName'],
          'isAdmin': true,
        });
      }
      
      // If the user is a member of any team
      for (final doc in memberDocs.documents) {
        // Only add if not already added as admin
        final teamId = doc.data['teamId'];
        final isAlreadyAdded = result.any((team) => team['teamId'] == teamId);
        
        if (!isAlreadyAdded) {
          result.add({
            'teamId': teamId,
            'isAdmin': doc.data['isAdmin'],
          });
        }
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user teams: $e');
      }
      rethrow;
    }
  }
  
  // Static methods for direct access

  static Future<String> createTeamAndAdminAccount({
    required String teamName, 
    required String adminName, 
    required String adminEmail, 
    required String password
  }) async {
    final service = AppwriteService();
    await service.init();
    
    try {
      // Create admin account
      final user = await service.createAccount(
        email: adminEmail,
        password: password,
        name: adminName
      );
      
      // Login to get session
      await service.createSession(
        email: adminEmail,
        password: password
      );
      
      // Generate team ID
      final teamId = service.generateTeamId();
      
      // Create team
      await service.databases.createDocument(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamsCollectionId,
        documentId: ID.unique(),
        data: {
          'teamId': teamId,
          'teamName': teamName,
          'adminUserId': user.$id,
          'adminName': adminName,
          'adminEmail': adminEmail,
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ]
      );
      
      // Add admin to team members
      await service.databases.createDocument(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamMembersCollectionId,
        documentId: ID.unique(),
        data: {
          'memberUserId': user.$id,
          'name': adminName,
          'email': adminEmail,
          'teamId': teamId,
          'isAdmin': true,
          'joinedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id))
        ]
      );
      
      return teamId;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating team and admin account: $e');
      }
      rethrow;
    }
  }
  
  static Future<void> joinTeamAndCreateUserAccount({
    required String teamIdToJoin,
    required String userName,
    required String userEmail,
    required String password
  }) async {
    final service = AppwriteService();
    await service.init();
    
    try {
      // Check if team exists
      final teamExists = await service.checkTeamExists(teamIdToJoin);
      if (!teamExists) {
        throw Exception('Team not found. Please check the team ID and try again.');
      }
      
      // Get team info to get admin
      final teamDocs = await service.databases.listDocuments(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamsCollectionId,
        queries: [
          Query.equal('teamId', teamIdToJoin),
        ],
      );
      
      final teamDoc = teamDocs.documents.first;
      final adminUserId = teamDoc.data['adminUserId'] as String;
      
      // Create user account
      final user = await service.createAccount(
        email: userEmail,
        password: password,
        name: userName
      );
      
      // Login to get session
      await service.createSession(
        email: userEmail,
        password: password
      );
      
      // Add user to team members
      await service.databases.createDocument(
        databaseId: dotenv.get('APPWRITE_DATABASE_ID'),
        collectionId: teamMembersCollectionId,
        documentId: ID.unique(),
        data: {
          'memberUserId': user.$id,
          'name': userName,
          'email': userEmail,
          'teamId': teamIdToJoin,
          'isAdmin': false,
          'joinedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.read(Role.user(adminUserId)),
          Permission.update(Role.user(adminUserId)),
          Permission.delete(Role.user(adminUserId)),
        ]
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error joining team and creating user account: $e');
      }
      rethrow;
    }
  }
  
  static Future<bool> checkTeamIdExists(String teamId) async {
    final service = AppwriteService();
    return await service.checkTeamExists(teamId);
  }
} 