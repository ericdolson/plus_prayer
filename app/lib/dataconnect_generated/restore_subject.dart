part of 'plusprayer.dart';

class RestoreSubjectVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  RestoreSubjectVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<RestoreSubjectData> dataDeserializer = (dynamic json)  => RestoreSubjectData.fromJson(jsonDecode(json));
  Serializer<RestoreSubjectVariables> varsSerializer = (RestoreSubjectVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<RestoreSubjectData, RestoreSubjectVariables>> execute() {
    return ref().execute();
  }

  MutationRef<RestoreSubjectData, RestoreSubjectVariables> ref() {
    RestoreSubjectVariables vars= RestoreSubjectVariables(id: id,);
    return _dataConnect.mutation("RestoreSubject", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class RestoreSubjectData {
  final int prayerSubject_updateMany;
  final int cascade;
  RestoreSubjectData.fromJson(dynamic json):
  
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

    final RestoreSubjectData otherTyped = other as RestoreSubjectData;
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

  RestoreSubjectData({
    required this.prayerSubject_updateMany,
    required this.cascade,
  });
}

@immutable
class RestoreSubjectVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  RestoreSubjectVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final RestoreSubjectVariables otherTyped = other as RestoreSubjectVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  RestoreSubjectVariables({
    required this.id,
  });
}

