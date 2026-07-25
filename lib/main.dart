import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nitro Proxy Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        title: const Text('Nitro Proxy Admin'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          StatsTab(apiUrl: apiUrl),
          UdidsTab(apiUrl: apiUrl),
          KeysTab(apiUrl: apiUrl),
          ManagementTab(apiUrl: apiUrl),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.phone_iphone), label: 'UDIDs'),
          BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: 'Chaves'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Gerência'),
        ],
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
  late Future<Map<String, dynamic>> _statsFuture;
  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }
  Future<Map<String, dynamic>> _fetchStats() async {
    final response = await http.get(Uri.parse('${widget.apiUrl}/admin/stats'));
    return jsonDecode(response.body);
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final stats = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard('Total de Chaves', stats['total_keys']),
            _buildStatCard('Chaves Ativas', stats['active_keys']),
            _buildStatCard('Chaves Pendentes', stats['pending_keys']),
            _buildStatCard('Total de UDIDs', stats['total_udids']),
          ],
        );
      },
    );
  }
  Widget _buildStatCard(String label, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class UdidsTab extends StatelessWidget {
  final String apiUrl;
  const UdidsTab({Key? key, required this.apiUrl}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: http.get(Uri.parse('$apiUrl/admin/udids')).then((r) => jsonDecode(r.body)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final udids = snapshot.data!;
        return ListView.builder(
          itemCount: udids.length,
          itemBuilder: (context, index) => Card(
            child: ListTile(
              title: Text('UDID: ${udids[index]['udid']}'),
              subtitle: Text('Chave: ${udids[index]['key']}'),
            ),
          ),
        );
      },
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
  final _durationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Duração (dias)')),
              TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantidade')),
              ElevatedButton(onPressed: () async {
                await http.post(Uri.parse('${widget.apiUrl}/admin/key/create'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'duration_days': int.parse(_durationController.text), 'quantity': int.parse(_quantityController.text)}));
                setState(() {});
              }, child: const Text('GERAR CHAVES')),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: http.get(Uri.parse('${widget.apiUrl}/admin/keys')).then((r) => jsonDecode(r.body)),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final keys = snapshot.data!;
              return ListView.builder(
                itemCount: keys.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(keys[index]['key']),
                  subtitle: Text('Status: ${keys[index]['status']}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ManagementTab extends StatelessWidget {
  final String apiUrl;
  const ManagementTab({Key? key, required this.apiUrl}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Gerenciamento de Keys Avançado'));
  }
}
