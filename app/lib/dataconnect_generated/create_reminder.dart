part of 'plusprayer.dart';

class CreateReminderVariablesBuilder {
  ReminderSlot slot;
  Optional<bool> _enabled = Optional.optional(nativeFromJson, nativeToJson);
  String localTime;
  Optional<String> _label = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateReminderVariablesBuilder enabled(bool? t) {
   _enabled.value = t;
   return this;
  }
  CreateReminderVariablesBuilder label(String? t) {
   _label.value = t;
   return this;
  }

  CreateReminderVariablesBuilder(this._dataConnect, {required  this.slot,required  this.localTime,});
  Deserializer<CreateReminderData> dataDeserializer = (dynamic json)  => CreateReminderData.fromJson(jsonDecode(json));
  Serializer<CreateReminderVariables> varsSerializer = (CreateReminderVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateReminderData, CreateReminderVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateReminderData, CreateReminderVariables> ref() {
    CreateReminderVariables vars= CreateReminderVariables(slot: slot,enabled: _enabled,localTime: localTime,label: _label,);
    return _dataConnect.mutation("CreateReminder", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateReminderReminderPreferenceInsert {
  final String id;
  CreateReminderReminderPreferenceInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReminderReminderPreferenceInsert otherTyped = other as CreateReminderReminderPreferenceInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateReminderReminderPreferenceInsert({
    required this.id,
  });
}

@immutable
class CreateReminderData {
  final CreateReminderReminderPreferenceInsert reminderPreference_insert;
  CreateReminderData.fromJson(dynamic json):
  
  reminderPreference_insert = CreateReminderReminderPreferenceInsert.fromJson(json['reminderPreference_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateReminderData otherTyped = other as CreateReminderData;
    return reminderPreference_insert == otherTyped.reminderPreference_insert;
    
  }
  @override
  int get hashCode => reminderPreference_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['reminderPreference_insert'] = reminderPreference_insert.toJson();
    return json;
  }

  CreateReminderData({
    required this.reminderPreference_insert,
  });
}

@immutable
class CreateReminderVariables {
  final ReminderSlot slot;
  late final Optional<bool>enabled;
  final String localTime;
  late final Optional<String>label;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateReminderVariables.fromJson(Map<String, dynamic> json):
  
  slot = ReminderSlot.values.byName(json['slot']),
  localTime = nativeFromJson<String>(json['localTime']) {
  
  
  
    enabled = Optional.optional(nativeFromJson, nativeToJson);
    enabled.value = json['enabled'] == null ? null : nativeFromJson<bool>(json['enabled']);
  
  
  
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

    final CreateReminderVariables otherTyped = other as CreateReminderVariables;
    return slot == otherTyped.slot && 
    enabled == otherTyped.enabled && 
    localTime == otherTyped.localTime && 
    label == otherTyped.label;
    
  }
  @override
  int get hashCode => Object.hashAll([slot.hashCode, enabled.hashCode, localTime.hashCode, label.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['slot'] = 
    slot.name
    ;
    if(enabled.state == OptionalState.set) {
      json['enabled'] = enabled.toJson();
    }
    json['localTime'] = nativeToJson<String>(localTime);
    if(label.state == OptionalState.set) {
      json['label'] = label.toJson();
    }
    return json;
  }

  CreateReminderVariables({
    required this.slot,
    required this.enabled,
    required this.localTime,
    required this.label,
  });
}

