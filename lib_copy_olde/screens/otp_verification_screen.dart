import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../app.dart';
import '../widgets/custom_button.dart';
import '../config/app_colors.dart';

/// Écran de vérification OTP
class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final bool isLogin; // true pour connexion, false pour inscription
  final String? firstName; // Optionnel, pour l'inscription
  final String? lastName; // Optionnel, pour l'inscription
  final String? email; // Optionnel, pour l'inscription

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.isLogin = false,
    this.firstName,
    this.lastName,
    this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    // Auto-focus sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
        _startResendCountdown();
      }
    });
  }

  void _handleOtpChange(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Vérifier si tous les champs sont remplis
    if (index == 5 && value.isNotEmpty) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Vérifier l'OTP via AuthService
    bool success;
    if (widget.isLogin) {
      // Connexion
      success = await AuthService.instance.verifyOtpAndLogin(
        widget.phone,
        otp,
      );
    } else {
      // Inscription
      success = await AuthService.instance.verifyOtpAndCreateAccount(
        phone: widget.phone,
        otp: otp,
        firstName: widget.firstName ?? 'Parent',
        lastName: widget.lastName ?? 'Utilisateur',
        email: widget.email,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      // Compte créé avec succès, rediriger vers l'application
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const App()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code OTP invalide. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
      // Effacer les champs
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _isResending = true;
    });

    // Envoie l'OTP via AuthService avec vérification des crédits
    final result = await AuthService.instance.sendOtp(widget.phone);

    setState(() {
      _isResending = false;
    });

    if (result == OtpSendResult.insufficientCredits) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédits SMS insuffisants. Veuillez recharger votre compte avant de renvoyer le code OTP.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    } else if (result != OtpSendResult.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du renvoi du code OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _resendCountdown = 60;
    });

    _startResendCountdown();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code OTP renvoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        title: Text(
          'Vérification OTP',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.primary.withOpacity(0),
                    AppColors.primary.withOpacity(0),
                    AppColors.primary.withOpacity(0.3),
                    AppColors.getPureAppBarBackground(true),
                  ]
                : [
                    AppColors.primary.withOpacity(0),
                    AppColors.primary.withOpacity(0),
                    AppColors.primary.withOpacity(0.3),
                    AppColors.getPureAppBarBackground(false),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Icône
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.toSurface(),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sms,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'VÉRIFICATION',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez le code à 6 chiffres envoyé au',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phone,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Champs OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 45,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.grey800 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) => _handleOtpChange(index, value),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Vérifier',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                // Renvoyer le code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Vous n\'avez pas reçu le code ? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_resendCountdown > 0)
                      Text(
                        'Renvoyer dans ${_resendCountdown}s',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      )
                    else
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Renvoyer'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Info box - Mode développement
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mode développement - SMS non envoyé',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Code OTP de test à utiliser : 123456',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[800],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'En production, le code sera envoyé par SMS à votre numéro.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

