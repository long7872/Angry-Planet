import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:io';
import 'package:flame/game.dart';
import '../../../bootstrap/local_server_runner.dart';
import '../../network/ws_client.dart';
import '../../game.dart';

class LobbySetupScreen extends StatefulWidget {
  const LobbySetupScreen({Key? key}) : super(key: key);

  @override
  State<LobbySetupScreen> createState() => _LobbySetupScreenState();
}

class _LobbySetupScreenState extends State<LobbySetupScreen> {
  late TextEditingController _nameController;  // ✓ NEW
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _seedController;
  bool _isLoading = true;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    
    // ✓ NEW: Generate random player name
    final randomNumber = Random().nextInt(9999);
    _nameController = TextEditingController(text: 'Player_$randomNumber');
    
    // IP controller
    _ipController = TextEditingController(text: 'Loading...');
    
    // Generate random port between 8000-9000
    final randomPort = 8000 + Random().nextInt(1000);
    _portController = TextEditingController(text: randomPort.toString());
    
    // Generate random seed
    final randomSeed = Random().nextInt(999999);
    _seedController = TextEditingController(text: randomSeed.toString());
    
    // Get IP address
    _getIPAddress();
  }

  Future<void> _getIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      
      String? bestIP;
      int bestPriority = -1;
      
      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        
        // Skip virtual adapters
        final isVirtual = name.contains('wsl') ||
            name.contains('hyper') ||
            name.contains('vethernet') ||
            name.contains('virtualbox') ||
            name.contains('vmware') ||
            name.contains('docker') ||
            name.contains('vbox') ||
            (name.contains('virtual') && name.contains('adapter'));
        
        if (isVirtual) {
          print('⏭️  Skipping: ${interface.name}');
          continue;
        }
        
        for (var addr in interface.addresses) {
          if (addr.type != InternetAddressType.IPv4) continue;
          if (addr.isLoopback) continue;
          
          final ip = addr.address;
          
          // Skip link-local
          if (ip.startsWith('169.254.')) continue;
          
          // Calculate priority
          int priority = 0;
          
          // Check interface type
          if (name.contains('wi-fi') || name.contains('wlan') || name.contains('wireless')) {
            priority = 100;
          } else if (name.contains('ethernet') || name.contains('eth')) {
            if (name.contains('veth') || name.contains('virtual')) continue;
            priority = 90;
          } else {
            priority = 50;
          }
          
          // Prefer common home/office networks
          if (ip.startsWith('192.168.')) {
            priority += 15;
          } else if (ip.startsWith('10.')) {
            priority += 10;
          } else if (ip.startsWith('172.')) {
            final secondOctet = int.tryParse(ip.split('.')[1]) ?? 0;
            if (secondOctet >= 16 && secondOctet <= 31) {
              priority += 10;
            }
          }
          
          print('🔍 ${interface.name}: $ip (priority: $priority)');
          
          if (priority > bestPriority) {
            bestPriority = priority;
            bestIP = ip;
          }
        }
      }
      
      setState(() {
        _ipController.text = bestIP ?? '127.0.0.1';
        _isLoading = false;
      });
      
      print('✅ Selected: ${_ipController.text}');
    } catch (e) {
      setState(() {
        _ipController.text = '127.0.0.1';
        _isLoading = false;
      });
      print('❌ Error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();  // ✓ NEW
    _ipController.dispose();
    _portController.dispose();
    _seedController.dispose();
    super.dispose();
  }

  Future<void> _startGame() async {
    if (_isStarting) return;
    
    setState(() {
      _isStarting = true;
    });

    try {
      final playerName = _nameController.text.trim();  // ✓ NEW
      final ip = _ipController.text.trim();
      final port = int.tryParse(_portController.text) ?? 3333;
      final seed = int.tryParse(_seedController.text) ?? 0;
      
      // ✓ Validate player name
      if (playerName.isEmpty) {
        throw Exception('Player name cannot be empty');
      }
      
      if (playerName.length > 20) {
        throw Exception('Player name too long (max 20 characters)');
      }
      
      // Validate IP address
      if (ip.isEmpty || !_isValidIP(ip)) {
        throw Exception('Invalid IP address');
      }
      
      print("🚀 Starting server on port $port with seed $seed...");
      print("👤 Player name: $playerName");
      
      // Start local server with port
      await startLocalServer(port, seed);
      await Future.delayed(Duration(seconds: 1));

      print("🔌 Connecting to $ip:$port...");
      final socket = ClientSocket("ws://$ip:$port/ws");
      await socket.connect();
      print("✅ Connected!");

      // Navigate to game
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: GameWidget(
              game: AngryPlanetGame(socket, playerName: playerName),  // ✓ Pass name
            ),
          ),
        ),
      );
    } catch (e) {
      print("❌ Error starting game: $e");
      
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTitle(),
                          SizedBox(height: 40),
                          _buildNameRow(),  // ✓ NEW
                          SizedBox(height: 20),
                          _buildIPRow(),
                          SizedBox(height: 20),
                          _buildPortRow(),
                          SizedBox(height: 20),
                          _buildSeedRow(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Start Button
              _buildStartButton(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _isStarting ? null : () => Navigator.pop(context),
          ),
          Text(
            'Lobby Setup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Server Configuration',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  // ✓ NEW: Player Name Row
  Widget _buildNameRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.purple, size: 24),
              SizedBox(width: 10),
              Text(
                'Player Name',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.purple),
                onPressed: _isStarting ? null : () {
                  setState(() {
                    final randomNumber = Random().nextInt(9999);
                    _nameController.text = 'Player_$randomNumber';
                  });
                },
                tooltip: 'Generate new name',
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _nameController,
            enabled: !_isStarting,
            maxLength: 20,
            inputFormatters: [
              // Allow letters, numbers, underscore, hyphen
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
            ],
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.edit, color: Colors.purple),
              hintText: 'Player_1234',
              hintStyle: TextStyle(color: Colors.white38),
              counterText: '',  // Hide character counter
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your display name in the game (editable)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIPRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.computer, color: Colors.blue, size: 24),
              SizedBox(width: 10),
              Text(
                'IP Address',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.blue),
                onPressed: _isStarting ? null : () {
                  setState(() {
                    _isLoading = true;
                    _ipController.text = 'Loading...';
                  });
                  _getIPAddress();
                },
                tooltip: 'Auto-detect IP',
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _ipController,
            enabled: !_isStarting && !_isLoading,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.edit, color: Colors.blue),
              hintText: '192.168.1.11',
              hintStyle: TextStyle(color: Colors.white38),
              suffixIcon: IconButton(
                icon: Icon(Icons.copy, color: Colors.white70),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _ipController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('IP Address copied!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your device or host IP address (editable)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_ethernet, color: Colors.orange, size: 24),
              SizedBox(width: 10),
              Text(
                'Server Port',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _portController,
            enabled: !_isStarting,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.edit, color: Colors.orange),
              hintText: '3333',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Port number for multiplayer server (editable)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeedRow() {
    return Container(
      constraints: BoxConstraints(maxWidth: 500),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text(
                'World Seed',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.green),
                onPressed: _isStarting ? null : () {
                  setState(() {
                    final newSeed = Random().nextInt(999999);
                    _seedController.text = newSeed.toString();
                  });
                },
                tooltip: 'Generate new seed',
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: _seedController,
            enabled: !_isStarting,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black12,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.edit, color: Colors.green),
              hintText: '123456',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Seed for procedural world generation (editable)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isStarting ? null : _startGame,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxWidth: 500),
            height: 70,
            decoration: BoxDecoration(
              gradient: _isStarting
                  ? LinearGradient(colors: [Colors.grey, Colors.grey.shade600])
                  : LinearGradient(colors: [Colors.green, Colors.greenAccent]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: (_isStarting ? Colors.grey : Colors.green).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 3,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isStarting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 15),
                        Text(
                          'STARTING...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Text(
                          'START GAME',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
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