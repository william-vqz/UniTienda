// lib/core/constants/app_strings.dart
class AppStrings {
  AppStrings._();

  static const appName = 'UniTienda';
  static const appSubtitle = 'CBTis 272 · Cancún';

  static const loginTitle = 'Bienvenido a UniTienda';
  static const loginSubtitle =
      'Inicia sesión con tu correo electrónico y contraseña';
  static const registerTitle = 'Registro de Alumno';
  static const registerSubtitle =
      'Crea tu cuenta para acceder al catálogo de uniformes';
  static const haveAccount = '¿Ya tienes cuenta? Inicia sesión';
  static const noAccount = '¿No tienes cuenta? Regístrate';

  static const fieldNombreCompleto = 'Nombre completo';
  static const fieldMatricula = 'Matrícula';
  static const fieldGrado = 'Grado';
  static const fieldGrupo = 'Grupo';
  static const fieldEmail = 'Correo electrónico';
  static const fieldTelefono = 'Número de teléfono';
  static const fieldPassword = 'Contraseña';
  static const fieldConfirmPassword = 'Confirmar contraseña';
  static const btnLogin = 'Iniciar Sesión';
  static const btnRegister = 'Registrarse';

  static const catalogTitle = 'Catálogo de Uniformes';

  static const notificationsTitle = 'Notificaciones';
  static const noNotifications = 'No tienes notificaciones';
  static const markAllRead = 'Marcar todas como leídas';

  static String stockAlertBanner({required int remaining}) =>
      'Solo quedan $remaining piezas listas. Si continúas, '
      'las piezas restantes se procesarán como Pedido Especial de Fábrica.';

  static const noStockMessage =
      'Producto sin stock físico. Requiere Pedido Especial de Fábrica.';

  static const cartTitle = 'Mi Carrito';
  static const cartEmpty = 'Tu carrito está vacío.';
  static const btnCheckout = 'Proceder al Pago';
  static const couponHint = 'Cupón institucional (ej. INSCRIPCION)';

  static const paymentCard = 'Pago Digital / Tarjeta';
  static const paymentOxxo = 'Depósito / OXXO / Transferencia';
  static const paymentCash = 'Pago en Efectivo (ventanilla)';
  static const uploadReceipt = 'Subir comprobante fotográfico';

  static String pushAdminNewOrder({required String studentName}) =>
      '¡Nuevo pedido recibido! El alumno $studentName ha generado una solicitud. '
      'Revisa el panel para empaquetar o verificar el pago.';

  static String pushAdminLowStock(
          {required String productName, required String size}) =>
      'Alerta de Stock Bajo: Quedan pocas unidades de $productName '
      'en Talla $size. Se sugiere coordinación con fábrica.';

  static const pushAlumnoOrderConfirmed =
      'Tu pedido ha sido confirmado. Tu uniforme especial llegará '
      'en aproximadamente una semana.';

  static const pushAlumnoReadyPickup =
      'Tu uniforme ya está listo. Puedes pasar a recogerlo a la papelería.';

  static String pushAlumnoCancelled({required String reason}) =>
      'Tu pedido ha sido cancelado por $reason. Por favor, '
      'pasa por tu dinero en efectivo a la ventanilla de la papelería.';

  static const errorGeneric = 'Ocurrió un error. Inténtalo de nuevo.';
  static const errorNoNetwork = 'Sin conexión a la red del plantel.';
  static const errorPasswordsDoNotMatch = 'Las contraseñas no coinciden';
  static const errorEmailInvalid = 'Correo electrónico no válido';
  static const errorTelefonoInvalid = 'Número de teléfono no válido';
  static const errorEmailExists = 'Este correo ya está registrado';
  static const errorMatriculaExists = 'Esta matrícula ya está registrada';
}
