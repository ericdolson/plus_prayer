part of 'plusprayer.dart';

class GetMyPrayerHistoryVariablesBuilder {
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _offset = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetMyPrayerHistoryVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }
  GetMyPrayerHistoryVariablesBuilder offset(int? t) {
   _offset.value = t;
   return this;
  }

  GetMyPrayerHistoryVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyPrayerHistoryData> dataDeserializer = (dynamic json)  => GetMyPrayerHistoryData.fromJson(jsonDecode(json));
  Serializer<GetMyPrayerHistoryVariables> varsSerializer = (GetMyPrayerHistoryVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyPrayerHistoryData, GetMyPrayerHistoryVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyPrayerHistoryData, GetMyPrayerHistoryVariables> ref() {
    GetMyPrayerHistoryVariables vars= GetMyPrayerHistoryVariables(limit: _limit,offset: _offset,);
    return _dataConnect.query("GetMyPrayerHistory", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyPrayerHistoryPrayers {
  final String id;
  final Timestamp startedAt;
  final Timestamp prayedAt;
  final DateTime localDate;
  final String timezone;
  final int durationSeconds;
  final EnumValue<PrayerEndedBy> endedBy;
  final EnumValue<PrayerMode> mode;
  final String? note;
  final GetMyPrayerHistoryPrayersCommunityList? communityList;
  final List<GetMyPrayerHistoryPrayersHeld> held;
  GetMyPrayerHistoryPrayers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  startedAt = Timestamp.fromJson(json['startedAt']),
  prayedAt = Timestamp.fromJson(json['prayedAt']),
  localDate = nativeFromJson<DateTime>(json['localDate']),
  timezone = nativeFromJson<String>(json['timezone']),
  durationSeconds = nativeFromJson<int>(json['durationSeconds']),
  endedBy = prayerEndedByDeserializer(json['endedBy']),
  mode = prayerModeDeserializer(json['mode']),
  note = json['note'] == null ? null : nativeFromJson<String>(json['note']),
  communityList = json['communityList'] == null ? null : GetMyPrayerHistoryPrayersCommunityList.fromJson(json['communityList']),
  held = (json['held'] as List<dynamic>)
        .map((e) => GetMyPrayerHistoryPrayersHeld.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerHistoryPrayers otherTyped = other as GetMyPrayerHistoryPrayers;
    return id == otherTyped.id && 
    startedAt == otherTyped.startedAt && 
    prayedAt == otherTyped.prayedAt && 
    localDate == otherTyped.localDate && 
    timezone == otherTyped.timezone && 
    durationSeconds == otherTyped.durationSeconds && 
    endedBy == otherTyped.endedBy && 
    mode == otherTyped.mode && 
    note == otherTyped.note && 
    communityList == otherTyped.communityList && 
    held == otherTyped.held;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, startedAt.hashCode, prayedAt.hashCode, localDate.hashCode, timezone.hashCode, durationSeconds.hashCode, endedBy.hashCode, mode.hashCode, note.hashCode, communityList.hashCode, held.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['startedAt'] = startedAt.toJson();
    json['prayedAt'] = prayedAt.toJson();
    json['localDate'] = nativeToJson<DateTime>(localDate);
    json['timezone'] = nativeToJson<String>(timezone);
    json['durationSeconds'] = nativeToJson<int>(durationSeconds);
    json['endedBy'] = 
    prayerEndedBySerializer(endedBy)
    ;
    json['mode'] = 
    prayerModeSerializer(mode)
    ;
    if (note != null) {
      json['note'] = nativeToJson<String?>(note);
    }
    if (communityList != null) {
      json['communityList'] = communityList!.toJson();
    }
    json['held'] = held.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyPrayerHistoryPrayers({
    required this.id,
    required this.startedAt,
    required this.prayedAt,
    required this.localDate,
    required this.timezone,
    required this.durationSeconds,
    required this.endedBy,
    required this.mode,
    this.note,
    this.communityList,
    required this.held,
  });
}

@immutable
class GetMyPrayerHistoryPrayersCommunityList {
  final String id;
  final int listNumber;
  final int? sealVariant;
  GetMyPrayerHistoryPrayersCommunityList.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  listNumber = nativeFromJson<int>(json['listNumber']),
  sealVariant = json['sealVariant'] == null ? null : nativeFromJson<int>(json['sealVariant']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerHistoryPrayersCommunityList otherTyped = other as GetMyPrayerHistoryPrayersCommunityList;
    return id == otherTyped.id && 
    listNumber == otherTyped.listNumber && 
    sealVariant == otherTyped.sealVariant;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, listNumber.hashCode, sealVariant.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['listNumber'] = nativeToJson<int>(listNumber);
    if (sealVariant != null) {
      json['sealVariant'] = nativeToJson<int?>(sealVariant);
    }
    return json;
  }

  GetMyPrayerHistoryPrayersCommunityList({
    required this.id,
    required this.listNumber,
    this.sealVariant,
  });
}

@immutable
class GetMyPrayerHistoryPrayersHeld {
  final String id;
  final EnumValue<SubjectKind> kind;
  final String publicName;
  final String? personalLabel;
  GetMyPrayerHistoryPrayersHeld.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerHistoryPrayersHeld otherTyped = other as GetMyPrayerHistoryPrayersHeld;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, publicName.hashCode, personalLabel.hashCode]);
  

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
    return json;
  }

  GetMyPrayerHistoryPrayersHeld({
    required this.id,
    required this.kind,
    required this.publicName,
    this.personalLabel,
  });
}

@immutable
class GetMyPrayerHistoryData {
  final List<GetMyPrayerHistoryPrayers> prayers;
  GetMyPrayerHistoryData.fromJson(dynamic json):
  
  prayers = (json['prayers'] as List<dynamic>)
        .map((e) => GetMyPrayerHistoryPrayers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerHistoryData otherTyped = other as GetMyPrayerHistoryData;
    return prayers == otherTyped.prayers;
    
  }
  @override
  int get hashCode => prayers.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayers'] = prayers.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyPrayerHistoryData({
    required this.prayers,
  });
}

@immutable
class GetMyPrayerHistoryVariables {
  late final Optional<int>limit;
  late final Optional<int>offset;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyPrayerHistoryVariables.fromJson(Map<String, dynamic> json) {
  
  
    limit = Optional.optional(nativeFromJson, nativeToJson);
    limit.value = json['limit'] == null ? null : nativeFromJson<int>(json['limit']);
  
  
    offset = Optional.optional(nativeFromJson, nativeToJson);
    offset.value = json['offset'] == null ? null : nativeFromJson<int>(json['offset']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerHistoryVariables otherTyped = other as GetMyPrayerHistoryVariables;
    return limit == otherTyped.limit && 
    offset == otherTyped.offset;
    
  }
  @override
  int get hashCode => Object.hashAll([limit.hashCode, offset.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(limit.state == OptionalState.set) {
      json['limit'] = limit.toJson();
    }
    if(offset.state == OptionalState.set) {
      json['offset'] = offset.toJson();
    }
    return json;
  }

  GetMyPrayerHistoryVariables({
    required this.limit,
    required this.offset,
  });
}

