import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/summary/summary_pane.dart';

void main() {
  test('"Enviar email": the period is the subject, the rest the body, spaces as %20', () {
    final uri = summaryMailUri('20 set - 26 set\n\nConcluído\n- [24 set] Relatório & café');
    expect(uri.scheme, 'mailto');
    expect(uri.toString(), isNot(contains('+')));
    expect(Uri.decodeComponent(uri.toString().split('subject=')[1].split('&')[0]), '20 set - 26 set');
    expect(Uri.decodeComponent(uri.toString().split('body=')[1]), 'Concluído\n- [24 set] Relatório & café');
  });
}
