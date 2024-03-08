class Config {



  String appName = 'AbartFoods';
  String androidPackageName = 'com.mstoreapp.ionic1650429742784';
  String iosPackageName = 'com.mstoreapp.ionic1650429742784';

  String url = 'https://abartfoods.com';
  String consumerKey = 'ck_09292a5dc287bf9c0f35453f474dbca448aa14d3';
  String consumerSecret = 'cs_1f96f878865613993f003add88aac040e6ab5deb';
  String mapApiKey = 'AIzaSyA1xvJetwlJ3xO_g3IHT7CphMLlEYJUCkM';

  static Config _singleton = new Config._internal();

  factory Config() {
    return _singleton;
  }

  Config._internal();

  Map<String, dynamic> appConfig = Map<String, dynamic>();

  Config loadFromMap(Map<String, dynamic> map) {
    appConfig.addAll(map);
    return _singleton;
  }

  dynamic get(String key) => appConfig[key];

  bool getBool(String key) => appConfig[key];

  int getInt(String key) => appConfig[key];

  double getDouble(String key) => appConfig[key];

  String getString(String key) => appConfig[key];

  void clear() => appConfig.clear();

  @Deprecated("use updateValue instead")
  void setValue(key, value) => value.runtimeType != appConfig[key].runtimeType
      ? throw ("wrong type")
      : appConfig.update(key, (dynamic) => value);

  void updateValue(String key, dynamic value) {
    if (appConfig[key] != null &&
        value.runtimeType != appConfig[key].runtimeType) {
      throw ("The persistent type of ${appConfig[key].runtimeType} does not match the given type ${value.runtimeType}");
    }
    appConfig.update(key, (dynamic) => value);
  }

  void addValue(String key, dynamic value) =>
      appConfig.putIfAbsent(key, () => value);

  add(Map<String, dynamic> map) => appConfig.addAll(map);

}