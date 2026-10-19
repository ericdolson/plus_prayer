part of 'plusprayer.dart';

class GetMyRemindersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyRemindersVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyRemindersData> dataDeserializer = (dynamic json)  => GetMyRemindersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyRemindersData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyRemindersData, void> ref() {
    
    return _dataConnect.query("GetMyReminders", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyRemindersReminderPreferences {
  final String id;
  final EnumValue<ReminderSlot> slot;
  final bool enabled;
  final String localTime;
  final String? label;
  GetMyRemindersReminderPreferences.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  slot = reminderSlotDeserializer(json['slot']),
  enabled = nativeFromJson<bool>(json['enabled']),
  localTime = nativeFromJson<String>(json['localTime']),
  label = json['label'] == null ? null : nativeFromJson<String>(json['label']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyRemindersReminderPreferences otherTyped = other as GetMyRemindersReminderPreferences;
    return id == otherTyped.id && 
    slot == otherTyped.slot && 
    enabled == otherTyped.enabled && 
    localTime == otherTyped.localTime && 
    label == otherTyped.label;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, slot.hashCode, enabled.hashCode, localTime.hashCode, label.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['slot'] = 
    reminderSlotSerializer(slot)
    ;
    json['enabled'] = nativeToJson<bool>(enabled);
    json['localTime'] = nativeToJson<String>(localTime);
    if (label != null) {
      json['label'] = nativeToJson<String?>(label);
    }
    return json;
  }

  GetMyRemindersReminderPreferences({
    required this.id,
    required this.slot,
    required this.enabled,
    required this.localTime,
    this.label,
  });
}

@immutable
class GetMyRemindersData {
  final List<GetMyRemindersReminderPreferences> reminderPreferences;
  GetMyRemindersData.fromJson(dynamic json):
  
  reminderPreferences = (json['reminderPreferences'] as List<dynamic>)
        .map((e) => GetMyRemindersReminderPreferences.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyRemindersData otherTyped = other as GetMyRemindersData;
    return reminderPreferences == otherTyped.reminderPreferences;
    
  }
  @override
  int get hashCode => reminderPreferences.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['reminderPreferences'] = reminderPreferences.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyRemindersData({
    required this.reminderPreferences,
  });
}

