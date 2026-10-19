part of 'plusprayer.dart';

class GetMyArchivedSubjectsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyArchivedSubjectsVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyArchivedSubjectsData> dataDeserializer = (dynamic json)  => GetMyArchivedSubjectsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyArchivedSubjectsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyArchivedSubjectsData, void> ref() {
    
    return _dataConnect.query("GetMyArchivedSubjects", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyArchivedSubjectsPrayerSubjects {
  final String id;
  final EnumValue<SubjectKind> kind;
  final GetMyArchivedSubjectsPrayerSubjectsParent? parent;
  final String publicName;
  final String? personalLabel;
  final EnumValue<SubjectResolution>? resolution;
  final Timestamp? resolvedAt;
  final bool archivedByCascade;
  GetMyArchivedSubjectsPrayerSubjects.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  parent = json['parent'] == null ? null : GetMyArchivedSubjectsPrayerSubjectsParent.fromJson(json['parent']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  resolution = json['resolution'] == null ? null : subjectResolutionDeserializer(json['resolution']),
  resolvedAt = json['resolvedAt'] == null ? null : Timestamp.fromJson(json['resolvedAt']),
  archivedByCascade = nativeFromJson<bool>(json['archivedByCascade']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyArchivedSubjectsPrayerSubjects otherTyped = other as GetMyArchivedSubjectsPrayerSubjects;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    parent == otherTyped.parent && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    resolution == otherTyped.resolution && 
    resolvedAt == otherTyped.resolvedAt && 
    archivedByCascade == otherTyped.archivedByCascade;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, parent.hashCode, publicName.hashCode, personalLabel.hashCode, resolution.hashCode, resolvedAt.hashCode, archivedByCascade.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    if (parent != null) {
      json['parent'] = parent!.toJson();
    }
    json['publicName'] = nativeToJson<String>(publicName);
    if (personalLabel != null) {
      json['personalLabel'] = nativeToJson<String?>(personalLabel);
    }
    if (resolution != null) {
      json['resolution'] = 
    subjectResolutionSerializer(resolution!)
    ;
    }
    if (resolvedAt != null) {
      json['resolvedAt'] = resolvedAt!.toJson();
    }
    json['archivedByCascade'] = nativeToJson<bool>(archivedByCascade);
    return json;
  }

  GetMyArchivedSubjectsPrayerSubjects({
    required this.id,
    required this.kind,
    this.parent,
    required this.publicName,
    this.personalLabel,
    this.resolution,
    this.resolvedAt,
    required this.archivedByCascade,
  });
}

@immutable
class GetMyArchivedSubjectsPrayerSubjectsParent {
  final String id;
  final String publicName;
  final String? personalLabel;
  final EnumValue<SubjectStatus> status;
  GetMyArchivedSubjectsPrayerSubjectsParent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  status = subjectStatusDeserializer(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyArchivedSubjectsPrayerSubjectsParent otherTyped = other as GetMyArchivedSubjectsPrayerSubjectsParent;
    return id == otherTyped.id && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, publicName.hashCode, personalLabel.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['publicName'] = nativeToJson<String>(publicName);
    if (personalLabel != null) {
      json['personalLabel'] = nativeToJson<String?>(personalLabel);
    }
    json['status'] = 
    subjectStatusSerializer(status)
    ;
    return json;
  }

  GetMyArchivedSubjectsPrayerSubjectsParent({
    required this.id,
    required this.publicName,
    this.personalLabel,
    required this.status,
  });
}

@immutable
class GetMyArchivedSubjectsData {
  final List<GetMyArchivedSubjectsPrayerSubjects> prayerSubjects;
  GetMyArchivedSubjectsData.fromJson(dynamic json):
  
  prayerSubjects = (json['prayerSubjects'] as List<dynamic>)
        .map((e) => GetMyArchivedSubjectsPrayerSubjects.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyArchivedSubjectsData otherTyped = other as GetMyArchivedSubjectsData;
    return prayerSubjects == otherTyped.prayerSubjects;
    
  }
  @override
  int get hashCode => prayerSubjects.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubjects'] = prayerSubjects.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyArchivedSubjectsData({
    required this.prayerSubjects,
  });
}

