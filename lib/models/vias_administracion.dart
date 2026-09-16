// Database/API codes are separate from the labels displayed to the user.
const Map<String, String> viasAdministracion = {
  'ORAL': 'Oral',
  'SUBLINGUAL': 'Sublingual',
  'RECTAL': 'Rectal',
  'INTRAVENOSA': 'Intravenosa',
  'INTRAMUSCULAR': 'Intramuscular',
  'SUBCUTANEA': 'Subcut\u00e1nea',
  'INTRADERMICA': 'Intrad\u00e9rmica',
  'TOPICA': 'T\u00f3pica',
  'INHALATORIA': 'Inhalatoria',
  'OFTALMICA': 'Oft\u00e1lmica',
  'OTICA': '\u00d3tica',
  'NASAL': 'Nasal',
  'VAGINAL': 'Vaginal',
};

String etiquetaViaAdministracion(String? codigo) =>
    viasAdministracion[codigo] ?? 'Sin especificar';
