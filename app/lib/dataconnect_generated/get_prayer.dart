part of 'plusprayer.dart';

class GetPrayerVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetPrayerVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetPrayerData> dataDeserializer = (dynamic json)  => GetPrayerData.fromJson(jsonDecode(json));
  Serializer<GetPrayerVariables> varsSerializer = (GetPrayerVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPrayerData, GetPrayerVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetPrayerData, GetPrayerVariables> ref() {
    GetPrayerVariables vars= GetPrayerVariables(id: id,);
    return _dataConnect.query("GetPrayer", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPrayerPrayers {
  final String id;
  final Timestamp startedAt;
  final Timestamp prayedAt;
  final DateTime localDate;
  final String timezone;
  final int durationSeconds;
  final EnumValue<PrayerEndedBy> endedBy;
  final EnumValue<PrayerMode> mode;
  final String? note;
  final int listContextNumber;
  final GetPrayerPrayersCommunityList? communityList;
  final List<GetPrayerPrayersHeld> held;
  GetPrayerPrayers.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  startedAt = Timestamp.fromJson(json['startedAt']),
  prayedAt = Timestamp.fromJson(json['prayedAt']),
  localDate = nativeFromJson<DateTime>(json['localDate']),
  timezone = nativeFromJson<String>(json['timezone']),
  durationSeconds = nativeFromJson<int>(json['durationSeconds']),
  endedBy = prayerEndedByDeserializer(json['endedBy']),
  mode = prayerModeDeserializer(json['mode']),
  note = json['note'] == null ? null : nativeFromJson<String>(json['note']),
  listContextNumber = nativeFromJson<int>(json['listContextNumber']),
  communityList = json['communityList'] == null ? null : GetPrayerPrayersCommunityList.fromJson(json['communityList']),
  held = (json['held'] as List<dynamic>)
        .map((e) => GetPrayerPrayersHeld.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPrayerPrayers otherTyped = other as GetPrayerPrayers;
    return id == otherTyped.id && 
    startedAt == otherTyped.startedAt && 
    prayedAt == otherTyped.prayedAt && 
    localDate == otherTyped.localDate && 
    timezone == otherTyped.timezone && 
    durationSeconds == otherTyped.durationSeconds && 
    endedBy == otherTyped.endedBy && 
    mode == otherTyped.mode && 
    note == otherTyped.note && 
    listContextNumber == otherTyped.listContextNumber && 
    communityList == otherTyped.communityList && 
    held == otherTyped.held;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, startedAt.hashCode, prayedAt.hashCode, localDate.hashCode, timezone.hashCode, durationSeconds.hashCode, endedBy.hashCode, mode.hashCode, note.hashCode, listContextNumber.hashCode, communityList.hashCode, held.hashCode]);
  

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
    json['listContextNumber'] = nativeToJson<int>(listContextNumber);
    if (communityList != null) {
      json['communityList'] = communityList!.toJson();
    }
    json['held'] = held.map((e) => e.toJson()).toList();
    return json;
  }

  GetPrayerPrayers({
    required this.id,
    required this.startedAt,
    required this.prayedAt,
    required this.localDate,
    required this.timezone,
    required this.durationSeconds,
    required this.endedBy,
    required this.mode,
    this.note,
    required this.listContextNumber,
    this.communityList,
    required this.held,
  });
}

@immutable
class GetPrayerPrayersCommunityList {
  final String id;
  final int listNumber;
  final int? sealVariant;
  GetPrayerPrayersCommunityList.fromJson(dynamic json):
  
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

    final GetPrayerPrayersCommunityList otherTyped = other as GetPrayerPrayersCommunityList;
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

  GetPrayerPrayersCommunityList({
    required this.id,
    required this.listNumber,
    this.sealVariant,
  });
}

@immutable
class GetPrayerPrayersHeld {
  final String id;
  final EnumValue<SubjectKind> kind;
  final String publicName;
  final String? personalLabel;
  GetPrayerPrayersHeld.fromJson(dynamic json):
  
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

    final GetPrayerPrayersHeld otherTyped = other as GetPrayerPrayersHeld;
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

  GetPrayerPrayersHeld({
    required this.id,
    required this.kind,
    required this.publicName,
    this.personalLabel,
  });
}

@immutable
class GetPrayerData {
  final List<GetPrayerPrayers> prayers;
  GetPrayerData.fromJson(dynamic json):
  
  prayers = (json['prayers'] as List<dynamic>)
        .map((e) => GetPrayerPrayers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPrayerData otherTyped = other as GetPrayerData;
    return prayers == otherTyped.prayers;
    
  }
  @override
  int get hashCode => prayers.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayers'] = prayers.map((e) => e.toJson()).toList();
    return json;
  }

  GetPrayerData({
    required this.prayers,
  });
}

@immutable
class GetPrayerVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPrayerVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPrayerVariables otherTyped = other as GetPrayerVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetPrayerVariables({
    required this.id,
  });
}

