/// Layout fixtures only. These are separate queue scenarios, not API resources.
enum HomePreviewQueue {
  available('Available pickups', 'Pickups are claimed by the rider.'),
  pickups('My pickups', 'The hub confirms receipt after collection.'),
  deliveries('Assigned delivery', 'Delivery work is assigned by the hub.');

  const HomePreviewQueue(this.label, this.description);
  final String label;
  final String description;
}

class HomePreviewTask {
  const HomePreviewTask({
    required this.tracking,
    required this.stage,
    required this.stop,
    required this.address,
    required this.nextStep,
  });
  final String tracking, stage, stop, address, nextStep;
}

const homePreviewTasks = <HomePreviewQueue, List<HomePreviewTask>>{
  HomePreviewQueue.available: [
    HomePreviewTask(
      tracking: 'DEMO-P1001',
      stage: 'Ready for pickup',
      stop: 'Example grocery',
      address: 'Market Street · Sample District',
      nextStep: 'Claim pickup',
    ),
    HomePreviewTask(
      tracking: 'DEMO-P1002',
      stage: 'Ready for pickup',
      stop: 'Example shop',
      address: 'Shop Street · Sample District',
      nextStep: 'Claim pickup',
    ),
  ],
  HomePreviewQueue.pickups: [
    HomePreviewTask(
      tracking: 'DEMO-P1003',
      stage: 'Collected from seller',
      stop: 'Example origin hub',
      address: 'Hub Road · Sample District',
      nextStep: 'Bring to hub and await receipt',
    ),
  ],
  HomePreviewQueue.deliveries: [
    HomePreviewTask(
      tracking: 'DEMO-D2001',
      stage: 'Assigned by destination hub',
      stop: 'Example destination hub',
      address: 'Destination Road · Sample District',
      nextStep: 'Scan out at the assigned hub',
    ),
  ],
};
