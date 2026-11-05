part of 'plusprayer.dart';

class SearchMySubjectsVariablesBuilder {
  String query;

  final FirebaseDataConnect _dataConnect;
  SearchMySubjectsVariablesBuilder(this._dataConnect, {required  this.query,});
  Deserializer<SearchMySubjectsData> dataDeserializer = (dynamic json)  => SearchMySubjectsData.fromJson(jsonDecode(json));
  Serializer<SearchMySubjectsVariables> varsSerializer = (SearchMySubjectsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<SearchMySubjectsData, SearchMySubjectsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<SearchMySubjectsData, SearchMySubjectsVariables> ref() {
    SearchMySubjectsVariables vars= SearchMySubjectsVariables(query: query,);
    return _dataConnect.query("SearchMySubjects", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class SearchMySubjectsPrayerSubjectsSearch {
  final String id;
  final EnumValue<SubjectKind> kind;
  final String? parentId;
  final String publicName;
  final String? personalLabel;
  final EnumValue<SubjectStatus> status;
  final bool isSelf;
  SearchMySubjectsPrayerSubjectsSearch.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  parentId = json['parentId'] == null ? null : nativeFromJson<String>(json['parentId']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  status = subjectStatusDeserializer(json['status']),
  isSelf = nativeFromJson<bool>(json['isSelf']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SearchMySubjectsPrayerSubjectsSearch otherTyped = other as SearchMySubjectsPrayerSubjectsSearch;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    parentId == otherTyped.parentId && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    status == otherTyped.status && 
    isSelf == otherTyped.isSelf;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, parentId.hashCode, publicName.hashCode, personalLabel.hashCode, status.hashCode, isSelf.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    if (parentId != null) {
      json['parentId'] = nativeToJson<String?>(parentId);
    }
    json['publicName'] = nativeToJson<String>(publicName);
    if (personalLabel != null) {
      json['personalLabel'] = nativeToJson<String?>(personalLabel);
    }
    json['status'] = 
    subjectStatusSerializer(status)
    ;
    json['isSelf'] = nativeToJson<bool>(isSelf);
    return json;
  }

  SearchMySubjectsPrayerSubjectsSearch({
    required this.id,
    required this.kind,
    this.parentId,
    required this.publicName,
    this.personalLabel,
    required this.status,
    required this.isSelf,
  });
}

@immutable
class SearchMySubjectsData {
  final List<SearchMySubjectsPrayerSubjectsSearch> prayerSubjects_search;
  SearchMySubjectsData.fromJson(dynamic json):
  
  prayerSubjects_search = (json['prayerSubjects_search'] as List<dynamic>)
        .map((e) => SearchMySubjectsPrayerSubjectsSearch.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SearchMySubjectsData otherTyped = other as SearchMySubjectsData;
    return prayerSubjects_search == otherTyped.prayerSubjects_search;
    
  }
  @override
  int get hashCode => prayerSubjects_search.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubjects_search'] = prayerSubjects_search.map((e) => e.toJson()).toList();
    return json;
  }

  SearchMySubjectsData({
    required this.prayerSubjects_search,
  });
}

@immutable
class SearchMySubjectsVariables {
  final String query;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  SearchMySubjectsVariables.fromJson(Map<String, dynamic> json):
  
  query = nativeFromJson<String>(json['query']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final SearchMySubjectsVariables otherTyped = other as SearchMySubjectsVariables;
    return query == otherTyped.query;
    
  }
  @override
  int get hashCode => query.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['query'] = nativeToJson<String>(query);
    return json;
  }

  SearchMySubjectsVariables({
    required this.query,
  });
}

