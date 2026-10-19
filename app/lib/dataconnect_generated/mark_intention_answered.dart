part of 'plusprayer.dart';

class MarkIntentionAnsweredVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  MarkIntentionAnsweredVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<MarkIntentionAnsweredData> dataDeserializer = (dynamic json)  => MarkIntentionAnsweredData.fromJson(jsonDecode(json));
  Serializer<MarkIntentionAnsweredVariables> varsSerializer = (MarkIntentionAnsweredVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<MarkIntentionAnsweredData, MarkIntentionAnsweredVariables>> execute() {
    return ref().execute();
  }

  MutationRef<MarkIntentionAnsweredData, MarkIntentionAnsweredVariables> ref() {
    MarkIntentionAnsweredVariables vars= MarkIntentionAnsweredVariables(id: id,);
    return _dataConnect.mutation("MarkIntentionAnswered", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class MarkIntentionAnsweredData {
  final int prayerSubject_updateMany;
  MarkIntentionAnsweredData.fromJson(dynamic json):
  
  prayerSubject_updateMany = nativeFromJson<int>(json['prayerSubject_updateMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkIntentionAnsweredData otherTyped = other as MarkIntentionAnsweredData;
    return prayerSubject_updateMany == otherTyped.prayerSubject_updateMany;
    
  }
  @override
  int get hashCode => prayerSubject_updateMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubject_updateMany'] = nativeToJson<int>(prayerSubject_updateMany);
    return json;
  }

  MarkIntentionAnsweredData({
    required this.prayerSubject_updateMany,
  });
}

@immutable
class MarkIntentionAnsweredVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  MarkIntentionAnsweredVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final MarkIntentionAnsweredVariables otherTyped = other as MarkIntentionAnsweredVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  MarkIntentionAnsweredVariables({
    required this.id,
  });
}

