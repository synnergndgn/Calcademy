import 'package:calcademy/app/auth/auth_controller.dart';
import 'package:calcademy/app/auth/auth_providers.dart';

export 'package:calcademy/app/auth/auth_controller.dart';
export 'package:calcademy/app/auth/auth_providers.dart';

typedef AuthGateState = AuthState;
typedef AuthGateController = AuthController;

final authGateControllerProvider = authControllerProvider;
