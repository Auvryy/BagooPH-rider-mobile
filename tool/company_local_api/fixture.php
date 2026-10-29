<?php

// Software fixture only. The reference backend is frozen and read-only; every
// migration, account, placement and consent lives in SQLite :memory:.
[$script, $backend, $runtime] = $argv;
foreach (['APP_ENV' => 'testing', 'APP_DEBUG' => 'false', 'APP_URL' => 'http://localhost',
    'APP_KEY' => 'base64:'.base64_encode(random_bytes(32)),
    'APP_CONFIG_CACHE' => $runtime.'/config.php', 'APP_ROUTES_CACHE' => $runtime.'/routes.php',
    'APP_PACKAGES_CACHE' => $runtime.'/packages.php', 'APP_SERVICES_CACHE' => $runtime.'/services.php',
    'APP_EVENTS_CACHE' => $runtime.'/events.php',
    'DB_CONNECTION' => 'sqlite', 'DB_DATABASE' => ':memory:', 'DB_URL' => '',
    'CACHE_STORE' => 'array', 'SESSION_DRIVER' => 'array', 'QUEUE_CONNECTION' => 'sync',
    'MAIL_MAILER' => 'array', 'LOG_CHANNEL' => 'null', 'BROADCAST_CONNECTION' => 'null',
    'BCRYPT_ROUNDS' => '4', 'ARGON_MEMORY' => '1024', 'ARGON_TIME' => '1',
    'PULSE_ENABLED' => 'false', 'TELESCOPE_ENABLED' => 'false', 'NIGHTWATCH_ENABLED' => 'false',
] as $key => $value) {
    putenv($key.'='.$value);
    $_ENV[$key] = $_SERVER[$key] = $value;
}
chdir($backend);
require $backend.'/vendor/autoload.php';
PHPUnit\TextUI\Configuration\Registry::init(
    (new PHPUnit\TextUI\CliArguments\Builder)->fromParameters([]),
    PHPUnit\TextUI\XmlConfiguration\DefaultConfiguration::create(),
);

class NativeCompanyFixture extends Tests\Feature\Courier\RiderCompanyApiTest
{
    private string $sandbox;

    public function sandbox(string $path): void { $this->sandbox = $path; }

    public function createApplication()
    {
        $app = parent::createApplication();
        $app->useStoragePath($this->sandbox.'/storage');
        $sqlite = config('database.connections.sqlite');
        $sqlite['database'] = ':memory:';
        $sqlite['url'] = null;
        config(['database.default' => 'sqlite', 'database.connections' => ['sqlite' => $sqlite],
            'view.compiled' => $this->sandbox.'/views', 'logging.default' => 'null']);
        if (config('database.default') !== 'sqlite' || config('database.connections.sqlite.database') !== ':memory:') {
            throw new RuntimeException('Company verification requires isolated SQLite :memory:.');
        }
        return $app;
    }

    public function startFixture(): void
    {
        foreach (['storage/framework/views', 'storage/framework/cache', 'storage/framework/sessions', 'views'] as $path) {
            mkdir($this->sandbox.'/'.$path, 0700, true);
        }
        parent::setUp();
        $this->assertSame(':memory:', Illuminate\Support\Facades\DB::connection()->getDatabaseName());
        $this->defaultHeaders = [];
    }

    public function control(array $message): array
    {
        if ($message['operation'] === 'info') {
            return ['database' => ':memory:', 'email' => $this->rider->email, 'password' => 'Password1234'];
        }
        if ($message['operation'] === 'offer') {
            $application = App\Models\RiderCompanyRequest::where('rider_id', $this->rider->id)->sole();
            return app(App\Services\Logistics\RiderCompanyOfferService::class)->issue($this->owner, $application->id, [
                'expected_version' => $application->version, 'request_token' => (string) Illuminate\Support\Str::uuid(),
                'hub_id' => $this->hub->id, 'barangay' => 'Bagumbayan',
                'terms' => 'Report to the recorded Bayan Hub and arrange your daily schedule.',
            ]);
        }
        if ($message['operation'] === 'counts') {
            $profile = $this->rider->courierProfile()->sole();
            return ['requests' => App\Models\RiderCompanyRequest::count(), 'commands' => App\Models\RiderCommand::count(),
                'consents' => App\Models\RiderCompanyConsent::count(), 'placements' => App\Models\LogisticsPlacementRecord::count(),
                'on_duty' => $profile->is_available, 'company_id' => $profile->logistics_company_id ? (string) $profile->logistics_company_id : null,
                'hub_id' => $profile->assigned_hub_id ? (string) $profile->assigned_hub_id : null,
                'delivery_checkpoints' => App\Models\DeliveryCheckpoint::count(), 'cod_accounts' => App\Models\CodAccount::count()];
        }
        throw new RuntimeException('Unknown local company fixture operation.');
    }

    public function requestFixture(array $message): array
    {
        $this->defaultHeaders = [];
        $this->app['auth']->forgetGuards();
        $this->app['auth']->shouldUse('web');
        $server = ['REMOTE_ADDR' => '127.0.0.1'];
        foreach ($message['headers'] as $name => $value) {
            $key = strtoupper(str_replace('-', '_', $name));
            $server[in_array($key, ['CONTENT_TYPE', 'CONTENT_LENGTH']) ? $key : 'HTTP_'.$key] = $value;
        }
        $response = $this->call($message['method'], $message['path'], $message['fields'], [], [], $server,
            $message['body'] === null ? null : base64_decode($message['body'], true))->baseResponse;
        return ['status' => $response->getStatusCode(), 'headers' => $response->headers->all(), 'body' => base64_encode($response->getContent())];
    }

    public function stopFixture(): void { parent::tearDown(); }
}

$fixture = new NativeCompanyFixture('test_approved_unassigned_account_discovers_directory_and_sharing_without_operational_placement');
$fixture->sandbox($runtime);
try {
    ob_start();
    $fixture->startFixture();
    ob_end_clean();
    fwrite(STDOUT, json_encode(['ready' => true])."\n");
    stream_set_timeout(STDIN, 3600);
    while (($line = fgets(STDIN)) !== false) {
        $message = json_decode($line, true, flags: JSON_THROW_ON_ERROR);
        ob_start();
        try {
            $result = isset($message['operation']) ? $fixture->control($message) : $fixture->requestFixture($message);
            ob_end_clean();
            fwrite(STDOUT, json_encode(['result' => $result], JSON_THROW_ON_ERROR)."\n");
        } catch (Throwable $error) {
            ob_end_clean();
            fwrite(STDERR, get_class($error).': '.$error->getMessage()."\n".$error->getTraceAsString()."\n");
            fwrite(STDOUT, json_encode(['error' => 'The isolated company fixture failed; inspect its private diagnostic log.'])."\n");
        }
    }
    $fixture->stopFixture();
} catch (Throwable $error) {
    fwrite(STDERR, get_class($error).': '.$error->getMessage()."\n".$error->getTraceAsString()."\n");
    exit(1);
}
