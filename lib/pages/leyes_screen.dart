import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LeyesScreen extends StatefulWidget {
  const LeyesScreen({super.key, this.selectedLawIndex});
  final int? selectedLawIndex;

  @override
  State<LeyesScreen> createState() => _LeyesScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('selectedLawIndex', selectedLawIndex));
  }
}

class _LeyesScreenState extends State<LeyesScreen> {
  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color tarjetaFondo = Color(0xFF111827);

  final List<Map<String, String>> _leyes = const <Map<String, String>>[
    <String, String>{
      'titulo': 'Constitución de la República Bolivariana de Venezuela',
      'descripcion': 'Marco constitucional de derechos, garantías y estructura del Estado venezolano.',
      'detalle': 'La Constitución es norma suprema y establece los derechos humanos, el debido proceso y la organización del Estado.',
    },
    <String, String>{
      'titulo': 'Código Penal Venezolano',
      'descripcion': 'Normas penales básicas que tipifican delitos y sancionan conductas criminales.',
      'detalle': 'Regula las penas, circunstancias agravantes y atenuantes, así como la aplicación de sanciones en el orden penal.',
    },
    <String, String>{
      'titulo': 'Código Orgánico Procesal Penal',
      'descripcion': 'Regula el procedimiento penal, investigación y garantías procesales.',
      'detalle': 'Establece la cadena de custodia, el juicio oral, la prueba, los recursos y la tutela judicial efectiva en materia penal.',
    },
    <String, String>{
      'titulo': 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
      'descripcion': 'Protege a las mujeres contra la violencia en el ámbito público y privado.',
      'detalle': 'Define medidas de prevención, atención y sanción para erradicar la violencia de género y garantizar la protección integral de las víctimas.',
    },
    <String, String>{
      'titulo': 'Ley Orgánica de Drogas',
      'descripcion': 'Regula el control, fiscalización y sanciones sobre estupefacientes y sustancias psicotrópicas.',
      'detalle': 'Establece tipos penales, medidas de seguridad y políticas de prevención contra el tráfico ilícito de drogas.',
    },
    <String, String>{
      'titulo': 'Ley Orgánica contra la Delincuencia Organizada y Financiamiento al Terrorismo',
      'descripcion': 'Sanciona los delitos de crimen organizado y financiamiento terrorista.',
      'detalle': 'Define los delitos, la cooperación internacional y las medidas penales especiales contra las redes criminales y el terrorismo.',
    },
    <String, String>{
      'titulo': 'Ley contra el Secuestro y la Extorsión',
      'descripcion': 'Tipifica y sanciona los delitos de secuestro, coacción y extorsión.',
      'detalle': 'Contempla penas elevadas, protección a las víctimas y medidas para combatir la violencia económica y la coerción ilícita.',
    },
    <String, String>{
      'titulo': 'Ley sobre el Hurto y Robo de Vehículos Automotores',
      'descripcion': 'Regula los delitos contra vehículos automotores y las penas correspondientes.',
      'detalle': 'Describe el hurto, el robo, el desvalijamiento y las circunstancias agravantes relacionadas con vehículos automotores.',
    },
    <String, String>{
      'titulo': 'Ley para el Desarme y Control de Armas y Municiones',
      'descripcion': 'Regula la tenencia, porte y control de armas de fuego y municiones.',
      'detalle': 'Establece operaciones de desarme, registro de armas y sanciones para el uso indebido de armas y municiones.',
    },
  ];

  bool _detailShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_detailShown && widget.selectedLawIndex != null) {
      final int index = widget.selectedLawIndex!;
      if (index >= 0 && index < _leyes.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mostrarDetalle(context, _leyes[index]);
        });
      }
      _detailShown = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("Biblioteca Legal"),
        backgroundColor: azulMarino,
      ),
      backgroundColor: azulMarino,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: _leyes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 120,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, String> ley = _leyes[index];
                  return GestureDetector(
                    onTap: () => _mostrarDetalle(context, ley),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: tarjetaFondo,
                        border: Border.all(color: dorado.withValues(alpha: 0.25)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            ley["titulo"]!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ley["descripcion"]!,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
                          ),
                          const Spacer(),
                          const Row(
                            children: <Widget>[
                              Icon(Icons.arrow_forward_rounded, color: dorado, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "VER FICHA",
                                style: TextStyle(
                                  color: dorado,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

  void _mostrarDetalle(BuildContext context, Map<String, String> ley) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
          backgroundColor: azulMarino,
          title: Text(ley["titulo"]!, style: const TextStyle(color: dorado)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ley["descripcion"]!,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 14),
              Text(
                ley["detalle"]!,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar", style: TextStyle(color: dorado)),
            ),
          ],
        ),
    );
  }
}