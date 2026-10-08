# Home layout fixtures

The earlier standalone Home preview has been retired from the application at
the user's request. Ordinary Linux/Android runs and APKs connect to Azure and
show real account login. HOME_PREVIEW no longer adds a button/route or disables
account access. See [everyday run instructions](../README.md#run-locally).

The synthetic Home cards and selection/exit behavior remain widget-test fixtures
in `test/home_preview_test.dart`. Tests mount the fixture directly in their own
harness; the main application never imports or navigates to it. These checks
prove layout behavior, not live task/claim/duty/delivery integration.

The earlier layout slice contributed M04 presentation and M02 fixture evidence.
Operational API prerequisites and server authority remain unchanged. Run
`flutter test test/home_preview_test.dart` for the bounded layout checks.
