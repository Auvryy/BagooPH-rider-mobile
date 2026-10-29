import '../../../core/network/api_failure.dart';
import '../../../core/network/rider_api_client.dart';
import '../../../core/network/wire.dart';
import '../../home/data/command_journal.dart';
import 'company_models.dart';

class RiderCompanyRepository {
  RiderCompanyRepository(
    this.api, {
    required this.accountId,
    required this.journal,
    required this.isCurrent,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final RiderSessionApi api;
  final String accountId;
  final CommandJournal journal;
  final bool Function() isCurrent;
  final DateTime Function() now;
  bool _writing = false;

  void _guard() {
    if (!isCurrent()) {
      throw const AccountFailure('Please sign in again.', status: 401);
    }
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Object? body,
    Map<String, String> headers = const {},
  }) async {
    _guard();
    final result = await api.authenticatedRequest(
      path,
      method: method,
      data: body,
      headers: headers,
    );
    _guard();
    return Wire.object(result['data']);
  }

  String _page(String path, int page, Map<String, String> filters) {
    if (page < 1 || page > 10000) Wire.invalid();
    return Uri(
      path: path,
      queryParameters: {'page': '$page', 'per_page': '20', ...filters},
    ).toString();
  }

  Future<CompanyAssignment> assignment() async =>
      CompanyAssignment.fromJson(await _request('rider/company-assignment'));
  Future<RiderCompany> company(String id) async {
    final result = RiderCompany.fromJson(
      await _request('rider/companies/${Wire.id(id)}'),
    );
    if (result.id != id) Wire.invalid();
    return result;
  }

  Future<CompanyPage<RiderCompany>> companies({
    int page = 1,
    String search = '',
    String province = '',
  }) async {
    for (final value in [search, province]) {
      if (value.runes.length > 100 ||
          value.contains(RegExp(r'[\x00-\x1f\x7f<>]'))) {
        throw const AccountFailure(
          'Use up to 100 characters of plain text to search.',
        );
      }
    }
    final result = CompanyPage.fromJson(
      await _request(
        _page('rider/companies', page, {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (province.trim().isNotEmpty) 'province': province.trim(),
        }),
      ),
      RiderCompany.fromJson,
      (row) => row.id,
    );
    if (result.page != page || result.perPage != 20) Wire.invalid();
    return result;
  }

  Future<CompanyPage<CompanyApplication>> applications({int page = 1}) async {
    final result = CompanyPage.fromJson(
      await _request(_page('rider/company-requests', page, {})),
      CompanyApplication.fromJson,
      (row) => row.id,
    );
    if (result.page != page || result.perPage != 20) Wire.invalid();
    return result;
  }

  Future<CompanyApplication> application(String id) async {
    final result = CompanyApplication.fromJson(
      await _request('rider/company-requests/${Wire.id(id)}'),
    );
    if (result.id != id) Wire.invalid();
    return result;
  }

  Future<CommandIntent?> pending() async {
    _guard();
    final saved = await journal.read();
    _guard();
    if (saved != null && (saved.accountId != accountId || !saved.isCompany)) {
      Wire.invalid();
    }
    return saved;
  }

  void _dispatchGuard(bool Function() mayDispatch) {
    _guard();
    if (!mayDispatch()) {
      throw const AccountFailure(
        'Return to this page and refresh before continuing.',
      );
    }
  }

  Future<void> _revalidate(
    CommandIntent intent,
    bool Function() mayDispatch,
  ) async {
    _dispatchGuard(mayDispatch);
    if (intent.action == 'company.submit') {
      final membership = await assignment();
      _dispatchGuard(mayDispatch);
      final current = await company(
        companyResourceId(intent.action, intent.resource),
      );
      _dispatchGuard(mayDispatch);
      if (!membership.canApply ||
          current.intakeVersion !=
              companyCounter(intent.body['intake_version'])) {
        throw const AccountFailure(
          'Company intake or your eligibility changed. Refresh and review the company again.',
          status: 409,
          code: 'STALE_COMPANY',
        );
      }
    } else {
      final current = await application(
        companyResourceId(intent.action, intent.resource),
      );
      _dispatchGuard(mayDispatch);
      final allowed = switch (intent.action) {
        'company.accepted' => current.canAccept,
        'company.declined' => current.canDecline,
        'company.withdrawn' => current.canWithdraw,
        _ => false,
      };
      if (!allowed ||
          current.version != companyCounter(intent.body['expected_version']) ||
          intent.action == 'company.accepted' &&
              (current.offer?.id != intent.body['offer_id'] ||
                  current.offer?.termsHash != intent.body['terms_hash'])) {
        throw const AccountFailure(
          'This request or its offer changed. Refresh and review the current details before deciding.',
          status: 409,
          code: 'STALE_COMPANY_OFFER',
        );
      }
    }
  }

  Future<CompanyCommandReceipt> submit(
    RiderCompany company, {
    String? note,
    required bool sharingAcknowledged,
    required bool Function() mayDispatch,
  }) => _newIntent('company.submit', 'company-${company.id}', {
    'company_id': company.id,
    'intake_version': company.intakeVersion,
    'sharing_acknowledged': sharingAcknowledged,
    'note': ?companyNote(note),
  }, mayDispatch);

  Future<CompanyCommandReceipt> decide(
    CompanyApplication request,
    String action, {
    bool acknowledged = false,
    String? reason,
    required bool Function() mayDispatch,
  }) {
    if (![
      'company.accepted',
      'company.declined',
      'company.withdrawn',
    ].contains(action)) {
      Wire.invalid();
    }
    return _newIntent(action, 'company-request-${request.id}', {
      'expected_version': request.version,
      if (action == 'company.accepted') ...{
        'offer_id': request.offer?.id,
        'terms_hash': request.offer?.termsHash,
        'acknowledged': acknowledged,
      } else 'reason': ?companyNote(reason, field: 'reason'),
    }, mayDispatch);
  }

  Future<CompanyCommandReceipt> _newIntent(
    String action,
    String resource,
    Map<String, dynamic> body,
    bool Function() mayDispatch,
  ) async {
    if (_writing) {
      throw const AccountFailure('A company request is already being checked.');
    }
    _writing = true;
    try {
      _dispatchGuard(mayDispatch);
      if (await pending() != null) {
        throw const AccountFailure(
          'Check the saved company request before starting another.',
        );
      }
      final intent = CommandIntent(
        accountId: accountId,
        key: commandUuid(),
        action: action,
        resource: resource,
        body: body,
        createdAt: now().toUtc(),
      );
      await _revalidate(intent, mayDispatch);
      await journal.write(intent);
      _dispatchGuard(mayDispatch);
      return await _dispatch(intent);
    } finally {
      _writing = false;
    }
  }

  Future<CompanyCommandReceipt> _accept(
    CommandIntent intent,
    Map<String, dynamic> data,
  ) async {
    final result = CompanyCommandReceipt.fromJson(data, intent);
    _guard();
    await journal.clear();
    _guard();
    return result;
  }

  Future<CompanyCommandReceipt> _dispatch(CommandIntent intent) async {
    try {
      return await _accept(
        intent,
        await _request(
          intent.path,
          method: 'POST',
          body: intent.body,
          headers: {'Idempotency-Key': intent.key},
        ),
      );
    } on AccountFailure catch (error) {
      // Definitive validation/source rejection means this attempt did not commit.
      // A conflicting key may name an earlier result and must remain recoverable.
      if (!error.unconfirmed &&
          [409, 422].contains(error.status) &&
          error.code != 'IDEMPOTENCY_CONFLICT') {
        await journal.clear();
      }
      rethrow;
    }
  }

  Future<CompanyCommandReceipt?> reconcile({
    bool retryUnknown = false,
    required bool Function() mayDispatch,
  }) async {
    if (_writing) {
      throw const AccountFailure('A company request is already being checked.');
    }
    _writing = true;
    try {
      final intent = await pending();
      if (intent == null) return null;
      try {
        return await _accept(
          intent,
          await _request('rider/company-commands/${intent.key}'),
        );
      } on AccountFailure catch (error) {
        if (error.status != 404 || error.code != 'COMMAND_UNKNOWN') rethrow;
        if (!retryUnknown) rethrow;
      }
      if (now().toUtc().difference(intent.createdAt) >
          const Duration(days: 7)) {
        throw const AccountFailure(
          'This original request is too old to retry. Its saved reference is retained for checking.',
        );
      }
      await _revalidate(intent, mayDispatch);
      _dispatchGuard(mayDispatch);
      return await _dispatch(intent);
    } finally {
      _writing = false;
    }
  }
}
