import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Add Firebase platform configuration with FlutterFire CLI before running.
  await Firebase.initializeApp();
  runApp(const AbdullahAIStudio());
}

class AbdullahAIStudio extends StatelessWidget {
  const AbdullahAIStudio({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abdullah AI Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0D14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      message(e.message ?? 'Login failed');
    } catch (_) {
      message('Please check your Firebase setup and try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> googleLogin() async {
    setState(() => busy = true);
    try {
      final account = await GoogleSignIn().signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      message(e.message ?? 'Google sign-in failed');
    } catch (_) {
      message('Google Sign-in needs Firebase and OAuth configuration.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      heading: 'Welcome back',
      subtitle: 'Sign in to create amazing AI photos and videos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(controller: email, label: 'Email address', icon: Icons.email_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              ),
              filled: true, fillColor: const Color(0xFF151925),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetScreen())),
              child: const Text('Forgot password?'),
            ),
          ),
          FilledButton(
            onPressed: busy ? null : login,
            style: primaryButton,
            child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: busy ? null : googleLogin,
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: const Text('Sign up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    name.dispose(); email.dispose(); password.dispose(); super.dispose();
  }

  Future<void> signup() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    setState(() => busy = true);
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(), password: password.text,
      );
      await result.user?.updateDisplayName(name.text.trim());
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please check Firebase setup.')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    heading: 'Create account',
    subtitle: 'Join Abdullah AI Studio for AI creativity.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthField(controller: name, label: 'Your name', icon: Icons.person_outline),
        const SizedBox(height: 12),
        AuthField(controller: email, label: 'Email address', icon: Icons.email_outlined),
        const SizedBox(height: 12),
        AuthField(controller: password, label: 'Password (6+ characters)', icon: Icons.lock_outline, isPassword: true),
        const SizedBox(height: 20),
        FilledButton(onPressed: busy ? null : signup, style: primaryButton,
          child: busy ? const CircularProgressIndicator() : const Text('Create account')),
        const SizedBox(height: 12),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Login')),
      ],
    ),
  );
}

class ResetScreen extends StatefulWidget {
  const ResetScreen({super.key});
  @override
  State<ResetScreen> createState() => _ResetScreenState();
}

class _ResetScreenState extends State<ResetScreen> {
  final email = TextEditingController();
  bool busy = false;
  @override
  void dispose() { email.dispose(); super.dispose(); }

  Future<void> reset() async {
    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent. Check your inbox.')));
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Could not send reset email')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    heading: 'Reset password',
    subtitle: 'Enter your email and we will send a reset link.',
    child: Column(children: [
      AuthField(controller: email, label: 'Email address', icon: Icons.email_outlined),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: busy ? null : reset, style: primaryButton,
        child: busy ? const CircularProgressIndicator() : const Text('Send reset link'),
      )),
    ]),
  );
}

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  const AuthField({super.key, required this.controller, required this.label, required this.icon, this.isPassword = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: isPassword,
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon),
      filled: true, fillColor: const Color(0xFF151925),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    ),
  );
}

class AuthScaffold extends StatelessWidget {
  final String heading;
  final String subtitle;
  final Widget child;
  const AuthScaffold({super.key, required this.heading, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.auto_awesome, size: 54, color: Color(0xFFC4A7FF)),
                const SizedBox(height: 12),
                const Text('Abdullah AI Studio', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 34),
                Text(heading, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 26),
                child,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final primaryButton = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(54),
  backgroundColor: const Color(0xFF8055E8),
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: Color(0xFFC4A7FF)),
          SizedBox(width: 9),
          Text('Abdullah AI Studio', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome${user?.displayName == null ? '' : ', ${user!.displayName}'}!',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Your AI creative studio is ready for the next setup step.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          _FeatureCard(icon: Icons.image_outlined, title: 'AI Photo Generator', description: 'Turn a text prompt into an image.'),
          const SizedBox(height: 12),
          _FeatureCard(icon: Icons.movie_creation_outlined, title: 'AI Video Generator', description: 'Create video from a prompt or photo.'),
          const SizedBox(height: 12),
          _FeatureCard(icon: Icons.collections_outlined, title: 'My Creations', description: 'Your generated media will appear here.'),
          const SizedBox(height: 24),
          const Text('AI generation will be enabled after connecting a secure generation backend.',
            style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureCard({required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF151925),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white10),
    ),
    child: Row(children: [
      Icon(icon, size: 32, color: const Color(0xFFC4A7FF)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(color: Colors.white60)),
      ])),
      const Icon(Icons.chevron_right, color: Colors.white54),
    ]),
  );
}
