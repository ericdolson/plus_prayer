part of 'plusprayer.dart';

class UpdateReminderVariablesBuilder {
  String id;
  Optional<bool> _enabled = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _localTime = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _label = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdateReminderVariablesBuilder enabled(bool? t) {
   _enabled.value = t;
   return this;
  }
  UpdateReminderVariablesBuilder localTime(String? t) {
   _localTime.value = t;
   return this;
  }
  UpdateReminderVariablesBuilder label(String? t) {
   _label.value = t;
   return this;
  }

  UpdateReminderVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdateReminderData> dataDeserializer = (dynamic json)  => UpdateReminderData.fromJson(jsonDecode(json));
  Serializer<UpdateReminderVariables> varsSerializer = (UpdateReminderVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateReminderData, UpdateReminderVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateReminderData, UpdateReminderVariables> ref() {
    UpdateReminderVariables vars= UpdateReminderVariables(id: id,enabled: _enabled,localTime: _localTime,label: _label,);
    return _dataConnect.mutation("UpdateReminder", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateReminderData {
  final int reminderPreference_updateMany;
  UpdateReminderData.fromJson(dynamic json):
  
  reminderPreference_updateMany = nativeFromJson<int>(json['reminderPreference_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReminderData otherTyped = other as UpdateReminderData;
    return reminderPreference_updateMany == otherTyped.reminderPreference_updateMany;
    
  }
  @override
  int get hashCode => reminderPreference_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['reminderPreference_updateMany'] = nativeToJson<int>(reminderPreference_updateMany);
    return json;
  }

  UpdateReminderData({
    required this.reminderPreference_updateMany,
  });
}

@immutable
class UpdateReminderVariables {
  final String id;
  late final Optional<bool>enabled;
  late final Optional<String>localTime;
  late final Optional<String>label;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateReminderVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    enabled = Optional.optional(nativeFromJson, nativeToJson);
    enabled.value = json['enabled'] == null ? null : nativeFromJson<bool>(json['enabled']);
  
  
    localTime = Optional.optional(nativeFromJson, nativeToJson);
    localTime.value = json['localTime'] == null ? null : nativeFromJson<String>(json['localTime']);
  
  
    label = Optional.optional(nativeFromJson, nativeToJson);
    label.value = json['label'] == null ? null : nativeFromJson<String>(json['label']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateReminderVariables otherTyped = other as UpdateReminderVariables;
    return id == otherTyped.id && 
    enabled == otherTyped.enabled && 
    localTime == otherTyped.localTime && 
    label == otherTyped.label;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, enabled.hashCode, localTime.hashCode, label.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(enabled.state == OptionalState.set) {
      json['enabled'] = enabled.toJson();
    }
    if(localTime.state == OptionalState.set) {
      json['localTime'] = localTime.toJson();
    }
    if(label.state == OptionalState.set) {
      json['label'] = label.toJson();
    }
    return json;
  }

  UpdateReminderVariables({
    required this.id,
    required this.enabled,
    required this.localTime,
    required this.label,
  });
}

