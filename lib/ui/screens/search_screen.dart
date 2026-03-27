import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/player_viewmodel.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _tagController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedTag();
    _focusNode.addListener(() {
      print('[LOG] Campo de texto mudou de foco: ${_focusNode.hasFocus}');
    });
  }

  Future<void> _loadSavedTag() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTag = prefs.getString('saved_player_tag');
    if (savedTag != null && savedTag.isNotEmpty) {
      if (mounted) {
        setState(() {
          _tagController.text = savedTag;
        });
        // Aciona a busca automática logo ao abrir o app e carregar a tag!
        _searchPlayer();
      }
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchPlayer() async {
    print('[LOG] Iniciando busca...');
    final tag = _tagController.text.trim().toUpperCase();
    if (tag.isEmpty) return;
    
    // Esconder o teclado
    FocusScope.of(context).unfocus();

    // Salvar tag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_player_tag', tag);
    
    final viewModel = context.read<PlayerViewModel>();
    await viewModel.fetchPlayerProfile(tag);
    
    if (viewModel.playerProfile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CR AI Deck Builder'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.search_rounded, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 24),
                  const Text(
                    'Encontre seu perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Insira sua Player Tag do Clash Royale para analisar seu deck.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _tagController,
                    focusNode: _focusNode,
                    onTap: () => print('[LOG] TextField foi clicado!'),
                    decoration: InputDecoration(
                      labelText: 'Player Tag (ex: L8P22UR2)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.tag),
                      filled: true,
                    ),
                    onSubmitted: (_) {
                      print('[LOG] Teclado confirmou submissão.');
                      _searchPlayer();
                    },
                  ),
                  const SizedBox(height: 24),
                  Consumer<PlayerViewModel>(
                    builder: (context, viewModel, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (viewModel.errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent),
                              ),
                              child: SelectableText(
                                viewModel.errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          FilledButton(
                            onPressed: viewModel.isLoading ? null : _searchPlayer,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: viewModel.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Buscar Jogador',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
