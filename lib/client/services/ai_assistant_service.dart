import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIAssistantService {
  static AIAssistantService? _instance;
  GenerativeModel? _model;
  bool _initialized = false;

  AIAssistantService._();

  static AIAssistantService get instance {
    _instance ??= AIAssistantService._();
    return _instance!;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
        print('⚠️ Gemini API key not configured. AI Assistant will not be available.');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_getGameContext()),
      );

      _initialized = true;
      print('✅ AI Assistant initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize AI Assistant: $e');
    }
  }

  String _getGameContext() {
    return '''
You are an AI Tutorial Assistant for "The Angry Planet" - a multiplayer 2D resource management and survival game.

GAME OVERVIEW:
- Players must survive, build factories, manage pollution, and escape the angry planet
- Built with Flutter and Flame engine
- Multiplayer with WebSocket support

MACHINES (9 types):
1. **Burner** - Burns coal/wood to generate Nuclear Energy (NE)
2. **Digger** - Mines ore from resource nodes in terrain
3. **Chopper** - Harvests wood from forest tiles
4. **Smelter** - Processes materials (ore → iron bars, catalyst → energy cubes)
5. **Holder** - Storage container for items
6. **Greener** - Reduces pollution in the environment
7. **Energy Linker** - Transfers energy between machines
8. **Item Linker** - Transfers items between machines
9. **Spaceship** - End-game machine (requires energy cubes to escape)

RESOURCES:
- **Raw**: Wood, Coal, Iron Ore, Energy Catalyst
- **Processed**: Iron Bars, Energy Cubes
- **Energy**: Nuclear Energy (NE)

KEY SYSTEMS:
1. **Energy System**: Machines need NE to operate. Connect with Energy Linkers.
2. **Pollution System**:
   - Pollution level: 0-10,000 (Clean → Critical)
   - High pollution triggers Acid Rain (damages machines)
   - Use Greener machines to reduce pollution
3. **Crafting Chain**: Raw resources → Processing → Advanced items
4. **Multiplayer**: Real-time sync, chat, cooperative building

GAME GOAL:
Build energy cubes and power the Spaceship to escape the angry planet!

TIPS FOR PLAYERS:
- Start with Burner (energy) + Digger/Chopper (resources)
- Connect machines with Energy/Item Linkers
- Watch pollution levels - use Greeners
- Cooperate with other players in multiplayer

Your role: Answer questions clearly, give helpful tips, explain mechanics, and guide new players.
Be friendly, concise, and encouraging. Use emojis occasionally to be engaging.
''';
  }

  Future<String> askAI(String question) async {
    if (!_initialized || _model == null) {
      return '⚠️ AI Assistant is not available. Please configure GEMINI_API_KEY in .env file.';
    }

    try {
      final content = [Content.text(question)];
      final response = await _model!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        return '❌ Sorry, I couldn\'t generate a response. Please try again.';
      }

      return response.text!;
    } catch (e) {
      print('❌ AI Assistant error: $e');
      return '❌ Error: ${e.toString().split('\n').first}';
    }
  }

  bool get isAvailable => _initialized && _model != null;
}
