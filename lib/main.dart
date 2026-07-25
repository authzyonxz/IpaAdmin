import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Proxy Advanced',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: const Color(0xFF9C27B0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9C27B0),
          secondary: Color(0xFF7B1FA2),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const AdminPage(),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedTabIndex = 0;
  final String apiUrl = 'http://179.198.97.250:5000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAINEL ADMINISTRATIVO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A0033),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          StatsTab(apiUrl: apiUrl),
          KeysTab(apiUrl: apiUrl),
          ManagementTab(apiUrl: apiUrl),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          backgroundColor: const Color(0xFF0F0F0F),
          selectedItemColor: const Color(0xFF9C27B0),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'STATS'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'GERAR'),
            BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'GERIR'),
          ],
        ),
      ),
    );
  }
}

class StatsTab extends StatefulWidget {
  final String apiUrl;
  const StatsTab({Key? key, required this.apiUrl}) : super(key: key);
  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  Future<Map<String, dynamic>> _fetchStats() async {
    final response = await http.get(Uri.parse('${widget.apiUrl}/admin/stats'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Falha ao carregar stats');
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitFadingCube(color: Color(0xFF9C27B0), size: 40));
          }
          if (snapshot.hasError) return const Center(child: Text('Erro ao conectar na VPS'));
          
          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatCard('TOTAL DE CHAVES', stats['total_keys'].toString(), Icons.vpn_key, Colors.blue),
              _buildStatCard('CHAVES ATIVAS', stats['active_keys'].toString(), Icons.check_circle, Colors.green),
              _buildStatCard('CHAVES EXPIRADAS', stats['expired_keys'].toString(), Icons.history, Colors.red),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          Icon(icon, color: color, size: 40),
        ],
      ),
    );
  }
}

class KeysTab extends StatefulWidget {
  final String apiUrl;
  const KeysTab({Key? key, required this.apiUrl}) : super(key: key);
  @override
  State<KeysTab> createState() => _KeysTabState();
}

class _KeysTabState extends State<KeysTab> {
  int _selectedDuration = 30;
  final _quantityController = TextEditingController(text: '1');
  bool _isGenerating = false;

  void _showKeysModal(List<dynamic> keys) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Text('CHAVES GERADAS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: keys.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: SelectableText(keys[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final allKeys = keys.join('\n');
                      Clipboard.setData(ClipboardData(text: allKeys));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas as chaves copiadas!')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
                    child: const Text('COPIAR TODAS'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('FECHAR')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _generateKeys() async {
    if (_quantityController.text.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      // Garantir que duration e quantity sejam enviados como inteiros
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/admin/key/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'days': _selectedDuration, // Alterado de 'duration' para 'days' conforme padrão comum de backend
          'count': int.parse(_quantityController.text) // Alterado de 'quantity' para 'count'
        }),
      );
      
      // Se falhar, tentar com os nomes de campos anteriores
      if (response.statusCode != 200) {
        final retryResponse = await http.post(
          Uri.parse('${widget.apiUrl}/admin/key/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'duration': _selectedDuration,
            'quantity': int.parse(_quantityController.text)
          }),
        );
        
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          _showKeysModal(data['keys']);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ${retryResponse.statusCode}: Verifique o Backend')));
      } else {
        final data = jsonDecode(response.body);
        _showKeysModal(data['keys']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de conexão com o servidor')));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GERADOR DE LICENÇAS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          const Text('DURAÇÃO DO ACESSO', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedDuration,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E1E1E),
                items: [1, 7, 30].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value DIAS', style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedDuration = val!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('QUANTIDADE DE CHAVES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.numbers, color: Color(0xFF9C27B0)),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 40),
          _isGenerating
              ? const Center(child: SpinKitThreeBounce(color: Color(0xFF9C27B0), size: 30))
              : ElevatedButton(
                  onPressed: _generateKeys,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('GERAR AGORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                ),
        ],
      ),
    );
  }
}

class ManagementTab extends StatefulWidget {
  final String apiUrl;
  const ManagementTab({Key? key, required this.apiUrl}) : super(key: key);
  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  Future<List<dynamic>> _fetchKeys() async {
    final response = await http.get(Uri.parse('${widget.apiUrl}/admin/keys'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<void> _updateStatus(String key, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiUrl}/admin/key/$key/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status atualizado para $status!')));
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao atualizar status')));
    }
  }

  Future<void> _resetUdid(String key) async {
    try {
      final response = await http.post(Uri.parse('${widget.apiUrl}/admin/key/$key/reset_udid'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UDID resetado com sucesso!')));
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao resetar UDID')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<dynamic>>(
        future: _fetchKeys(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SpinKitPulse(color: Color(0xFF9C27B0)));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma chave encontrada ou erro no servidor'));
          }
          
          final keys = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final k = keys[index];
              final bool isPaused = k['status'] == 'paused';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), 
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: k['status'] == 'active' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                ),
                child: ExpansionTile(
                  leading: Icon(Icons.vpn_key, color: k['status'] == 'active' ? Colors.green : (isPaused ? Colors.orange : Colors.red)),
                  title: Text(k['key'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('UDID: ${k['udid'] ?? "Livre"} | Status: ${k['status'].toString().toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _actionBtn(Icons.refresh, 'RESET', () => _resetUdid(k['key']), Colors.blue),
                          // Botão dinâmico: Se pausado mostra PLAY, se ativo mostra PAUSE
                          _actionBtn(
                            isPaused ? Icons.play_arrow : Icons.pause, 
                            isPaused ? 'DESPAUSAR' : 'PAUSAR', 
                            () => _updateStatus(k['key'], isPaused ? 'active' : 'paused'), 
                            isPaused ? Colors.green : Colors.orange
                          ),
                          _actionBtn(Icons.block, 'BAN', () => _updateStatus(k['key'], 'banned'), Colors.red),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback press, Color color) {
    return InkWell(
      onTap: press,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
