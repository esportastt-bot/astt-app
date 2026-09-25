import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez remplir tous les champs.";
        _isLoading = false;
      });
      return;
    }

    try {
      if (_isLogin) {
        final error = await appState.login(email, password);
        if (error != null) {
          setState(() => _errorMessage = error);
        } else {
          if (mounted) Navigator.pop(context);
        }
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        // Create user document in firestore
        await appState.createUserProfile(email);
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez entrer votre e-mail pour réinitialiser le mot de passe.";
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail de réinitialisation envoyé.')));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Connexion' : 'Créer un compte', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLogin ? 'Bon retour !' : 'Rejoignez-nous !',
                style: GoogleFonts.chakraPetch(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Utilisez la même adresse email que sur HelloAsso pour recevoir vos codes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(_isLogin ? 'SE CONNECTER' : 'S\'INSCRIRE', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = null;
                  });
                },
                child: Text(_isLogin ? 'Pas encore de compte ? S\'inscrire' : 'Déjà un compte ? Se connecter', style: const TextStyle(color: Color(0xFF00D4FF))),
              ),
              if (_isLogin)
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Mot de passe oublié ?', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

