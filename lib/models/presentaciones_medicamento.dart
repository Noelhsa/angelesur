import '../utils/texto_busqueda.dart';

const presentacionesMedicamento = <String, String>{
  'TABLETA': 'Tableta',
  'CAPSULA': 'Capsula',
  'PASTILLA': 'Pastilla',
  'JARABE': 'Jarabe',
  'SUSPENSION': 'Suspension',
  'GOTAS': 'Gotas',
  'INYECCION': 'Inyectable',
  'CREMA': 'Crema',
  'POMADA': 'Pomada',
  'AEROSOL': 'Spray',
  'SOLUCION': 'Solucion',
  'OTRO': 'Otro',
};

String normalizarPresentacion(String? valor) {
  final texto = normalizarTextoBusqueda(valor ?? '');
  if (texto.isEmpty || texto == 'sin especificar') return '';
  for (final opcion in presentacionesMedicamento.entries) {
    if (texto == opcion.key.toLowerCase() ||
        texto == opcion.value.toLowerCase()) {
      return opcion.key;
    }
  }
  const variantes = {
    'tabletas': 'TABLETA',
    'capsulas': 'CAPSULA',
    'pastillas': 'PASTILLA',
    'jarabes': 'JARABE',
    'suspensiones': 'SUSPENSION',
    'gota': 'GOTAS',
    'inyecciones': 'INYECCION',
    'inyectables': 'INYECCION',
    'cremas': 'CREMA',
    'pomadas': 'POMADA',
    'aerosoles': 'AEROSOL',
    'soluciones': 'SOLUCION',
    'otros': 'OTRO',
  };
  // Historical free-text values must survive opening and saving the editor.
  return variantes[texto] ?? valor!.trim();
}

String presentacionVisible(String? valor) {
  final codigo = normalizarPresentacion(valor);
  return codigo.isEmpty
      ? 'Sin especificar'
      : presentacionesMedicamento[codigo] ?? codigo;
}
