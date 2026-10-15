<?php

// Test-only Laravel kernel bridge. The backend checkout is a read-only source;
// all database state is SQLite :memory: and all files live in the runner's sandbox.
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

class NativeHandoverFixture extends Tests\Feature\Courier\RiderHandoverApiTest
{
    private array $parcels = [];
    private App\Models\User $holder;
    private string $sandbox;

    public function sandbox(string $path): void
    {
        $this->sandbox = $path;
    }

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
            throw new RuntimeException('The local fixture requires an isolated in-memory database.');
        }

        return $app;
    }

    public function startFixture(): void
    {
        foreach (['storage/framework/views', 'storage/framework/cache', 'storage/framework/sessions', 'views', 'uploads'] as $path) {
            mkdir($this->sandbox.'/'.$path, 0700, true);
        }
        parent::setUp();
        $this->assertSame(':memory:', Illuminate\Support\Facades\DB::connection()->getDatabaseName());
        $this->holder = $this->createApprovedUser('courier', [
            'email' => 'handover-rider@example.test', 'password' => 'Local-Handover-123!']);
        $first = $this->flowDelivery($this->newFlowOrder(), 'assigned_pickup', $this->holder);
        $this->parcels = [$first, $this->flowDelivery($this->newFlowOrder(), 'assigned_pickup', $this->holder)];
    }

    public function control(array $message): array
    {
        $operation = $message['operation'];
        if ($operation === 'info') {
            return ['database' => ':memory:', 'email' => $this->holder->email,
                'password' => 'Local-Handover-123!', 'barcodes' => array_map(fn ($p) => $p->tracking_number, $this->parcels)];
        }
        if ($operation === 'counts') {
            return ['reports' => App\Models\HandoverIssue::count(), 'commands' => App\Models\RiderCommand::count(),
                'acknowledgements' => App\Models\HandoverIssueEvent::where('event_type', 'holder_acknowledged')->count(),
                'evidence_hashes' => App\Models\HandoverIssue::orderBy('id')->pluck('evidence_hash')->all(),
                'parcels' => array_map(fn ($p) => $p->fresh()->status, $this->parcels),
                'products_hash' => hash('sha256', json_encode(Illuminate\Support\Facades\DB::table('products')->orderBy('id')->get())),
                'orders_hash' => hash('sha256', json_encode(Illuminate\Support\Facades\DB::table('orders')->orderBy('id')->get())),
                'cod_accounts' => App\Models\CodAccount::count()];
        }
        $issue = App\Models\HandoverIssue::with('delivery.order')->findOrFail($message['issue_id']);
        if ($operation === 'authorize') {
            $reviewer = App\Models\LogisticsCompany::findOrFail($issue->delivery->logistics_company_id)->user;
            $view = $this->actingAs($reviewer)->get('/handover-issues/'.$issue->id)->assertOk()->inertiaProps('issue');
            $this->postJson('/handover-issues/'.$issue->id.'/review', ['decision' => 'confirm',
                'notes' => 'Independent review of the isolated synthetic handover fixture.',
                'evidence_reviewed' => true, 'expected_version' => $view['version'],
                'source_token' => $view['source_token'], 'request_token' => (string) Illuminate\Support\Str::uuid()])->assertOk();
            $method = new ReflectionMethod(Tests\Feature\Courier\RiderHandoverApiTest::class, 'authorize');
            $grant = $method->invoke($this, $issue->fresh()->load('delivery.order'), $this->holder);

            return ['grant_id' => (string) $grant->id];
        }
        if ($operation === 'receive') {
            $grant = App\Models\HandoverRecoveryGrant::where('handover_issue_id', $issue->id)->sole();
            $method = new ReflectionMethod(Tests\Feature\Courier\RiderHandoverApiTest::class, 'receipt');
            $method->invoke($this, $issue, $grant);

            return ['state' => $issue->fresh()->state];
        }
        throw new RuntimeException('Unsupported local fixture operation.');
    }

    public function requestFixture(array $message): array
    {
        // A web fixture actor must never become the next bearer request's user.
        $this->app['auth']->forgetGuards();
        $this->app['auth']->shouldUse('web');
        $files = [];
        try {
            foreach ($message['files'] as $name => $file) {
                $path = tempnam($this->sandbox.'/uploads', 'evidence-');
                file_put_contents($path, base64_decode($file['bytes'], true));
                $files[$name] = new Illuminate\Http\UploadedFile($path, $file['name'], $file['mime'], null, true);
            }
            $server = ['REMOTE_ADDR' => '127.0.0.1'];
            foreach ($message['headers'] as $name => $value) {
                $key = strtoupper(str_replace('-', '_', $name));
                $server[in_array($key, ['CONTENT_TYPE', 'CONTENT_LENGTH']) ? $key : 'HTTP_'.$key] = $value;
            }
            $response = $this->call($message['method'], $message['path'], $message['fields'], [], $files, $server,
                $message['body'] === null ? null : base64_decode($message['body'], true))->baseResponse;
            $bytes = $response instanceof Symfony\Component\HttpFoundation\BinaryFileResponse
                ? file_get_contents($response->getFile()->getPathname()) : $response->getContent();

            return ['status' => $response->getStatusCode(), 'headers' => $response->headers->all(), 'body' => base64_encode($bytes)];
        } finally {
            foreach ($files as $file) {
                @unlink($file->getPathname());
            }
        }
    }

    public function stopFixture(): void
    {
        parent::tearDown();
    }
}

$fixture = new NativeHandoverFixture('test_native_report_is_only_an_observation_and_exact_retry_reconciles_the_original_result');
$fixture->sandbox($runtime);
try {
    ob_start();
    $fixture->startFixture();
    ob_end_clean();
    fwrite(STDOUT, json_encode(['ready' => true])."\n");
    while (($line = fgets(STDIN)) !== false) {
        $message = json_decode($line, true, flags: JSON_THROW_ON_ERROR);
        ob_start();
        try {
            $result = isset($message['operation']) ? $fixture->control($message) : $fixture->requestFixture($message);
            ob_end_clean();
            fwrite(STDOUT, json_encode(['result' => $result], JSON_THROW_ON_ERROR)."\n");
        } catch (Throwable $error) {
            ob_end_clean();
            fwrite(STDERR, get_class($error).': '.$error->getMessage()."\n");
            fwrite(STDOUT, json_encode(['error' => 'The isolated kernel fixture failed; inspect its local diagnostic log.'])."\n");
        }
    }
    $fixture->stopFixture();
} catch (Throwable $error) {
    fwrite(STDERR, get_class($error).': '.$error->getMessage()."\n");
    exit(1);
}
