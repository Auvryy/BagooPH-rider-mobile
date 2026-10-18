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

class NativeParcelFixture extends Tests\Feature\Courier\RiderParcelApiTest
{
    private array $parcels = [];
    private App\Models\User $holder;
    private App\Models\User $other;
    private string $sandbox;

    public function sandbox(string $path): void { $this->sandbox = $path; }

    public function createApplication()
    {
        fwrite(STDERR, "fixture: bootstrap start\n");
        $app = parent::createApplication();
        fwrite(STDERR, "fixture: bootstrap complete\n");
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
        fwrite(STDERR, "fixture: migration/setup start\n");
        parent::setUp();
        $this->withoutVite();
        fwrite(STDERR, "fixture: migration/setup complete\n");
        $this->assertSame(':memory:', Illuminate\Support\Facades\DB::connection()->getDatabaseName());
        Illuminate\Support\Facades\Storage::fake('local');
        Illuminate\Support\Facades\Storage::fake('public');
        $this->holder = $this->createApprovedUser('courier', [
            'email' => 'parcel-rider@example.test', 'password' => 'Local-Parcel-123!']);
        // Prepare phases sequentially. Active final-mile work correctly blocks
        // a new pickup; the fixture must honour that rule too.
        $pickup = $this->newFlowOrder('ready_for_pickup', ['shipping_city' => 'Los Baños'])->delivery;
        fwrite(STDERR, "fixture: ready pickup created\n");
        $this->flowRider($pickup->originBayanHub, $this->holder);
        $this->parcels = ['pickup' => $pickup];
        $this->other = $this->flowRider($pickup->originBayanHub, $this->createApprovedUser('courier', [
            'email' => 'other-parcel-rider@example.test', 'password' => 'Local-Other-123!']));
    }

    public function control(array $message): array
    {
        $operation = $message['operation'];
        if ($operation === 'info') {
            return ['database' => ':memory:', 'email' => $this->holder->email, 'password' => 'Local-Parcel-123!',
                'other_email' => $this->other->email, 'other_password' => 'Local-Other-123!',
                'parcels' => array_map(fn ($p) => ['id' => (string) $p->id, 'barcode' => $p->tracking_number], $this->parcels)];
        }
        if ($operation === 'counts') {
            return ['commands' => App\Models\RiderCommand::count(),
                'parcels' => array_map(fn ($p) => ['stage' => $p->fresh()->status,
                    'order' => $p->order->fresh()->status, 'payment' => $p->order->fresh()->payment_status,
                    'custody' => App\Models\DeliveryCheckpoint::lastCustody($p->fresh()),
                    'assignments' => $p->checkpoints()->whereIn('checkpoint_type', ['assigned_pickup', 'assigned_to_rider'])->count(),
                    'picked_up' => $p->checkpoints()->where('checkpoint_type', 'picked_up')->count(),
                    'departed' => $p->checkpoints()->where('checkpoint_type', 'out_for_delivery')->count(),
                    'delivered' => $p->checkpoints()->where('checkpoint_type', 'delivered')->count(),
                    'attempts' => App\Models\DeliveryAttempt::where('delivery_id', $p->id)->count()], $this->parcels),
                'cash' => App\Models\CodAccount::get()->map(fn ($cash) => [
                    'delivery_id' => (string) $cash->delivery_id, 'expected_cents' => (string) $cash->expected_cents,
                    'balance_cents' => (string) $cash->state['balances']['rider:'.$this->holder->id],
                    'events' => $cash->events()->count(), 'reconciled' => $cash->reconciled_at !== null])->all(),
                'public_proofs' => Illuminate\Support\Facades\Storage::disk('public')->allFiles('delivery-proofs')];
        }
        if ($operation === 'message_reply') {
            $phase = $message['phase'];
            $this->assertContains($phase, ['pickup', 'final_mile']);
            $p = $this->parcels[$phase === 'pickup' ? 'pickup' : 'delivery']->fresh();
            $sender = $phase === 'pickup' ? $p->order->items->first()->product->shop->user : $p->order->buyer;
            // Reply through the actual owning seller/buyer action, never by
            // changing the messages table or forging a Rider participant.
            $reply = $this->actingAs($sender)->postJson(route('chat.send'), [
                'receiver_id' => $this->holder->id, 'order_id' => $p->order_id,
                'message' => $message['text'],
            ])->assertOk()->json('message');
            return ['id' => (string) $reply['id'], 'sender_id' => (string) $sender->id];
        }
        if ($operation === 'messages_snapshot') {
            $state = [];
            foreach (['pickup', 'delivery'] as $kind) {
                if (! isset($this->parcels[$kind])) continue;
                $p = $this->parcels[$kind]->fresh();
                $participant = $kind === 'pickup' ? $p->order->items->first()->product->shop->user : $p->order->buyer;
                $rows = App\Models\Message::where('order_id', $p->order_id)
                    ->where(fn ($query) => $query->where('sender_id', $this->holder->id)->orWhere('receiver_id', $this->holder->id))
                    ->orderBy('id')->get();
                // These owning inbox GETs only inspect state; ChatController's
                // separate getMessages endpoint would acknowledge messages.
                $path = $kind === 'pickup' ? '/seller/messages' : '/buyer/messages';
                $this->actingAs($participant)->get($path)->assertOk()->assertInertia(
                    fn (Inertia\Testing\AssertableInertia $page) => $page
                        ->component($kind === 'pickup' ? 'Seller/Messages' : 'Buyer/Messages')
                        ->where('conversations', function ($conversations) use ($rows) {
                            $visible = collect($conversations)->flatMap(fn ($thread) => $thread['messages'])->pluck('id');
                            return $rows->every(fn ($row) => $visible->contains($row->id));
                        })
                );
                $state[$kind] = ['participant_id' => (string) $participant->id, 'stage' => $p->status,
                    'messages' => $rows->map(fn ($row) => ['id' => (string) $row->id,
                        'sender_id' => (string) $row->sender_id, 'receiver_id' => (string) $row->receiver_id,
                        'text' => $row->message, 'is_read' => (bool) $row->is_read])->all()];
            }
            return ['parcels' => $state,
                'sends' => App\Models\RiderCommand::where('action', 'message.send')->count(),
                'reads' => App\Models\RiderCommand::where('action', 'message.read')->count(),
                'outcomes' => App\Models\DeliveryCheckpoint::where('checkpoint_type', 'delivered')->count()];
        }
        if (in_array($operation, ['prepare_delivery', 'prepare_failure'], true)) {
            $kind = $operation === 'prepare_delivery' ? 'delivery' : 'failure';
            $this->parcels[$kind] ??= $this->flowDelivery(
                $this->newFlowOrder('placed', ['shipping_city' => 'Los Baños']), 'assigned_to_rider', $this->holder);
            $p = $this->parcels[$kind];
            return ['parcel' => ['id' => (string) $p->id, 'barcode' => $p->tracking_number]];
        }
        if ($operation === 'receive_pickup') {
            $p = $this->parcels['pickup'];
            $this->confirmFlowScan($p, $p->originBayanHub, 'RECEIVE_FROM_PICKUP_RIDER');
            return ['stage' => $p->fresh()->status];
        }
        if ($operation === 'receive_failure') {
            $this->receiveFailureFlow($this->parcels['failure']);
            return ['received' => true];
        }
        if ($operation === 'buyer_receive') {
            $p = $this->parcels['delivery'];
            $this->actingAs($p->order->buyer)->post('/buyer/orders/'.$p->order_id.'/confirm')->assertSessionHas('success');
            return ['order' => $p->order->fresh()->status];
        }
        if ($operation === 'reassign_retry') {
            $p = $this->parcels['failure']->fresh();
            $hub = $p->destinationBayanHub;
            $attempt = App\Models\DeliveryAttempt::where('delivery_id', $p->id)->sole();
            $this->actingAs($hub->company->user)->post(route('hub.recovery.retry', $p), [
                'retry_at' => now('Asia/Manila')->addMinutes(5)->format('Y-m-d\TH:i'),
                'notes' => 'Isolated software test buyer confirmed the same saved destination.',
                'request_token' => (string) Illuminate\Support\Str::uuid(), 'attempt_reference' => $attempt->reference,
            ])->assertSessionHas('success');
            $this->travel(6)->minutes();
            $handler = $this->flowHandler($hub);
            $this->actingAs($handler)->postJson(route('hub.scan'), ['barcode' => $p->tracking_number, 'hub_id' => $hub->id,
                'mode' => 'confirm', 'action' => 'RELEASE_APPROVED_RETRY', 'expected_status' => 'delivery_failed',
                'attempt_reference' => $attempt->reference])->assertOk();
            $this->postJson(route('hub.sort'), ['delivery_id' => $p->id, 'barangay' => $p->order->destination_barangay])->assertOk();
            $this->postJson(route('hub.assignRider', $p), ['rider_id' => $this->other->id])->assertOk();
            return ['stage' => $p->fresh()->status];
        }
        if ($operation === 'change_proof') {
            $p = $this->parcels['delivery']->fresh();
            // A second genuine PNG, rather than invalid text disguised as an
            // image, exercises the accepted-hash mismatch independently of GD.
            $different = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAX+XDSwAAAABJRU5ErkJggg==');
            Illuminate\Support\Facades\Storage::disk('local')->put($p->proof_image, $different);
            return ['changed' => true];
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
            if ($response instanceof Symfony\Component\HttpFoundation\BinaryFileResponse) {
                $bytes = file_get_contents($response->getFile()->getPathname());
            } elseif ($response instanceof Symfony\Component\HttpFoundation\StreamedResponse) {
                ob_start();
                $response->sendContent();
                $bytes = ob_get_clean();
            } else {
                $bytes = $response->getContent();
            }

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

$fixture = new NativeParcelFixture('test_native_departure_and_private_delivery_record_real_cash_without_buyer_completion');
$fixture->sandbox($runtime);
try {
    ob_start();
    $fixture->startFixture();
    ob_end_clean();
    fwrite(STDOUT, json_encode(['ready' => true])."\n");
    // Node uses a socket for child stdin. Its default idle timeout can elapse
    // while Flutter compiles; request deadlines are enforced by the bridge.
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
            fwrite(STDOUT, json_encode(['error' => 'The isolated kernel fixture failed; inspect its local diagnostic log.'])."\n");
        }
    }
    $fixture->stopFixture();
} catch (Throwable $error) {
    fwrite(STDERR, get_class($error).': '.$error->getMessage()."\n".$error->getTraceAsString()."\n");
    exit(1);
}
