part of 'plusprayer.dart';

class PurgeSubjectVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  PurgeSubjectVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<PurgeSubjectData> dataDeserializer = (dynamic json)  => PurgeSubjectData.fromJson(jsonDecode(json));
  Serializer<PurgeSubjectVariables> varsSerializer = (PurgeSubjectVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<PurgeSubjectData, PurgeSubjectVariables>> execute() {
    return ref().execute();
  }

  MutationRef<PurgeSubjectData, PurgeSubjectVariables> ref() {
    PurgeSubjectVariables vars= PurgeSubjectVariables(id: id,);
    return _dataConnect.mutation("PurgeSubject", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class PurgeSubjectData {
  final int prayerSubject_updateMany;
  final int cascade;
  PurgeSubjectData.fromJson(dynamic json):
  
  prayerSubject_updateMany = nativeFromJson<int>(json['prayerSubject_updateMany']),
  cascade = nativeFromJson<int>(json['cascade']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final PurgeSubjectData otherTyped = other as PurgeSubjectData;
    return prayerSubject_updateMany == otherTyped.prayerSubject_updateMany && 
    cascade == otherTyped.cascade;
    
  }
  @override
  int get hashCode => Object.hashAll([prayerSubject_updateMany.hashCode, cascade.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubject_updateMany'] = nativeToJson<int>(prayerSubject_updateMany);
    json['cascade'] = nativeToJson<int>(cascade);
    return json;
  }

  PurgeSubjectData({
    required this.prayerSubject_updateMany,
    required this.cascade,
  });
}

@immutable
class PurgeSubjectVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  PurgeSubjectVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final PurgeSubjectVariables otherTyped = other as PurgeSubjectVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  PurgeSubjectVariables({
    required this.id,
  });
}

