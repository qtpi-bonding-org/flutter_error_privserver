import 'package:flutter_test/flutter_test.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

class _State with UiFlowStateMixin {
  const _State({this.status = UiFlowStatus.idle, this.error});
  @override
  final UiFlowStatus status;
  @override
  final Object? error;

  _State copyWith({UiFlowStatus? status, Object? error}) =>
      _State(status: status ?? this.status, error: error ?? this.error);
}

class _Cubit extends TryOperationCubit<_State> with ErrorPrivserverMixin<_State> {
  _Cubit() : super(const _State());

  Future<void> fail() => tryOperation(() async => throw Exception('boom'));
  Future<void> succeed() =>
      tryOperation(() async => state.copyWith(status: UiFlowStatus.success));
}

class _FakeStorage implements ErrorBoxStorage {
  final saved = <ErrorEntry>[];

  @override
  Future<void> saveError(ErrorEntry error) async => saved.add(error);
  @override
  Future<List<ErrorBoxEntry>> getUnsentErrors() async => [];
  @override
  Future<ErrorBoxEntry?> getErrorById(String id) async => null;
  @override
  Future<void> markAsSent(String id) async {}
  @override
  Future<void> deleteError(String id) async {}
  @override
  Future<int> getUnsentCount() async => saved.length;
}

void main() {
  test('captures an operation error via the onOperationError hook, not by duplicating tryOperation', () async {
    final storage = _FakeStorage();
    ErrorPrivserverMixin.configure(ErrorPrivserverConfig(
      storage: storage,
      reporter: (_) async => true,
      errorCodeMapper: (_) => 'ERR',
      exceptionMapper: (_) => null,
    ));

    final cubit = _Cubit();
    await cubit.fail();
    await pumpEventQueue();

    expect(cubit.state.status, UiFlowStatus.failure);
    expect(storage.saved, hasLength(1));
    expect(storage.saved.single.errorType, contains('Exception'));
    await cubit.close();
  });

  test('does not capture on a successful operation', () async {
    final storage = _FakeStorage();
    ErrorPrivserverMixin.configure(ErrorPrivserverConfig(
      storage: storage,
      reporter: (_) async => true,
      errorCodeMapper: (_) => 'ERR',
      exceptionMapper: (_) => null,
    ));

    final cubit = _Cubit();
    await cubit.succeed();
    await pumpEventQueue();

    expect(cubit.state.status, UiFlowStatus.success);
    expect(storage.saved, isEmpty);
    await cubit.close();
  });
}
