import 'package:flutter/material.dart';
import 'shopify_auth_service.dart';
import 'auth_storage.dart';
import 'main.dart';

class ActivationInfoPage extends StatefulWidget {
  final String email;
  final String password;
  final ShopifyAuthService auth;

  const ActivationInfoPage({
    super.key,
    required this.email,
    required this.password,
    required this.auth,
  });

  @override
  State<ActivationInfoPage> createState() => _ActivationInfoPageState();
}

class _ActivationInfoPageState extends State<ActivationInfoPage> {
  bool _loading = false;
  String? _error;

  Future<void> _loginAfterVerify() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await widget.auth.loginAndGetAccessToken(
        email: widget.email,
        password: widget.password,
      );

      await AuthStorage.saveToken(token);

 if (!mounted) return;
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const MainShell()),
  (route) => false,
);


    } catch (e) {
      setState(() {
        _error =
            'Noch nicht bestätigt. Bitte öffne die Bestätigungs-Mail und klicke den Link. Danach hier nochmal drücken.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
     appBar: AppBar(
  backgroundColor: Colors.black,
  surfaceTintColor: Colors.black,
  elevation: 0,
  automaticallyImplyLeading: false,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
    Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const MainShell()),
  (route) => false,
);
    },
  ),
  title: const Text(
    'E-Mail bestätigt',
    style: TextStyle(color: Colors.white),
  ),
),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
   //         const Text(
     //         'Herzlich Willkommen',
       //       style: TextStyle(
         //       color: Colors.white,
          //      fontSize: 26,
            //    fontWeight: FontWeight.w800,
              //  letterSpacing: 0.2,
          //    ),
          //  ),
            const SizedBox(height: 6),
       //     const Text(
         //     'Wir haben Dir eine Bestätigungs Mail gesendet.',
           //   style: TextStyle(color: Colors.white70, fontSize: 14),
         //   ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFC876).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDFC876).withOpacity(0.55),
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: Color(0xFFDFC876),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Konto erstellt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Wir haben eine Bestätigungs E-Mail an\n${widget.email}\ngesendet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                   const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _loginAfterVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDFC876),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white24,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Bestätigt – Welcome!',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}