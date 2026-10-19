part of 'plusprayer.dart';

class GetSubjectDetailVariablesBuilder {
  String id;
  Optional<int> _prayerLimit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _prayerOffset = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  GetSubjectDetailVariablesBuilder prayerLimit(int? t) {
   _prayerLimit.value = t;
   return this;
  }
  GetSubjectDetailVariablesBuilder prayerOffset(int? t) {
   _prayerOffset.value = t;
   return this;
  }

  GetSubjectDetailVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetSubjectDetailData> dataDeserializer = (dynamic json)  => GetSubjectDetailData.fromJson(jsonDecode(json));
  Serializer<GetSubjectDetailVariables> varsSerializer = (GetSubjectDetailVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSubjectDetailData, GetSubjectDetailVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetSubjectDetailData, GetSubjectDetailVariables> ref() {
    GetSubjectDetailVariables vars= GetSubjectDetailVariables(id: id,prayerLimit: _prayerLimit,prayerOffset: _prayerOffset,);
    return _dataConnect.query("GetSubjectDetail", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSubjectDetailPrayerSubjects {
  final String id;
  final EnumValue<SubjectKind> kind;
  final String publicName;
  final String? personalLabel;
  final String? note;
  final bool isSelf;
  final bool isCarried;
  final EnumValue<SubjectStatus> status;
  final int sortOrder;
  final int? avatarTone;
  final String? avatarPath;
  final EnumValue<SubjectResolution>? resolution;
  final Timestamp? resolvedAt;
  final Timestamp createdAt;
  final GetSubjectDetailPrayerSubjectsParent? parent;
  final List<GetSubjectDetailPrayerSubjectsIntentions> intentions;
  final List<GetSubjectDetailPrayerSubjectsEntries> entries;
  final List<GetSubjectDetailPrayerSubjectsPrayers> prayers;
  GetSubjectDetailPrayerSubjects.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  note = json['note'] == null ? null : nativeFromJson<String>(json['note']),
  isSelf = nativeFromJson<bool>(json['isSelf']),
  isCarried = nativeFromJson<bool>(json['isCarried']),
  status = subjectStatusDeserializer(json['status']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  avatarTone = json['avatarTone'] == null ? null : nativeFromJson<int>(json['avatarTone']),
  avatarPath = json['avatarPath'] == null ? null : nativeFromJson<String>(json['avatarPath']),
  resolution = json['resolution'] == null ? null : subjectResolutionDeserializer(json['resolution']),
  resolvedAt = json['resolvedAt'] == null ? null : Timestamp.fromJson(json['resolvedAt']),
  createdAt = Timestamp.fromJson(json['createdAt']),
  parent = json['parent'] == null ? null : GetSubjectDetailPrayerSubjectsParent.fromJson(json['parent']),
  intentions = (json['intentions'] as List<dynamic>)
        .map((e) => GetSubjectDetailPrayerSubjectsIntentions.fromJson(e))
        .toList(),
  entries = (json['entries'] as List<dynamic>)
        .map((e) => GetSubjectDetailPrayerSubjectsEntries.fromJson(e))
        .toList(),
  prayers = (json['prayers'] as List<dynamic>)
        .map((e) => GetSubjectDetailPrayerSubjectsPrayers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailPrayerSubjects otherTyped = other as GetSubjectDetailPrayerSubjects;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    note == otherTyped.note && 
    isSelf == otherTyped.isSelf && 
    isCarried == otherTyped.isCarried && 
    status == otherTyped.status && 
    sortOrder == otherTyped.sortOrder && 
    avatarTone == otherTyped.avatarTone && 
    avatarPath == otherTyped.avatarPath && 
    resolution == otherTyped.resolution && 
    resolvedAt == otherTyped.resolvedAt && 
    createdAt == otherTyped.createdAt && 
    parent == otherTyped.parent && 
    intentions == otherTyped.intentions && 
    entries == otherTyped.entries && 
    prayers == otherTyped.prayers;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, publicName.hashCode, personalLabel.hashCode, note.hashCode, isSelf.hashCode, isCarried.hashCode, status.hashCode, sortOrder.hashCode, avatarTone.hashCode, avatarPath.hashCode, resolution.hashCode, resolvedAt.hashCode, createdAt.hashCode, parent.hashCode, intentions.hashCode, entries.hashCode, prayers.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    json['publicName'] = nativeToJson<String>(publicName);
    if (personalLabel != null) {
      json['personalLabel'] = nativeToJson<String?>(personalLabel);
    }
    if (note != null) {
      json['note'] = nativeToJson<String?>(note);
    }
    json['isSelf'] = nativeToJson<bool>(isSelf);
    json['isCarried'] = nativeToJson<bool>(isCarried);
    json['status'] = 
    subjectStatusSerializer(status)
    ;
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
    if (parent != null) {
      json['parent'] = parent!.toJson();
    }
    json['intentions'] = intentions.map((e) => e.toJson()).toList();
    json['entries'] = entries.map((e) => e.toJson()).toList();
    json['prayers'] = prayers.map((e) => e.toJson()).toList();
    return json;
  }

  GetSubjectDetailPrayerSubjects({
    required this.id,
    required this.kind,
    required this.publicName,
    this.personalLabel,
    this.note,
    required this.isSelf,
    required this.isCarried,
    required this.status,
    required this.sortOrder,
    this.avatarTone,
    this.avatarPath,
    this.resolution,
    this.resolvedAt,
    required this.createdAt,
    this.parent,
    required this.intentions,
    required this.entries,
    required this.prayers,
  });
}

@immutable
class GetSubjectDetailPrayerSubjectsParent {
  final String id;
  final String publicName;
  final String? personalLabel;
  final bool isCarried;
  final bool isSelf;
  GetSubjectDetailPrayerSubjectsParent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  isCarried = nativeFromJson<bool>(json['isCarried']),
  isSelf = nativeFromJson<bool>(json['isSelf']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailPrayerSubjectsParent otherTyped = other as GetSubjectDetailPrayerSubjectsParent;
    return id == otherTyped.id && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    isCarried == otherTyped.isCarried && 
    isSelf == otherTyped.isSelf;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, publicName.hashCode, personalLabel.hashCode, isCarried.hashCode, isSelf.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['publicName'] = nativeToJson<String>(publicName);
    if (personalLabel != null) {
      json['personalLabel'] = nativeToJson<String?>(personalLabel);
    }
    json['isCarried'] = nativeToJson<bool>(isCarried);
    json['isSelf'] = nativeToJson<bool>(isSelf);
    return json;
  }

  GetSubjectDetailPrayerSubjectsParent({
    required this.id,
    required this.publicName,
    this.personalLabel,
    required this.isCarried,
    required this.isSelf,
  });
}

@immutable
class GetSubjectDetailPrayerSubjectsIntentions {
  final String id;
  final String publicName;
  final bool isCarried;
  final EnumValue<SubjectStatus> status;
  final EnumValue<SubjectResolution>? resolution;
  final Timestamp? resolvedAt;
  GetSubjectDetailPrayerSubjectsIntentions.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  publicName = nativeFromJson<String>(json['publicName']),
  isCarried = nativeFromJson<bool>(json['isCarried']),
  status = subjectStatusDeserializer(json['status']),
  resolution = json['resolution'] == null ? null : subjectResolutionDeserializer(json['resolution']),
  resolvedAt = json['resolvedAt'] == null ? null : Timestamp.fromJson(json['resolvedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailPrayerSubjectsIntentions otherTyped = other as GetSubjectDetailPrayerSubjectsIntentions;
    return id == otherTyped.id && 
    publicName == otherTyped.publicName && 
    isCarried == otherTyped.isCarried && 
    status == otherTyped.status && 
    resolution == otherTyped.resolution && 
    resolvedAt == otherTyped.resolvedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, publicName.hashCode, isCarried.hashCode, status.hashCode, resolution.hashCode, resolvedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['publicName'] = nativeToJson<String>(publicName);
    json['isCarried'] = nativeToJson<bool>(isCarried);
    json['status'] = 
    subjectStatusSerializer(status)
    ;
    if (resolution != null) {
      json['resolution'] = 
    subjectResolutionSerializer(resolution!)
    ;
    }
    if (resolvedAt != null) {
      json['resolvedAt'] = resolvedAt!.toJson();
    }
    return json;
  }

  GetSubjectDetailPrayerSubjectsIntentions({
    required this.id,
    required this.publicName,
    required this.isCarried,
    required this.status,
    this.resolution,
    this.resolvedAt,
  });
}

@immutable
class GetSubjectDetailPrayerSubjectsEntries {
  final String id;
  final EnumValue<ModerationStatus> moderationStatus;
  final GetSubjectDetailPrayerSubjectsEntriesList list;
  GetSubjectDetailPrayerSubjectsEntries.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  moderationStatus = moderationStatusDeserializer(json['moderationStatus']),
  list = GetSubjectDetailPrayerSubjectsEntriesList.fromJson(json['list']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailPrayerSubjectsEntries otherTyped = other as GetSubjectDetailPrayerSubjectsEntries;
    return id == otherTyped.id && 
    moderationStatus == otherTyped.moderationStatus && 
    list == otherTyped.list;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, moderationStatus.hashCode, list.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['moderationStatus'] = 
    moderationStatusSerializer(moderationStatus)
    ;
    json['list'] = list.toJson();
    return json;
  }

  GetSubjectDetailPrayerSubjectsEntries({
    required this.id,
    required this.moderationStatus,
    required this.list,
  });
}

@immutable
class GetSubjectDetailPrayerSubjectsEntriesList {
  final String id;
  final int listNumber;
  final DateTime listDate;
  final String status;
  final Timestamp? currentFrom;
  final int? sealVariant;
  final int prayerCount;
  GetSubjectDetailPrayerSubjectsEntriesList.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  listNumber = nativeFromJson<int>(json['listNumber']),
  listDate = nativeFromJson<DateTime>(json['listDate']),
  status = nativeFromJson<String>(json['status']),
  currentFrom = json['currentFrom'] == null ? null : Timestamp.fromJson(json['currentFrom']),
  sealVariant = json['sealVariant'] == null ? null : nativeFromJson<int>(json['sealVariant']),
  prayerCount = nativeFromJson<int>(json['prayerCount']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailPrayerSubjectsEntriesList otherTyped = other as GetSubjectDetailPrayerSubjectsEntriesList;
    return id == otherTyped.id && 
    listNumber == otherTyped.listNumber && 
    listDate == otherTyped.listDate && 
    status == otherTyped.status && 
    currentFrom == otherTyped.currentFrom && 
    sealVariant == otherTyped.sealVariant && 
    prayerCount == otherTyped.prayerCount;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, listNumber.hashCode, listDate.hashCode, status.hashCode, currentFrom.hashCode, sealVariant.hashCode, prayerCount.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['listNumber'] = nativeToJson<int>(listNumber);
    json['listDate'] = nativeToJson<DateTime>(listDate);
    json['status'] = nativeToJson<String>(status);
    if (currentFrom != null) {
      json['currentFrom'] = currentFrom!.toJson();
    }
    if (sealVariant != null) {
      json['sealVariant'] = nativeToJson<int?>(sealVariant);
    }
    json['prayerCount'] = nativeToJson<int>(prayerCount);
    return json;
  }

  GetSubjectDetailPrayerSubjectsEntriesList({
    required this.id,
    required this.listNumber,
    required this.listDate,
    required this.status,
    this.currentFrom,
    this.sealVariant,
    required this.prayerCount,
  });
}

@immutable
class GetSubjectDetailPrayerSubjectsPrayers {
  final String id;
  final Timestamp startedAt;
  final Timestamp prayedAt;
  final DateTime localDate;
  final int durationSeconds;
  final EnumValue<PrayerEndedBy> endedBy;
  final int listContextNumber;
  final String? note;
  GetSubjectDetailPrayerSubjectsPrayers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  startedAt = Timestamp.fromJson(json['startedAt']),
  prayedAt = Timestamp.fromJson(json['prayedAt']),
  localDate = nativeFromJson<DateTime>(json['localDate']),
  durationSeconds = nativeFromJson<int>(json['durationSeconds']),
  endedBy = prayerEndedByDeserializer(json['endedBy']),
  listContextNumber = nativeFromJson<int>(json['listContextNumber']),
  note = json['note'] == null ? null : nativeFromJson<String>(json['note']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailPrayerSubjectsPrayers otherTyped = other as GetSubjectDetailPrayerSubjectsPrayers;
    return id == otherTyped.id && 
    startedAt == otherTyped.startedAt && 
    prayedAt == otherTyped.prayedAt && 
    localDate == otherTyped.localDate && 
    durationSeconds == otherTyped.durationSeconds && 
    endedBy == otherTyped.endedBy && 
    listContextNumber == otherTyped.listContextNumber && 
    note == otherTyped.note;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, startedAt.hashCode, prayedAt.hashCode, localDate.hashCode, durationSeconds.hashCode, endedBy.hashCode, listContextNumber.hashCode, note.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['startedAt'] = startedAt.toJson();
    json['prayedAt'] = prayedAt.toJson();
    json['localDate'] = nativeToJson<DateTime>(localDate);
    json['durationSeconds'] = nativeToJson<int>(durationSeconds);
    json['endedBy'] = 
    prayerEndedBySerializer(endedBy)
    ;
    json['listContextNumber'] = nativeToJson<int>(listContextNumber);
    if (note != null) {
      json['note'] = nativeToJson<String?>(note);
    }
    return json;
  }

  GetSubjectDetailPrayerSubjectsPrayers({
    required this.id,
    required this.startedAt,
    required this.prayedAt,
    required this.localDate,
    required this.durationSeconds,
    required this.endedBy,
    required this.listContextNumber,
    this.note,
  });
}

@immutable
class GetSubjectDetailData {
  final List<GetSubjectDetailPrayerSubjects> prayerSubjects;
  GetSubjectDetailData.fromJson(dynamic json):
  
  prayerSubjects = (json['prayerSubjects'] as List<dynamic>)
        .map((e) => GetSubjectDetailPrayerSubjects.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailData otherTyped = other as GetSubjectDetailData;
    return prayerSubjects == otherTyped.prayerSubjects;
    
  }
  @override
  int get hashCode => prayerSubjects.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerSubjects'] = prayerSubjects.map((e) => e.toJson()).toList();
    return json;
  }

  GetSubjectDetailData({
    required this.prayerSubjects,
  });
}

@immutable
class GetSubjectDetailVariables {
  final String id;
  late final Optional<int>prayerLimit;
  late final Optional<int>prayerOffset;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSubjectDetailVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']) {
  
  
  
    prayerLimit = Optional.optional(nativeFromJson, nativeToJson);
    prayerLimit.value = json['prayerLimit'] == null ? null : nativeFromJson<int>(json['prayerLimit']);
  
  
    prayerOffset = Optional.optional(nativeFromJson, nativeToJson);
    prayerOffset.value = json['prayerOffset'] == null ? null : nativeFromJson<int>(json['prayerOffset']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubjectDetailVariables otherTyped = other as GetSubjectDetailVariables;
    return id == otherTyped.id && 
    prayerLimit == otherTyped.prayerLimit && 
    prayerOffset == otherTyped.prayerOffset;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, prayerLimit.hashCode, prayerOffset.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if(prayerLimit.state == OptionalState.set) {
      json['prayerLimit'] = prayerLimit.toJson();
    }
    if(prayerOffset.state == OptionalState.set) {
      json['prayerOffset'] = prayerOffset.toJson();
    }
    return json;
  }

  GetSubjectDetailVariables({
    required this.id,
    required this.prayerLimit,
    required this.prayerOffset,
  });
}

