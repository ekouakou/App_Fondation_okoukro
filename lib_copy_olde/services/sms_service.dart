/// Service abstrait pour l'envoi de SMS
/// 
/// Implémentations possibles :
/// - MockSmsService : pour le développement (ne fait pas d'envoi réel)
/// - TwilioSmsService : intégration avec Twilio
/// - AwsSnsService : intégration avec AWS SNS
/// - LocalSmsService : intégration avec un service SMS local
abstract class SmsService {
  /// Envoie un SMS avec le code OTP au numéro de téléphone
  /// 
  /// [phone] : Numéro de téléphone au format international (ex: +2250748011247)
  /// [otpCode] : Code OTP à envoyer
  /// 
  /// Retourne true si l'envoi a réussi, false sinon
  Future<bool> sendOtpSms(String phone, String otpCode);
  
  /// Vérifie si le service SMS est configuré et disponible
  bool get isAvailable;
}

/// Implémentation mock pour le développement
/// 
/// Ne fait pas d'envoi réel de SMS, juste pour les tests
class MockSmsService implements SmsService {
  @override
  bool get isAvailable => true;
  
  @override
  Future<bool> sendOtpSms(String phone, String otpCode) async {
    // Simule un délai d'envoi
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // En mode développement, on log le SMS qui serait envoyé
    print('📱 [MOCK SMS] Envoi OTP à $phone : $otpCode');
    print('⚠️  Mode développement : SMS non envoyé réellement');
    
    // Retourne toujours true en mode mock
    return true;
  }
}

/// Implémentation pour un service SMS réel (à implémenter)
/// 
/// Exemple avec Twilio :
/// ```dart
/// class TwilioSmsService implements SmsService {
///   final String accountSid;
///   final String authToken;
///   final String fromNumber;
///   
///   @override
///   bool get isAvailable => accountSid.isNotEmpty && authToken.isNotEmpty;
///   
///   @override
///   Future<bool> sendOtpSms(String phone, String otpCode) async {
///     try {
///       final client = TwilioClient(accountSid, authToken);
///       final message = await client.messages.create(
///         body: 'Votre code OTP est : $otpCode',
///         from: fromNumber,
///         to: phone,
///       );
///       return message.sid != null;
///     } catch (e) {
///       print('Erreur envoi SMS: $e');
///       return false;
///     }
///   }
/// }
/// ```
/// 
/// TODO: Implémenter avec votre service SMS préféré :
/// - Twilio (https://www.twilio.com/)
/// - AWS SNS (https://aws.amazon.com/sns/)
/// - Orange SMS API (pour la Côte d'Ivoire)
/// - Autre service SMS local

