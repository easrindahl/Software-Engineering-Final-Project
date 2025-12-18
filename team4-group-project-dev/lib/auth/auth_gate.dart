import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team4_group_project/models/user_service.dart';
import 'package:team4_group_project/models/user_handler.dart';

//I literally don't understand why vs code is forcing me to keep this comment or it errors
// DON'T REMOVE THIS COMMENT || LOAD BEARING COMMENT
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.clientId, required this.signedIn});

  final String clientId;
  final Widget signedIn;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider()],

            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to GetInGame, please sign in!')
                    : const Text('Welcome to GetInGame, please sign up!'),
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        }

        // creating user based on auth gate info
        final user = snapshot.data;
        if (user != null) {
          final model = UserModel(
            id: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            photoUrl: user.photoURL ?? '',
          );

          UserService.createUserIfNotExists(
            model,
            subcollections: {
              'profile': {
                'meta': {'createdAt': FieldValue.serverTimestamp()},
              },
            },
          );
        }

        return signedIn;
      },
    );
  }
}
