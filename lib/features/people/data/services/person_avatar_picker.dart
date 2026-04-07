import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class PersonAvatarPicker {
  PersonAvatarPicker({ImagePicker? imagePicker, ImageCropper? imageCropper})
    : _imagePicker = imagePicker ?? ImagePicker(),
      _imageCropper = imageCropper ?? ImageCropper();

  final ImagePicker _imagePicker;
  final ImageCropper _imageCropper;

  Future<String?> pickAndCropAvatar({required String toolbarTitle}) async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      requestFullMetadata: false,
    );
    if (pickedImage == null) {
      return null;
    }

    final croppedImage = await _imageCropper.cropImage(
      sourcePath: pickedImage.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      maxWidth: 1024,
      maxHeight: 1024,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: toolbarTitle,
          lockAspectRatio: true,
          hideBottomControls: false,
          cropStyle: CropStyle.circle,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: toolbarTitle,
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
          rotateClockwiseButtonHidden: false,
          cropStyle: CropStyle.circle,
        ),
      ],
    );

    return croppedImage?.path;
  }
}
