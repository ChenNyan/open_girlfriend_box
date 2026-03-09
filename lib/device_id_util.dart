import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdUtil {
  static const _key = "device_uuid";

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? uuid = prefs.getString(_key);

    // 已经存在
    if (uuid != null) {
      return uuid;
    }

    // 第一次生成
    uuid = const Uuid().v4();

    await prefs.setString(_key, uuid);

    return uuid;
  }
}