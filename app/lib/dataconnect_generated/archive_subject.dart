part of 'plusprayer.dart';

class ArchiveSubjectVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  ArchiveSubjectVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<ArchiveSubjectData> dataDeserializer = (dynamic json)  => ArchiveSubjectData.fromJson(jsonDecode(json));
  Serializer<ArchiveSubjectVariables> varsSerializer = (ArchiveSubjectVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ArchiveSubjectData, ArchiveSubjectVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ArchiveSubjectData, ArchiveSubjectVariables> ref() {
    ArchiveSubjectVariables vars= ArchiveSubjectVariables(id: id,);
    return _dataConnect.mutation("ArchiveSubject", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ArchiveSubjectData {
  final int prayerSubject_updateMany;
  final int cascade;
  ArchiveSubjectData.fromJson(dynamic json):
  
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

    final ArchiveSubjectData otherTyped = other as ArchiveSubjectData;
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

  ArchiveSubjectData({
    required this.prayerSubject_updateMany,
    required this.cascade,
  });
}

@immutable
class ArchiveSubjectVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ArchiveSubjectVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ArchiveSubjectVariables otherTyped = other as ArchiveSubjectVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  ArchiveSubjectVariables({
    required this.id,
  });
}

