part of 'plusprayer.dart';

class SetSubjectAvatarToneVariablesBuilder {
  String id;
  Optional<int> _avatarTone = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  SetSubjectAvatarToneVariablesBuilder avatarTone(int? t) {
   _avatarTone.value = t;
   return this;
  }

  SetSubjectAvatarToneVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<SetSubjectAvatarToneData> dataDeserializer = (dynamic json)  => SetSubjectAvatarToneData.fromJson(jsonDecode(json));
  Serializer<SetSubjectAvatarToneVariables> varsSerializer = (SetSubjectAvatarToneVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<SetSubjectAvatarToneData, SetSubjectAvatarToneVariables>> execute() {
    return ref().execute();
  }

  MutationRef<SetSubjectAvatarToneData, SetSubjectAvatarToneVariables> ref() {
    SetSubjectAvatarToneVariables vars= SetSubjectAvatarToneVariables(id: id,avatarTone: _avatarTone,);
    return _dataConnect.mutation("SetSubjectAvatarTone", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SetSubjectAvatarToneData {
  final int prayerSubject_updateMany;
  SetSubjectAvatarToneData.fromJson(dynamic json):
  
  prayerSubject_updateMany = nativeFromJson<int>(json['prayerSubject_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetSubjectAvatarToneData otherTyped = other as SetSubjectAvatarToneData;
    return prayerSubject_updateMany == otherTyped.prayerSubject_updateMany;
    
  }
  @override
  int get hashCode => prayerSubject_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubject_updateMany'] = nativeToJson<int>(prayerSubject_updateMany);
    return json;
  }

  SetSubjectAvatarToneData({
    required this.prayerSubject_updateMany,
  });
}

@immutable
class SetSubjectAvatarToneVariables {
  final String id;
  late final Optional<int>avatarTone;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SetSubjectAvatarToneVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    avatarTone = Optional.optional(nativeFromJson, nativeToJson);
    avatarTone.value = json['avatarTone'] == null ? null : nativeFromJson<int>(json['avatarTone']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SetSubjectAvatarToneVariables otherTyped = other as SetSubjectAvatarToneVariables;
    return id == otherTyped.id && 
    avatarTone == otherTyped.avatarTone;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, avatarTone.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(avatarTone.state == OptionalState.set) {
      json['avatarTone'] = avatarTone.toJson();
    }
    return json;
  }

  SetSubjectAvatarToneVariables({
    required this.id,
    required this.avatarTone,
  });
}

