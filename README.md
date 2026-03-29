# Uống Thuốc Thông Minh

Ứng dụng Flutter nhắc uống thuốc, quản lý thuốc, quản lý lịch uống thuốc, lưu dữ liệu cục bộ và gửi thông báo đúng giờ.

## 1. Yêu cầu môi trường

- Flutter SDK (kênh stable)
- Dart SDK (đi kèm Flutter)
- Android Studio
- VS Code + extension `Flutter` và `Dart`
- JDK 17 (Android Studio mới thường đã đi kèm)

## 2. Cài Flutter SDK

1. Tải Flutter SDK tại: https://docs.flutter.dev/get-started/install
2. Giải nén Flutter SDK.
3. Thêm thư mục `flutter/bin` vào biến môi trường `PATH`.
4. Kiểm tra:

```bash
flutter --version
flutter doctor
```

5. Chấp nhận license Android:

```bash
flutter doctor --android-licenses
```

## 3. Cài Android SDK trong Android Studio

Mở `Android Studio` -> `More Actions` -> `SDK Manager`, cài các mục sau:

- `Android SDK Platform 36` (API 36)
- `Android SDK Build-Tools`
- `Android SDK Command-line Tools (latest)`
- `Android Emulator`
- `Android SDK Platform-Tools`

Sau khi cài xong, chạy lại:

```bash
flutter doctor
```

Nếu còn lỗi Android toolchain, xử lý theo gợi ý của `flutter doctor`.

## 4. Tạo máy ảo Android API 36

1. Mở Android Studio -> `Device Manager`.
2. Chọn `Create device`.
3. Chọn model (ví dụ `Pixel 6`).
4. Ở phần `System Image`, chọn image có `API Level 36`.
5. Hoàn tất tạo máy ảo và bấm chạy máy ảo.

## 5. Chạy dự án bằng VS Code

1. Mở thư mục dự án trong VS Code.
2. Mở terminal tại thư mục gốc dự án.
3. Cài dependency:

```bash
flutter pub get
```

4. Chọn thiết bị Android ảo (API 36) ở góc dưới phải VS Code.
5. Chạy app:

```bash
flutter run
```

Hoặc bấm `F5` trong VS Code.

## 6. Build APK debug

```bash
flutter build apk --debug
```

APK sẽ nằm tại:

`build/app/outputs/flutter-apk/app-debug.apk`

## 7. Kiểm tra nhanh chức năng thông báo

1. Mở app và cấp quyền thông báo khi được hỏi.
2. Vào tab `Thuốc`, thêm một thuốc mới.
3. Vào tab `Lịch`, tạo lịch sau thời điểm hiện tại 1-2 phút.
4. Chờ đến giờ để kiểm tra thông báo hiện đúng nội dung.

Nếu không thấy thông báo:

- Kiểm tra app đang bật thông báo trong tab `Tài khoản`.
- Kiểm tra quyền thông báo của app trong cài đặt Android.
- Đảm bảo bạn tạo lịch ở thời điểm tương lai gần.

## 8. Một số lệnh hữu ích

```bash
flutter clean
flutter pub get
flutter analyze
flutter run
```
