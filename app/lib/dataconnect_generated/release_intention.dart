part of 'plusprayer.dart';

class ReleaseIntentionVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  ReleaseIntentionVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<ReleaseIntentionData> dataDeserializer = (dynamic json)  => ReleaseIntentionData.fromJson(jsonDecode(json));
  Serializer<ReleaseIntentionVariables> varsSerializer = (ReleaseIntentionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ReleaseIntentionData, ReleaseIntentionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ReleaseIntentionData, ReleaseIntentionVariables> ref() {
    ReleaseIntentionVariables vars= ReleaseIntentionVariables(id: id,);
    return _dataConnect.mutation("ReleaseIntention", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ReleaseIntentionData {
  final int prayerSubject_updateMany;
  ReleaseIntentionData.fromJson(dynamic json):
  
  prayerSubject_updateMany = nativeFromJson<int>(json['prayerSubject_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReleaseIntentionData otherTyped = other as ReleaseIntentionData;
    return prayerSubject_updateMany == otherTyped.prayerSubject_updateMany;
    
  }
  @override
  int get hashCode => prayerSubject_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubject_updateMany'] = nativeToJson<int>(prayerSubject_updateMany);
    return json;
  }

  ReleaseIntentionData({
    required this.prayerSubject_updateMany,
  });
}

@immutable
class ReleaseIntentionVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ReleaseIntentionVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReleaseIntentionVariables otherTyped = other as ReleaseIntentionVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ReleaseIntentionVariables({
    required this.id,
  });
}

