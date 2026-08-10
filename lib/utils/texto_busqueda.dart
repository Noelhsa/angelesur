String normalizarTextoBusqueda(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[\u00e1\u00e0\u00e4\u00e2\u00e3]'), 'a')
      .replaceAll(RegExp('[\u00e9\u00e8\u00eb\u00ea]'), 'e')
      .replaceAll(RegExp('[\u00ed\u00ec\u00ef\u00ee]'), 'i')
      .replaceAll(RegExp('[\u00f3\u00f2\u00f6\u00f4\u00f5]'), 'o')
      .replaceAll(RegExp('[\u00fa\u00f9\u00fc\u00fb]'), 'u')
      .replaceAll('\u00f1', 'n')
      .replaceAll('\u00e7', 'c');
}
