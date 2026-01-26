import 'package:flutter/material.dart';
import 'package:app_finanzas/app/core/loading_registry.dart';

class GlobalLoadingOverlay extends StatelessWidget {
  final Widget child;
  final String message;

  const GlobalLoadingOverlay({
    super.key,
    required this.child,
    this.message = 'Procesando...',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<int>(
          valueListenable: LoadingRegistry.counter,
          builder: (_, count, __) {
            if (count <= 0) return const SizedBox.shrink();

            return PopScope(
              canPop: false, // bloquea back (Android)
              child: AbsorbPointer(
                absorbing: true, // bloquea todos los taps
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.70), // más invasivo
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loader gigante "bonito"
                      const SizedBox(
                        width: 88,
                        height: 88,
                        child: CircularProgressIndicator(
                          strokeWidth: 7,
                          // respeta el theme; si quieres un color fijo, se puede,
                          // pero lo dejamos neutro.
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Text(
                      //   'Por favor espera',
                      //   style: TextStyle(
                      //     color: Colors.white.withOpacity(0.85),
                      //     fontSize: 13,
                      //     fontWeight: FontWeight.w500,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
