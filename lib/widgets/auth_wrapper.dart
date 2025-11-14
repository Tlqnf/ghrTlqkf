import 'package:flutter/material.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/route/app_route.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Provider.of<AuthProvider>(context, listen: false).tryAutoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            switch (auth.authState) {
              case AuthState.loggedIn:
                debugPrint("로그인 성공");
                return AppRoute.routes[AppRoute.main]!(context);
              case AuthState.needsProfileSetup:
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoute.profile,
                    arguments: {
                      "onSetupComplete": () => auth.completeProfileSetup(),
                      "token": auth.token,
                    },
                  );
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              case AuthState.loggedOut:
                return AppRoute.routes[AppRoute.login]!(context);
              default:
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
            }
          },
        );
      },
    );
  }
}
