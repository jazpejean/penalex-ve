import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../config/app_tokens.dart';
import '../models/sentencia_model.dart';
import '../services/criterio_dia_service.dart';
import '../widgets/app_screen_header.dart';

/// Criterio del día, tip de alto valor y minuta de sentencias.
class CriterioDelDiaScreen extends StatefulWidget {
  const CriterioDelDiaScreen({super.key});

  @override
  State<CriterioDelDiaScreen> createState() => _CriterioDelDiaScreenState();
}

class _CriterioDelDiaScreenState extends State<CriterioDelDiaScreen> {
  SentenciaModel? _criterio;
  List<SentenciaModel> _minuta = <SentenciaModel>[];
  bool _cargando = true;
  bool _nuevasHoy = false;
  TipDelDia _tip = CriterioDiaService.tipDelDia;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final SentenciaModel? criterio = await CriterioDiaService.criterioDelDia();
    final ({List<SentenciaModel> sentencias, bool nuevas}) minuta =
        await CriterioDiaService.minutaDelDia();
    TipDelDia tip = CriterioDiaService.tipDelDia;
    if (criterio != null) {
      final TipDelDia? automatico =
          await CriterioDiaService.tipDesdeSentencia(criterio);
      if (automatico != null) tip = automatico;
    }
    if (!mounted) return;
    setState(() {
      _criterio = criterio;
      _minuta = minuta.sentencias;
      _nuevasHoy = minuta.nuevas;
      _tip = tip;
      _cargando = false;
    });
  }

  Future<void> _compartir(String texto) async {
    await Share.share(texto, subject: 'Penalex VE');
  }

  Future<void> _abrirSentencia(SentenciaModel s) async {
    final String url = s.urlHTML.isNotEmpty ? s.urlHTML : s.urlTSJ;
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta sentencia no tiene enlace.')),
      );
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String _fechaHoy() {
    const List<String> meses = <String>[
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final DateTime h = DateTime.now();
    return '${h.day} de ${meses[h.month - 1]} de ${h.year}';
  }

  @override
  Widget build(BuildContext context) {
    final TipDelDia tip = _tip;
    return Scaffold(
      backgroundColor: TemaGlobal.superficie,
      appBar: AppBar(
        backgroundColor: TemaGlobal.superficie,
        elevation: 0,
        iconTheme: IconThemeData(color: TemaGlobal.texto),
        title: const Text('Criterio del día'),
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppTokens.margen),
                children: <Widget>[
                  AppScreenHeader(
                    titulo: 'Criterio del día',
                    subtitulo: _fechaHoy(),
                  ),
                  const SizedBox(height: 16),
                  // Tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TemaGlobal.tarjeta,
                      borderRadius: BorderRadius.circular(AppTokens.radioTarjeta),
                      border: Border.all(color: TemaGlobal.capa),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(Icons.lightbulb_outline,
                                color: AppColors.dorado, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip de alto valor',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.dorado,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Compartir tip',
                              onPressed: () => _compartir(tip.textoParaCompartir),
                              icon: Icon(Icons.share,
                                  size: 18, color: TemaGlobal.textoSecundario),
                            ),
                          ],
                        ),
                        Text(
                          tip.titulo,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: TemaGlobal.texto,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(tip.texto, style: AppTokens.cuerpo),
                        const SizedBox(height: 12),
                        Text(
                          tip.baseLegal,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TemaGlobal.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Criterio
                  if (_criterio != null) ...<Widget>[
                    Text('Sentencia del día', style: AppTokens.tituloSeccion),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TemaGlobal.tarjeta,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radioTarjeta),
                        border: Border.all(color: TemaGlobal.capa),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Nº ${_criterio!.numeroSentencia} · '
                            '${_criterio!.fechaSentencia}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TemaGlobal.texto,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_criterio!.resumen, style: AppTokens.cuerpo),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: () => _abrirSentencia(_criterio!),
                                icon: const Icon(Icons.menu_book, size: 18),
                                label: const Text('Leer'),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Compartir sentencia',
                                onPressed: () => _compartir(
                                  'Sentencia Nº ${_criterio!.numeroSentencia}\n'
                                  '${_criterio!.resumen}\n\nPenalex VE',
                                ),
                                icon: const Icon(Icons.share, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Minuta del día', style: AppTokens.tituloSeccion),
                  const SizedBox(height: 4),
                  Text(
                    _nuevasHoy
                        ? 'Publicadas hoy antes de las 8:00.'
                        : 'Hoy no hubo publicaciones nuevas. Estas son las '
                            'más recientes.',
                    style: AppTokens.secundario,
                  ),
                  const SizedBox(height: 10),
                  for (final SentenciaModel s in _minuta)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: TemaGlobal.tarjeta,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radioControl),
                        border: Border.all(color: TemaGlobal.capa),
                      ),
                      child: ListTile(
                        onTap: () => _abrirSentencia(s),
                        title: Text(
                          'Nº ${s.numeroSentencia}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TemaGlobal.texto,
                          ),
                        ),
                        subtitle: Text(
                          '${s.fechaSentencia} · ${s.resumen}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: TemaGlobal.textoSecundario,
                          ),
                        ),
                        trailing: IconButton(
                          tooltip: 'Compartir',
                          onPressed: () => _compartir(
                            'Sentencia Nº ${s.numeroSentencia}\n'
                            '${s.resumen}\n\nPenalex VE',
                          ),
                          icon: const Icon(Icons.share, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
