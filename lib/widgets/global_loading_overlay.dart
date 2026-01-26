import 'package:flutter/material.dart';
import 'package:app_finanzas/app/core/loading_registry.dart';

class GlobalLoadingOverlay extends StatelessWidget {
  final Widget child;

  const GlobalLoadingOverlay({
    super.key,
    required this.child,
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
              canPop: false, // bloquea back
              child: AbsorbPointer(
                absorbing: true, // bloquea taps
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white, // blanco total
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          strokeWidth: 7,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Cargando...',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
