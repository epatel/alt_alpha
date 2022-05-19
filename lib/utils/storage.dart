import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static Storage instance = Storage._();
  Storage._();

  late SharedPreferences _sharedPreferences;

  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _sharedPreferences.setInt('app.counter', count + 1);
  }

  int get count => _sharedPreferences.getInt('app.counter') ?? 0;
}
