import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../widgets/rgv_logo.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startInCreateAccount = false});

  final bool startInCreateAccount;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool isLogin;
  String? error;

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final ageController = TextEditingController();
  final gradeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isLogin = !widget.startInCreateAccount;
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    ageController.dispose();
    gradeController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final state = context.read<AppState>();

    setState(() => error = null);

    if (isLogin) {
      final message = state.signIn(
        username: usernameController.text,
        password: passwordController.text,
      );
      if (message != null) {
        setState(() => error = message);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    final parsedAge = int.tryParse(ageController.text.trim());
    if (parsedAge == null || parsedAge <= 0) {
      setState(() => error = 'Enter a valid age.');
      return;
    }

    final message = state.signUp(
      name: nameController.text,
      username: usernameController.text,
      password: passwordController.text,
      age: parsedAge,
      gradeLevel: gradeController.text,
    );
    if (message != null) {
      setState(() => error = message);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.14),
                colorScheme.secondary.withOpacity(0.10),
                colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const RgvTutorLogo(size: 46),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'RGV Tutor',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Learn offline—Math, Reading, Science, and History.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      color: colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ModeToggle(
                              isLogin: isLogin,
                              onChanged: (next) => setState(() {
                                isLogin = next;
                                error = null;
                              }),
                            ),
                            const SizedBox(height: 18),
                            if (!isLogin) ...[
                              TextField(
                                controller: nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                              onSubmitted: (_) => isLogin ? submit() : null,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                            ),
                            if (!isLogin) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: ageController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                  prefixIcon: Icon(Icons.cake_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: gradeController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => submit(),
                                decoration: const InputDecoration(
                                  labelText: 'Grade level',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                              ),
                            ],
                            if (error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  error!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => submit(),
                                child: Text(isLogin ? 'Sign in' : 'Create account'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonal(
                                onPressed: () {
                                  context.read<AppState>().signInAsGuest();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                },
                                child: const Text('Continue as guest'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Note: accounts are stored locally on this device.',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Sign in',
              selected: isLogin,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Create account',
              selected: !isLogin,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
