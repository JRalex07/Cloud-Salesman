import 'dart:html' as html;

void ensureRecaptchaContainerExists() {
  try {
    if (html.document.getElementById('recaptcha-container') == null) {
      final div = html.DivElement()
        ..id = 'recaptcha-container'
        ..style.position = 'absolute'
        ..style.bottom = '10px'
        ..style.right = '10px'
        ..style.width = '0px'
        ..style.height = '0px'
        ..style.opacity = '0'
        ..style.pointerEvents = 'none';
      html.document.body?.append(div);
    }
  } catch (e) {
    // Graceful safety guard for non-browser/unusual environments
  }
}
