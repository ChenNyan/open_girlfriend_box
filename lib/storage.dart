import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Storage{
  static Storage? _instance;

  factory Storage() => _instance ?? Storage._init();

  Storage._init()  {
    _initStorage();
  }

  static late SharedPreferences _storage;

  _initStorage() async {
    try{
      _storage = await SharedPreferences.getInstance();
    } catch(e){
      _storage = await SharedPreferences.getInstance();
    }
  }

  setStorage(String key, dynamic value) async {
    await _initStorage();
    String type;
    if(value is Map || value is List) {
      type = "String";
      value = const JsonEncoder().convert(value);
    } else {
      type = value.runtimeType.toString();
    }

    switch(type){
      case "String":
        _storage.setString(key, value);
        break;
      case "int":
        _storage.setInt(key, value);
        break;
      case "double":
        _storage.setDouble(key, value);
        break;
      case "bool":
        _storage.setBool(key, value);
        break;
    }
  }

  Future<dynamic>? getStorage(String key) async {
    await _initStorage();
    dynamic value = _storage.get(key);
    if(_isJson(value)){
      return const JsonDecoder().convert(value);
    } else {
      return value;
    }
  }

  Future<bool> hasKey(String key) async {
    await _initStorage();
    return _storage.containsKey(key);
  }

  Future<bool> removeStorage(String key) async {
    await _initStorage();
    if(await hasKey(key)){
      await _storage.remove(key);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> clear() async {
    await _initStorage();
    _storage.clear();
    return true;
  }

  Future<Set<String>> getKeys() async {
    await _initStorage();
    return _storage.getKeys();
  }

  _isJson(dynamic value){
    try {
      const JsonDecoder().convert(value);
      return true;
    } catch (e) {
      return false;
    }
  }

}