import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../shared/widgets/google_sign_in_button.dart';
import '../domain/auth_state.dart';
import 'auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  VideoPlayerController? _videoController;
  bool _introStarted = false;
  bool _showLoginButton = false;

  @override
  void initState() {
    super.initState();
    // Start intro immediately so there is zero delay before the splash plays
    _startIntro();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the first-frame asset so Flutter can render it instantly
    precacheImage(const AssetImage('assets/branding/splash_frame.png'), context);
  }

  Future<void> _startIntro() async {
    if (_introStarted) return;
    _introStarted = true;

    final controller = VideoPlayerController.asset(
      'assets/branding/splash_intro_optimized.mp4',
    );

    _videoController = controller;

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);
      await controller.setVolume(0);

      controller.addListener(_onVideoChanged);

      setState(() {});

      await controller.play();
    } catch (error) {
      debugPrint('Splash video failed: $error');

      if (identical(_videoController, controller)) {
        _videoController = null;

        if (mounted) {
          setState(() => _showLoginButton = true);
        }
      }

      await controller.dispose();
    }
  }

  void _onVideoChanged() {
    final controller = _videoController;

    if (controller == null || !controller.value.isCompleted) {
      return;
    }

    // Stop listening, but keep the controller alive.
    // VideoPlayer will continue displaying its final frame.
    controller.removeListener(_onVideoChanged);

    unawaited(controller.pause());

    if (mounted) {
      setState(() => _showLoginButton = true);
    }
  }

  Widget _buildBackground() {
    final controller = _videoController;

    if (controller != null && controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    // Render first frame of the splash immediately while video is decoding
    return Image.asset(
      'assets/branding/splash_frame.png',
      fit: BoxFit.cover,
      gaplessPlayback: true,
      width: double.infinity,
      height: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        _startIntro();
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isAuthenticating =
        authState.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: const Color(0xFFB7D4F2), // Matches splash sky background
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _buildBackground(),
            ),

            // Subtle dark overlay fades in smoothly when the login button appears
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showLoginButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const ColoredBox(
                  color: Color(0x33000000),
                ),
              ),
            ),

            Center(
              child: IgnorePointer(
                ignoring: !_showLoginButton,
                child: AnimatedOpacity(
                  opacity: _showLoginButton ? 1 : 0,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    width: 250,
                    child: GoogleSignInButton(
                      text: 'Log in with Google',
                      isLoading: isAuthenticating,
                      onPressed: isAuthenticating
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    final controller = _videoController;

    if (controller != null) {
      controller.removeListener(_onVideoChanged);
      unawaited(controller.dispose());
    }

    super.dispose();
  }
}