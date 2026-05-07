// Auth Cubit - manages authentication state using flutter_bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState()) {
    _initialize();
  }

  void _initialize() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.emailVerified) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.needsVerification,
          user: user,
        ));
      }
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await AuthService.signInWithGoogle();
    
    if (result.isSuccess) {
      final user = FirebaseAuth.instance.currentUser;
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
        isLoading: false,
      ));
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await AuthService.login(email: email, password: password);
    
    if (result.isSuccess) {
      final user = FirebaseAuth.instance.currentUser;
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        isLoading: false,
      ));
    } else if (result.requiresVerification) {
      final user = FirebaseAuth.instance.currentUser;
      emit(state.copyWith(
        status: AuthStatus.needsVerification,
        user: user,
        infoMessage: result.infoMessage,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: result.errorMessage,
        isLoading: false,
      ));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await AuthService.register(
      name: name,
      email: email,
      password: password,
    );
    
    if (result.isSuccess) {
      final user = FirebaseAuth.instance.currentUser;
      emit(state.copyWith(
        status: AuthStatus.needsVerification,
        user: user,
        infoMessage: result.infoMessage,
        isLoading: false,
      ));
    } else if (result.requiresVerification) {
      emit(state.copyWith(
        status: AuthStatus.needsVerification,
        infoMessage: result.infoMessage,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: result.errorMessage,
        isLoading: false,
      ));
    }
  }

  Future<void> sendVerificationEmail() async {
    await AuthService.sendVerificationEmail();
  }

  Future<void> checkVerification() async {
    emit(state.copyWith(isLoading: true));
    final result = await AuthService.checkVerificationStatus();
    
    if (result.isSuccess) {
      final user = FirebaseAuth.instance.currentUser;
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        infoMessage: result.infoMessage,
        isLoading: false,
      ));
    } else {
      emit(state.copyWith(
        errorMessage: result.errorMessage,
        isLoading: false,
      ));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(isLoading: true));
    await AuthService.logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      isLoading: false,
    ));
  }

  Future<void> refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null) {
        if (refreshedUser.emailVerified) {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: refreshedUser,
          ));
        } else {
          emit(state.copyWith(
            status: AuthStatus.needsVerification,
            user: refreshedUser,
          ));
        }
      }
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, infoMessage: null));
  }
}