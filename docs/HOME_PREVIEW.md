# Home preview and Demo login

This is a small development layout slice: Home greeting, three queue filters,
sample parcel cards and an exit to login. It can be reviewed without an account,
email code or running backend.

From the Rider repository:

```sh
flutter run -d linux --dart-define=HOME_PREVIEW=true
```

For Chrome:

```sh
flutter run -d chrome --dart-define=HOME_PREVIEW=true --dart-define=DEVICE_PREVIEW=false
```

Press **Demo login** on the login screen. Switch between **Available pickups**,
**My pickups** and **Assigned delivery**, then choose **Exit demo**. All addresses
and parcel references are synthetic. Each filter is a separate sample scenario;
the page does not depict simultaneous pickup and final-mile assignments.

The preview has its own route and local selection state. It never signs in an
account, issues a token, changes the real auth provider or performs a parcel
action. Exiting discards the selection; opening again starts with available
pickups. Actual [account login and logout](ACCOUNT_ACCESS.md) remain separate.
The demo entry clears any typed password before opening the preview.

`HOME_PREVIEW` defaults to false. Both its button and route require debug mode
and explicit opt-in; release/profile builds exclude them even when the flag is
requested. Device Preview remains a separate debug option.

Source review: backend `7534acd` contains the accepted local account adapter,
but operational task/claim/duty/delivery APIs are still separate prerequisites.
This slice changes only the Rider repository. It contributes layout evidence to
M04 and development fixtures to M02; it does not complete their live-API cards,
task freshness/capacity policies, navigation shell or Android acceptance.

Checks cover opt-in routing, zero authentication calls during demo navigation,
filter/reset/exit behavior, unchanged real account sign-in/logout, 320-width
200% text and desktop layouts. Run `flutter analyze` and `flutter test`.
