import '../../../core/network/rider_api_client.dart';
import '../../home/data/command_journal.dart';
import 'cash_models.dart';

abstract interface class CashRepository {
  bool get cashWritesVerified;
  Future<bool> cashAvailable();
  Future<CashPage> cashPage({
    int page = 1,
    String query = '',
    RiderReadCancellation? cancellation,
  });
  Future<CashAccount> cashDetail(
    String id, {
    RiderReadCancellation? cancellation,
  });
  Future<Map<String, dynamic>> offerCash(
    CashAccount reviewed, {
    required String recipientId,
    required String amount,
    required String evidenceReference,
    required bool Function() mayDispatch,
  });
  Future<CommandIntent?> pending();
  Future<Map<String, dynamic>?> reconcile({
    bool retryUnknown = false,
    bool Function()? mayDispatch,
  });
}
