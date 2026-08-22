import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caso_hipotetico_model.dart';
import '../providers/game_provider.dart';
import '../services/casos_service.dart';
import '../data/venezuela_regions.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> with SingleTickerProviderStateMixin {
  late CasoHipotetico _currentCaso;
  int? _selectedOption;
  bool _showingResult = false;
  bool _isCorrect = false;
  int _attempts = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _bgPrincipal = Color(0xFF0A0E1A);
  static const Color _bgSecundario = Color(0xFF1A1F2E);
  static const Color _bgCard = Color(0xFF0F1623);
  static const Color _borderColor = Color(0xFF2A3142);
  static const Color _dorado = Color(0xFFD4AF37);
  static const Color _success = Color(0xFF22C55E);
  static const Color _error = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _info = Color(0xFFF97316);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _loadQuestion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadQuestion() {
    final gameState = Provider.of<GameState>(context, listen: false);
    setState(() {
      _currentCaso = CasosService.getCasoParaNivel(gameState.currentLevel);
      _selectedOption = null;
      _showingResult = false;
      _isCorrect = false;
      _attempts = 0;
    });
  }

  void _verifyAnswer() {
    if (_selectedOption == null) return;

    setState(() {
      _attempts++;
      _isCorrect = _selectedOption == _currentCaso.respuestaCorrecta;
      _showingResult = true;
    });

    _animationController.forward(from: 0.0);

    if (_isCorrect) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          final gameState = Provider.of<GameState>(context, listen: false);
          gameState.completeLevel();
          _loadNextQuestion();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Nivel ${Provider.of<GameState>(context).currentLevel}'),
        backgroundColor: const Color(0xFF003893),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentGame != null
                ? GameWidget(game: _currentGame!)
                : const Center(child: CircularProgressIndicator()),
          ),
          if (!_showingResult)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  _currentGame?.verifyAnswer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'VERIFICAR RESPUESTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (_showingResult && _resultado != null)
            _buildResultPanel(_resultado!),
        ],
      ),
    );
  }

  Widget _buildResultPanel(ResultadoRespuesta resultado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: resultado.correcto
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : const Color(0xFFF44336).withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: resultado.correcto
                ? const Color(0xFF4CAF50)
                : const Color(0xFFF44336),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                resultado.correcto ? Icons.check_circle : Icons.error,
                color: resultado.correcto
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  resultado.mensaje ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: resultado.correcto
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (resultado.correcto && resultado.fundamentacion != null)
            _buildFundamentacion(resultado.fundamentacion!),
          if (!resultado.correcto && resultado.pista != null)
            _buildPista(resultado.pista!),
        ],
      ),
    );
  }

  Widget _buildFundamentacion(Fundamentacion fundamentacion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚖️ Fundamentación Legal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF003893),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          fundamentacion.explicacion,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 12),
        ...fundamentacion.articulos.map((art) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• ${art.articulo}: ${art.texto}',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPista(Pista pista) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💡 Pista',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF57C00),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pista.textoPista,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        if (pista.busquedaSugerida != null) ...[
          const SizedBox(height: 8),
          Text(
            pista.busquedaSugerida!,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}

  Widget _buildBloqueadoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: _warning, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'CASO BLOQUEADO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Has agotado los 3 intentos permitidos',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
          const Divider(color: _borderColor, height: 32),
          const Text(
            '⚠️  OPCIONES DISPONIBLES:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionInfo(
            icon: Icons.description,
            title: '1. 📜 USAR APELACIÓN',
            subtitle: 'Desbloquea este caso inmediatamente\nSe regenera 1 cada 30 minutos',
          ),
          const SizedBox(height: 12),
          _buildOptionInfo(
            icon: Icons.schedule,
            title: '2. ⏰ ESPERAR 24 HORAS',
            subtitle: 'El caso se desbloqueará automáticamente\nPuedes avanzar otros niveles mientras',
          ),
          const SizedBox(height: 12),
          _buildOptionInfo(
            icon: Icons.book,
            title: '3. 📚 ESTUDIAR EN REPOSITORIO',
            subtitle: 'Revisa jurisprudencias relacionadas',
          ),
        ],
      ),
    );
  }

  Widget _buildOptionInfo({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgSecundario,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _dorado, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: _success,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_forward, size: 20),
          SizedBox(width: 8),
          Text(
            'CONTINUAR AL SIGUIENTE NIVEL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton(
      onPressed: _retry,
      style: ElevatedButton.styleFrom(
        backgroundColor: _info,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: 20),
          SizedBox(width: 8),
          Text(
            'INTENTAR DE NUEVO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApelacionButtons() {
    final gameState = Provider.of<GameState>(context, listen: false);
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: gameState.apelacionesDisponibles > 0 ? _useApelacion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _dorado,
            foregroundColor: _bgPrincipal,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description, size: 20),
              const SizedBox(width: 8),
              Text(
                'USAR 1 APELACIÓN (${gameState.apelacionesDisponibles} disponibles)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            // TODO: Navegar al repositorio de jurisprudencia
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _dorado,
            side: const BorderSide(color: _dorado, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_books, size: 20),
              SizedBox(width: 8),
              Text(
                'IR AL REPOSITORIO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text(
                'VOLVER AL LOBBY',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
