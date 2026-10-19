part of 'plusprayer.dart';

class UpdateMySettingsVariablesBuilder {
  Optional<String> _locale = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _timezone = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _listLiveOptIn = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _showNamesInNotifications = Optional.optional(nativeFromJson, nativeToJson);
  Optional<bool> _graceOffersEnabled = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  UpdateMySettingsVariablesBuilder locale(String? t) {
   _locale.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder timezone(String? t) {
   _timezone.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder listLiveOptIn(bool? t) {
   _listLiveOptIn.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder showNamesInNotifications(bool? t) {
   _showNamesInNotifications.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder graceOffersEnabled(bool? t) {
   _graceOffersEnabled.value = t;
   return this;
  }

  UpdateMySettingsVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateMySettingsData> dataDeserializer = (dynamic json)  => UpdateMySettingsData.fromJson(jsonDecode(json));
  Serializer<UpdateMySettingsVariables> varsSerializer = (UpdateMySettingsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateMySettingsData, UpdateMySettingsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateMySettingsData, UpdateMySettingsVariables> ref() {
    UpdateMySettingsVariables vars= UpdateMySettingsVariables(locale: _locale,timezone: _timezone,listLiveOptIn: _listLiveOptIn,showNamesInNotifications: _showNamesInNotifications,graceOffersEnabled: _graceOffersEnabled,);
    return _dataConnect.mutation("UpdateMySettings", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateMySettingsUserUpdate {
  final String id;
  UpdateMySettingsUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMySettingsUserUpdate otherTyped = other as UpdateMySettingsUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateMySettingsUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateMySettingsData {
  final UpdateMySettingsUserUpdate? user_update;
  UpdateMySettingsData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateMySettingsUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMySettingsData otherTyped = other as UpdateMySettingsData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateMySettingsData({
    this.user_update,
  });
}

@immutable
class UpdateMySettingsVariables {
  late final Optional<String>locale;
  late final Optional<String>timezone;
  late final Optional<bool>listLiveOptIn;
  late final Optional<bool>showNamesInNotifications;
  late final Optional<bool>graceOffersEnabled;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateMySettingsVariables.fromJson(Map<String, dynamic> json) {
  
  
    locale = Optional.optional(nativeFromJson, nativeToJson);
    locale.value = json['locale'] == null ? null : nativeFromJson<String>(json['locale']);
  
  
    timezone = Optional.optional(nativeFromJson, nativeToJson);
    timezone.value = json['timezone'] == null ? null : nativeFromJson<String>(json['timezone']);
  
  
    listLiveOptIn = Optional.optional(nativeFromJson, nativeToJson);
    listLiveOptIn.value = json['listLiveOptIn'] == null ? null : nativeFromJson<bool>(json['listLiveOptIn']);
  
  
    showNamesInNotifications = Optional.optional(nativeFromJson, nativeToJson);
    showNamesInNotifications.value = json['showNamesInNotifications'] == null ? null : nativeFromJson<bool>(json['showNamesInNotifications']);
  
  
    graceOffersEnabled = Optional.optional(nativeFromJson, nativeToJson);
    graceOffersEnabled.value = json['graceOffersEnabled'] == null ? null : nativeFromJson<bool>(json['graceOffersEnabled']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateMySettingsVariables otherTyped = other as UpdateMySettingsVariables;
    return locale == otherTyped.locale && 
    timezone == otherTyped.timezone && 
    listLiveOptIn == otherTyped.listLiveOptIn && 
    showNamesInNotifications == otherTyped.showNamesInNotifications && 
    graceOffersEnabled == otherTyped.graceOffersEnabled;
    
  }
  @override
  int get hashCode => Object.hashAll([locale.hashCode, timezone.hashCode, listLiveOptIn.hashCode, showNamesInNotifications.hashCode, graceOffersEnabled.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(locale.state == OptionalState.set) {
      json['locale'] = locale.toJson();
    }
    if(timezone.state == OptionalState.set) {
      json['timezone'] = timezone.toJson();
    }
    if(listLiveOptIn.state == OptionalState.set) {
      json['listLiveOptIn'] = listLiveOptIn.toJson();
    }
    if(showNamesInNotifications.state == OptionalState.set) {
      json['showNamesInNotifications'] = showNamesInNotifications.toJson();
    }
    if(graceOffersEnabled.state == OptionalState.set) {
      json['graceOffersEnabled'] = graceOffersEnabled.toJson();
    }
    return json;
  }

  UpdateMySettingsVariables({
    required this.locale,
    required this.timezone,
    required this.listLiveOptIn,
    required this.showNamesInNotifications,
    required this.graceOffersEnabled,
  });
}

