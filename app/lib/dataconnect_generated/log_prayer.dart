part of 'plusprayer.dart';

class LogPrayerVariablesBuilder {
  String id;
  Timestamp startedAt;
  Timestamp prayedAt;
  int durationSeconds;
  DateTime localDate;
  String timezone;
  Optional<String> _communityListId = Optional.optional(nativeFromJson, nativeToJson);
  int listContextNumber;
  Optional<String> _note = Optional.optional(nativeFromJson, nativeToJson);
  List<String> subjectIds;

  final FirebaseDataConnect _dataConnect;  LogPrayerVariablesBuilder communityListId(String? t) {
   _communityListId.value = t;
   return this;
  }
  LogPrayerVariablesBuilder note(String? t) {
   _note.value = t;
   return this;
  }

  LogPrayerVariablesBuilder(this._dataConnect, {required  this.id,required  this.startedAt,required  this.prayedAt,required  this.durationSeconds,required  this.localDate,required  this.timezone,required  this.listContextNumber,required  this.subjectIds,});
  Deserializer<LogPrayerData> dataDeserializer = (dynamic json)  => LogPrayerData.fromJson(jsonDecode(json));
  Serializer<LogPrayerVariables> varsSerializer = (LogPrayerVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<LogPrayerData, LogPrayerVariables>> execute() {
    return ref().execute();
  }

  MutationRef<LogPrayerData, LogPrayerVariables> ref() {
    LogPrayerVariables vars= LogPrayerVariables(id: id,startedAt: startedAt,prayedAt: prayedAt,durationSeconds: durationSeconds,localDate: localDate,timezone: timezone,communityListId: _communityListId,listContextNumber: listContextNumber,note: _note,subjectIds: subjectIds,);
    return _dataConnect.mutation("LogPrayer", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class LogPrayerData {
  final int? execute_;
  LogPrayerData.fromJson(dynamic json):
  
  execute_ = json['_execute'] == null ? null : nativeFromJson<int>(json['_execute']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LogPrayerData otherTyped = other as LogPrayerData;
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

  LogPrayerData({
    this.execute_,
  });
}

@immutable
class LogPrayerVariables {
  final String id;
  final Timestamp startedAt;
  final Timestamp prayedAt;
  final int durationSeconds;
  final DateTime localDate;
  final String timezone;
  late final Optional<String>communityListId;
  final int listContextNumber;
  late final Optional<String>note;
  final List<String> subjectIds;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  LogPrayerVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  startedAt = Timestamp.fromJson(json['startedAt']),
  prayedAt = Timestamp.fromJson(json['prayedAt']),
  durationSeconds = nativeFromJson<int>(json['durationSeconds']),
  localDate = nativeFromJson<DateTime>(json['localDate']),
  timezone = nativeFromJson<String>(json['timezone']),
  listContextNumber = nativeFromJson<int>(json['listContextNumber']),
  subjectIds = (json['subjectIds'] as List<dynamic>)
        .map((e) => nativeFromJson<String>(e))
        .toList() {
  
  
  
  
  
  
  
  
    communityListId = Optional.optional(nativeFromJson, nativeToJson);
    communityListId.value = json['communityListId'] == null ? null : nativeFromJson<String>(json['communityListId']);
  
  
  
    note = Optional.optional(nativeFromJson, nativeToJson);
    note.value = json['note'] == null ? null : nativeFromJson<String>(json['note']);
  
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final LogPrayerVariables otherTyped = other as LogPrayerVariables;
    return id == otherTyped.id && 
    startedAt == otherTyped.startedAt && 
    prayedAt == otherTyped.prayedAt && 
    durationSeconds == otherTyped.durationSeconds && 
    localDate == otherTyped.localDate && 
    timezone == otherTyped.timezone && 
    communityListId == otherTyped.communityListId && 
    listContextNumber == otherTyped.listContextNumber && 
    note == otherTyped.note && 
    subjectIds == otherTyped.subjectIds;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, startedAt.hashCode, prayedAt.hashCode, durationSeconds.hashCode, localDate.hashCode, timezone.hashCode, communityListId.hashCode, listContextNumber.hashCode, note.hashCode, subjectIds.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['startedAt'] = startedAt.toJson();
    json['prayedAt'] = prayedAt.toJson();
    json['durationSeconds'] = nativeToJson<int>(durationSeconds);
    json['localDate'] = nativeToJson<DateTime>(localDate);
    json['timezone'] = nativeToJson<String>(timezone);
    if(communityListId.state == OptionalState.set) {
      json['communityListId'] = communityListId.toJson();
    }
    json['listContextNumber'] = nativeToJson<int>(listContextNumber);
    if(note.state == OptionalState.set) {
      json['note'] = note.toJson();
    }
    json['subjectIds'] = subjectIds.map((e) => nativeToJson<String>(e)).toList();
    return json;
  }

  LogPrayerVariables({
    required this.id,
    required this.startedAt,
    required this.prayedAt,
    required this.durationSeconds,
    required this.localDate,
    required this.timezone,
    required this.communityListId,
    required this.listContextNumber,
    required this.note,
    required this.subjectIds,
  });
}

