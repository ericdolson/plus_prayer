part of 'plusprayer.dart';

class ReorderSubjectsVariablesBuilder {
  List<String> orderedIds;

  final FirebaseDataConnect _dataConnect;
  ReorderSubjectsVariablesBuilder(this._dataConnect, {required  this.orderedIds,});
  Deserializer<ReorderSubjectsData> dataDeserializer = (dynamic json)  => ReorderSubjectsData.fromJson(jsonDecode(json));
  Serializer<ReorderSubjectsVariables> varsSerializer = (ReorderSubjectsVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<ReorderSubjectsData, ReorderSubjectsVariables>> execute() {
    return ref().execute();
  }

  MutationRef<ReorderSubjectsData, ReorderSubjectsVariables> ref() {
    ReorderSubjectsVariables vars= ReorderSubjectsVariables(orderedIds: orderedIds,);
    return _dataConnect.mutation("ReorderSubjects", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class ReorderSubjectsData {
  final int? execute_;
  ReorderSubjectsData.fromJson(dynamic json):
  
  execute_ = json['_execute'] == null ? null : nativeFromJson<int>(json['_execute']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReorderSubjectsData otherTyped = other as ReorderSubjectsData;
    return execute_ == otherTyped.execute_;
    
  }
  @override
  int get hashCode => execute_.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (execute_ != null) {
      json['_execute'] = nativeToJson<int?>(execute_);
    }
    return json;
  }

  ReorderSubjectsData({
    this.execute_,
  });
}

@immutable
class ReorderSubjectsVariables {
  final List<String> orderedIds;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  ReorderSubjectsVariables.fromJson(Map<String, dynamic> json):
  
  orderedIds = (json['orderedIds'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ReorderSubjectsVariables otherTyped = other as ReorderSubjectsVariables;
    return orderedIds == otherTyped.orderedIds;
    
  }
  @override
  int get hashCode => orderedIds.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['orderedIds'] = orderedIds.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  ReorderSubjectsVariables({
    required this.orderedIds,
  });
}

