import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Authentication buttons widget that provides Apple and Google sign-in options
class AuthButtons extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final auth = useAuth();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Apple Sign-In Button
        FutureBuilder<bool>(
          future: SignInWithApple.isAvailable(),
          builder: (context, snapshot) {
            final isAvailable = snapshot.data ?? false;

            if (!isAvailable) {
              return const SizedBox.shrink();
            }

            return ElevatedButton.icon(
              onPressed: auth.isLoggingIn
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      auth.signInWithApple();
                    },
              icon: Icon(
                Icons.apple,
                size: 24,
                color: Colors.white,
              ),
              label: const Text('Sign in with Apple'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            );
          },
        ),

        // Google Sign-In Button
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: auth.isLoggingIn
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  auth.signInWithGoogle();
                },
          icon: Image.asset('assets/img/google_logo.png', height: 18),
          label: const Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            // Google background color
            backgroundColor: Colors.white,
            // Google text color
            foregroundColor: Color(0xFF5F6368),
            // Google border color
            // side: BorderSide(color: Color(0xFFDADCE0)),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ],
    );
  }
}
