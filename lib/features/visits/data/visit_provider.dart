import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'visit_repository.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository();
});
