import 'recaptcha_helper_stub.dart'
    if (dart.library.html) 'recaptcha_helper_web.dart';

void setupRecaptchaContainer() {
  ensureRecaptchaContainerExists();
}
