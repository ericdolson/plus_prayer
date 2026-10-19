part of 'plusprayer.dart';

class UpdatePrayerNoteVariablesBuilder {
  String id;
  Optional<String> _note = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  UpdatePrayerNoteVariablesBuilder note(String? t) {
   _note.value = t;
   return this;
  }

  UpdatePrayerNoteVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<UpdatePrayerNoteData> dataDeserializer = (dynamic json)  => UpdatePrayerNoteData.fromJson(jsonDecode(json));
  Serializer<UpdatePrayerNoteVariables> varsSerializer = (UpdatePrayerNoteVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdatePrayerNoteData, UpdatePrayerNoteVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdatePrayerNoteData, UpdatePrayerNoteVariables> ref() {
    UpdatePrayerNoteVariables vars= UpdatePrayerNoteVariables(id: id,note: _note,);
    return _dataConnect.mutation("UpdatePrayerNote", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdatePrayerNoteData {
  final int prayer_updateMany;
  UpdatePrayerNoteData.fromJson(dynamic json):
  
  prayer_updateMany = nativeFromJson<int>(json['prayer_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePrayerNoteData otherTyped = other as UpdatePrayerNoteData;
    return prayer_updateMany == otherTyped.prayer_updateMany;
    
  }
  @override
  int get hashCode => prayer_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayer_updateMany'] = nativeToJson<int>(prayer_updateMany);
    return json;
  }

  UpdatePrayerNoteData({
    required this.prayer_updateMany,
  });
}

@immutable
class UpdatePrayerNoteVariables {
  final String id;
  late final Optional<String>note;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdatePrayerNoteVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    note = Optional.optional(nativeFromJson, nativeToJson);
    note.value = json['note'] == null ? null : nativeFromJson<String>(json['note']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdatePrayerNoteVariables otherTyped = other as UpdatePrayerNoteVariables;
    return id == otherTyped.id && 
    note == otherTyped.note;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, note.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(note.state == OptionalState.set) {
      json['note'] = note.toJson();
    }
    return json;
  }

  UpdatePrayerNoteVariables({
    required this.id,
    required this.note,
  });
}

