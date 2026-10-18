import 'package:bagoo_rider_mobile/features/parcels/data/parcel_photo_service.dart';
import 'package:image_picker/image_picker.dart';

import 'parcel_support.dart';

class TestParcelPhotoPicker implements ParcelPhotoPicker {
  TestParcelPhotoPicker({
    this.supportsCamera = false,
    this.recoversLostData = false,
  });
  @override
  final bool supportsCamera;
  @override
  final bool recoversLostData;
  int recoverCalls = 0, chooseCalls = 0;
  List<XFile> lost = [];
  Future<XFile?> Function()? select;
  @override
  Future<XFile?> choose({required bool camera}) async {
    chooseCalls++;
    return select == null
        ? XFile.fromData(
            parcelTestPng(),
            path: 'software-test-proof.png',
            mimeType: 'image/png',
          )
        : select!();
  }

  @override
  Future<List<XFile>> recover() async {
    recoverCalls++;
    return lost;
  }
}
