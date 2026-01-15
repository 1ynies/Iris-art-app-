import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart' show ClientSession;
import 'package:iris_designer/Features/ONBOARDING/Domain/usecases/start_session_usecase.dart';

// --- EVENTS ---
abstract class OnboardingEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class StartSessionPressed extends OnboardingEvent {
  final String name;
  final String email;
  final String country;

  StartSessionPressed({required this.name, required this.email, required this.country});
}

// --- STATES ---
abstract class OnboardingState extends Equatable {
  @override
  List<Object> get props => [];
}

class OnboardingInitial extends OnboardingState {}
class OnboardingLoading extends OnboardingState {}
class OnboardingSuccess extends OnboardingState {
  final ClientSession session;
  OnboardingSuccess(this.session);
}
class OnboardingFailure extends OnboardingState {
  final String message;
  OnboardingFailure(this.message);
}

// --- BLOC ---
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final StartSessionUseCase startSessionUseCase;

  OnboardingBloc({required this.startSessionUseCase}) : super(OnboardingInitial()) {
    on<StartSessionPressed>((event, emit) async {
      emit(OnboardingLoading());
      
      final result = await startSessionUseCase(event.name, event.email, event.country);
      
      result.fold(
        (failure) => emit(OnboardingFailure("Error starting session")),
        (session) => emit(OnboardingSuccess(session)),
      );
    });
  }
}