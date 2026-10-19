part of 'plusprayer.dart';

class GetMySubjectsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMySubjectsVariablesBuilder(this._dataConnect, );
  Deserializer<GetMySubjectsData> dataDeserializer = (dynamic json)  => GetMySubjectsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMySubjectsData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMySubjectsData, void> ref() {
    
    return _dataConnect.query("GetMySubjects", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMySubjectsPrayerSubjects {
  final String id;
  final EnumValue<SubjectKind> kind;
  final GetMySubjectsPrayerSubjectsParent? parent;
  final String publicName;
  final String? personalLabel;
  final String? note;
  final bool isSelf;
  final bool isCarried;
  final int sortOrder;
  final int? avatarTone;
  final String? avatarPath;
  final EnumValue<SubjectResolution>? resolution;
  final Timestamp? resolvedAt;
  final Timestamp createdAt;
  final List<GetMySubjectsPrayerSubjectsLastPrayed> lastPrayed;
  GetMySubjectsPrayerSubjects.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  parent = json['parent'] == null ? null : GetMySubjectsPrayerSubjectsParent.fromJson(json['parent']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  note = json['note'] == null ? null : nativeFromJson<String>(json['note']),
  isSelf = nativeFromJson<bool>(json['isSelf']),
  isCarried = nativeFromJson<bool>(json['isCarried']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  avatarTone = json['avatarTone'] == null ? null : nativeFromJson<int>(json['avatarTone']),
  avatarPath = json['avatarPath'] == null ? null : nativeFromJson<String>(json['avatarPath']),
  resolution = json['resolution'] == null ? null : subjectResolutionDeserializer(json['resolution']),
  resolvedAt = json['resolvedAt'] == null ? null : Timestamp.fromJson(json['resolvedAt']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  lastPrayed = (json['lastPrayed'] as List<dynamic>)
        .map((e) => GetMySubjectsPrayerSubjectsLastPrayed.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubjectsPrayerSubjects otherTyped = other as GetMySubjectsPrayerSubjects;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    parent == otherTyped.parent && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    note == otherTyped.note && 
    isSelf == otherTyped.isSelf && 
    isCarried == otherTyped.isCarried && 
    sortOrder == otherTyped.sortOrder && 
    avatarTone == otherTyped.avatarTone && 
    avatarPath == otherTyped.avatarPath && 
    resolution == otherTyped.resolution && 
    resolvedAt == otherTyped.resolvedAt && 
    createdAt == otherTyped.createdAt && 
    lastPrayed == otherTyped.lastPrayed;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, parent.hashCode, publicName.hashCode, personalLabel.hashCode, note.hashCode, isSelf.hashCode, isCarried.hashCode, sortOrder.hashCode, avatarTone.hashCode, avatarPath.hashCode, resolution.hashCode, resolvedAt.hashCode, createdAt.hashCode, lastPrayed.hashCode]);
  

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
    if (note != null) {
      json['note'] = nativeToJson<String?>(note);
    }
    json['isSelf'] = nativeToJson<bool>(isSelf);
    json['isCarried'] = nativeToJson<bool>(isCarried);
    json['sortOrder'] = nativeToJson<int>(sortOrder);
    if (avatarTone != null) {
      json['avatarTone'] = nativeToJson<int?>(avatarTone);
    }
    if (avatarPath != null) {
      json['avatarPath'] = nativeToJson<String?>(avatarPath);
    }
    if (resolution != null) {
      json['resolution'] = 
    subjectResolutionSerializer(resolution!)
    ;
    }
    if (resolvedAt != null) {
      json['resolvedAt'] = resolvedAt!.toJson();
    }
    json['createdAt'] = createdAt.toJson();
    json['lastPrayed'] = lastPrayed.map((e) => e.toJson()).toList();
    return json;
  }

  GetMySubjectsPrayerSubjects({
    required this.id,
    required this.kind,
    this.parent,
    required this.publicName,
    this.personalLabel,
    this.note,
    required this.isSelf,
    required this.isCarried,
    required this.sortOrder,
    this.avatarTone,
    this.avatarPath,
    this.resolution,
    this.resolvedAt,
    required this.createdAt,
    required this.lastPrayed,
  });
}

@immutable
class GetMySubjectsPrayerSubjectsParent {
  final String id;
  GetMySubjectsPrayerSubjectsParent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubjectsPrayerSubjectsParent otherTyped = other as GetMySubjectsPrayerSubjectsParent;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMySubjectsPrayerSubjectsParent({
    required this.id,
  });
}

@immutable
class GetMySubjectsPrayerSubjectsLastPrayed {
  final DateTime localDate;
  GetMySubjectsPrayerSubjectsLastPrayed.fromJson(dynamic json):
  
  localDate = nativeFromJson<DateTime>(json['localDate']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubjectsPrayerSubjectsLastPrayed otherTyped = other as GetMySubjectsPrayerSubjectsLastPrayed;
    return localDate == otherTyped.localDate;
    
  }
  @override
  int get hashCode => localDate.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localDate'] = nativeToJson<DateTime>(localDate);
    return json;
  }

  GetMySubjectsPrayerSubjectsLastPrayed({
    required this.localDate,
  });
}

@immutable
class GetMySubjectsData {
  final List<GetMySubjectsPrayerSubjects> prayerSubjects;
  GetMySubjectsData.fromJson(dynamic json):
  
  prayerSubjects = (json['prayerSubjects'] as List<dynamic>)
        .map((e) => GetMySubjectsPrayerSubjects.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMySubjectsData otherTyped = other as GetMySubjectsData;
    return prayerSubjects == otherTyped.prayerSubjects;
    
  }
  @override
  int get hashCode => prayerSubjects.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubjects'] = prayerSubjects.map((e) => e.toJson()).toList();
    return json;
  }

  GetMySubjectsData({
    required this.prayerSubjects,
  });
}

