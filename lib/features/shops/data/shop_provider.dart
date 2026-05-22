import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository();
});
