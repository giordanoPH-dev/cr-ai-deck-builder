import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/ai_datasource.dart';
import 'search_screen.dart';

class ApiKeyScreen extends StatefulWidget {
  /// When true, hides the back button and navigates forward to SearchScreen
  /// after saving. Used when the key is required before accessing the app.
  final bool mustConfigure;

  const ApiKeyScreen({super.key, this.mustConfigure = false});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _saved = false;
  String? _currentKey;

  @override
  void initState() {
    super.initState();
    _loadCurrentKey();
  }

  Future<void> _loadCurrentKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(AppConstants.userGeminiApiKeyKey);
    if (key != null && key.isNotEmpty && mounted) {
      setState(() {
        _currentKey = key;
        _controller.text = key;
      });
    }
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userGeminiApiKeyKey, key);
    GetIt.instance<AiDatasource>().updateApiKey(key);

    setState(() {
      _currentKey = key;
      _saved = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    if (widget.mustConfigure) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _removeKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userGeminiApiKeyKey);
    setState(() {
      _currentKey = null;
      _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Back button — hidden when key is required
              if (!widget.mustConfigure)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),

              // Header icon
              const Icon(Icons.key_rounded, color: Colors.amber, size: 56),
              const SizedBox(height: 16),

              Text(
                widget.mustConfigure ? 'CHAVE GEMINI NECESSÁRIA' : 'SUA CHAVE GEMINI AI',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.mustConfigure
                    ? 'Para usar o app, insira sua chave gratuita do Gemini AI.'
                    : 'Use sua própria chave e nunca fique sem análises.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              // Status badge
              if (_currentKey != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Chave pessoal ativa',
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // How-to steps
              Card(
                color: Colors.white.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMO OBTER SUA CHAVE',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStep(1, 'Acesse', 'aistudio.google.com/apikey'),
                      _buildStep(2, 'Faça login com sua conta Google', null),
                      _buildStep(3, 'Clique em', '"Create API Key"'),
                      _buildStep(4, 'Selecione um projeto Google Cloud ou crie um novo', null),
                      _buildStep(5, 'Copie a chave gerada (começa com', '"AIza..."'),
                      _buildStep(6, 'Cole abaixo e toque em Salvar', null),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'O plano gratuito inclui 1.500 requests/dia. Mais que suficiente para uso pessoal.',
                                style: TextStyle(color: Colors.amber, fontSize: 11, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Input
              Card(
                color: Colors.white.withValues(alpha: 0.1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        obscureText: _obscure,
                        style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 0.5),
                        decoration: InputDecoration(
                          labelText: 'Cole sua API Key aqui',
                          labelStyle: const TextStyle(color: Colors.amber),
                          hintText: 'AIzaSy...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: Colors.amber),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, color: Colors.white38, size: 20),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              IconButton(
                                icon: const Icon(Icons.content_paste, color: Colors.white38, size: 20),
                                onPressed: () async {
                                  final data = await Clipboard.getData('text/plain');
                                  if (data?.text != null) {
                                    _controller.text = data!.text!.trim();
                                  }
                                },
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.amber),
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saved ? null : _saveKey,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(_saved ? Icons.check : Icons.save_rounded, size: 20),
                        label: Text(
                          _saved ? 'SALVO!' : 'SALVAR CHAVE',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      if (_currentKey != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _removeKey,
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text('Remover chave pessoal', style: TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int n, String text, String? highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.amber,
            child: Text(
              '$n',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                children: [
                  TextSpan(text: text),
                  if (highlight != null && highlight.isNotEmpty) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: highlight,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
