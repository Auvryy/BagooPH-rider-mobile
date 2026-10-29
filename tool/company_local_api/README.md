# Isolated company and compatibility check

From the rider project, with the reviewed backend beside it:

```sh
node tool/parcel_local_api/run.mjs ../bagoo company <BACKEND_COMMIT>
```

Use a committed hexadecimal revision or omit it to freeze the backend's HEAD.
This suite runs native Dart HTTP against the actual Laravel kernel without
opening a window. It requires the existing Flutter toolchain, Node 22+, bsdtar,
PHP with pdo_sqlite, and backend Composer development dependencies. Command
storage uses an explicitly mocked secure-storage adapter; this is not an
operating-system keyring or physical-phone test.

The fixture inherits the backend's approved, unassigned rider and company
contract setup. Before migration it restricts all connections to SQLite
`:memory:`. The backend checkout stays read-only. Its committed source is
archived into an ignored temporary directory and removed after the run.
Synthetic credentials and the ephemeral control token are never printed.

The check loads current public registration requirements, then signs in through
the real token endpoint. Applying must preserve its original key after a failed
dispatch. The owning company's real service issues and replaces an offer; the
client must reject the earlier review before sending acceptance. A lost
acceptance response is recovered by reading the original command. Final
assertions require one request, two committed commands, one consent, one
placement, duty still off, and no delivery checkpoint or COD account.

Current Home/shift and zero-ledger Cash responses are decoded with the same
models used in the app. Separate widget tests exercise consent dialogs,
responsive layouts, session changes and company notification destinations.
These checks do not enable parcel, payment, cash, message or notification write
gates, exercise a deployed server, or certify Android permissions and recovery.
