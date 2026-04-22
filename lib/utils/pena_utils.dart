class PenaUtils {
  static String formatPena(double years) {
    if (years <= 0) return '0 años';
    final Map<String, int> ymd = _convertToYMD(years);
    final List<String> parts = <String>[];
    
    if (ymd['anos']! > 0) parts.add('${ymd['anos']} ${ymd['anos'] == 1 ? 'año' : 'años'}');
    if (ymd['meses']! > 0) parts.add('${ymd['meses']} ${ymd['meses'] == 1 ? 'mes' : 'meses'}');
    if (ymd['dias']! > 0) parts.add('${ymd['dias']} ${ymd['dias'] == 1 ? 'día' : 'días'}');
    
    return parts.isEmpty ? '0 días' : parts.join(', ');
  }

  static Map<String, int> _convertToYMD(double totalYears) {
    if (totalYears <= 0) return <String, int>{'anos': 0, 'meses': 0, 'dias': 0};
    
    final int totalDias = (totalYears * 360).round();
    int anos = totalDias ~/ 360;
    int meses = (totalDias % 360) ~/ 30;
    int dias = totalDias % 30;

    if (dias == 30) {
      meses += 1;
      dias = 0;
    }
    if (meses == 12) {
      anos += 1;
      meses = 0;
    }
    return <String, int>{'anos': anos, 'meses': meses, 'dias': dias};
  }
}