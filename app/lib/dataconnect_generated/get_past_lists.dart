part of 'plusprayer.dart';

class GetPastListsVariablesBuilder {
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _offset = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetPastListsVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }
  GetPastListsVariablesBuilder offset(int? t) {
   _offset.value = t;
   return this;
  }

  GetPastListsVariablesBuilder(this._dataConnect, );
  Deserializer<GetPastListsData> dataDeserializer = (dynamic json)  => GetPastListsData.fromJson(jsonDecode(json));
  Serializer<GetPastListsVariables> varsSerializer = (GetPastListsVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetPastListsData, GetPastListsVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetPastListsData, GetPastListsVariables> ref() {
    GetPastListsVariables vars= GetPastListsVariables(limit: _limit,offset: _offset,);
    return _dataConnect.query("GetPastLists", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetPastListsPrayerLists {
  final String id;
  final int listNumber;
  final DateTime listDate;
  final int? sealVariant;
  final int soulCount;
  final int intentionCount;
  final int prayerCount;
  final int prayerSeconds;
  final String? videoPath;
  final Timestamp? videoPublishedAt;
  GetPastListsPrayerLists.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  listNumber = nativeFromJson<int>(json['listNumber']),
  listDate = nativeFromJson<DateTime>(json['listDate']),
  sealVariant = json['sealVariant'] == null ? null : nativeFromJson<int>(json['sealVariant']),
  soulCount = nativeFromJson<int>(json['soulCount']),
  intentionCount = nativeFromJson<int>(json['intentionCount']),
  prayerCount = nativeFromJson<int>(json['prayerCount']),
  prayerSeconds = nativeFromJson<int>(json['prayerSeconds']),
  videoPath = json['videoPath'] == null ? null : nativeFromJson<String>(json['videoPath']),
  videoPublishedAt = json['videoPublishedAt'] == null ? null : Timestamp.fromJson(json['videoPublishedAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPastListsPrayerLists otherTyped = other as GetPastListsPrayerLists;
    return id == otherTyped.id && 
    listNumber == otherTyped.listNumber && 
    listDate == otherTyped.listDate && 
    sealVariant == otherTyped.sealVariant && 
    soulCount == otherTyped.soulCount && 
    intentionCount == otherTyped.intentionCount && 
    prayerCount == otherTyped.prayerCount && 
    prayerSeconds == otherTyped.prayerSeconds && 
    videoPath == otherTyped.videoPath && 
    videoPublishedAt == otherTyped.videoPublishedAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, listNumber.hashCode, listDate.hashCode, sealVariant.hashCode, soulCount.hashCode, intentionCount.hashCode, prayerCount.hashCode, prayerSeconds.hashCode, videoPath.hashCode, videoPublishedAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['listNumber'] = nativeToJson<int>(listNumber);
    json['listDate'] = nativeToJson<DateTime>(listDate);
    if (sealVariant != null) {
      json['sealVariant'] = nativeToJson<int?>(sealVariant);
    }
    json['soulCount'] = nativeToJson<int>(soulCount);
    json['intentionCount'] = nativeToJson<int>(intentionCount);
    json['prayerCount'] = nativeToJson<int>(prayerCount);
    json['prayerSeconds'] = nativeToJson<int>(prayerSeconds);
    if (videoPath != null) {
      json['videoPath'] = nativeToJson<String?>(videoPath);
    }
    if (videoPublishedAt != null) {
      json['videoPublishedAt'] = videoPublishedAt!.toJson();
    }
    return json;
  }

  GetPastListsPrayerLists({
    required this.id,
    required this.listNumber,
    required this.listDate,
    this.sealVariant,
    required this.soulCount,
    required this.intentionCount,
    required this.prayerCount,
    required this.prayerSeconds,
    this.videoPath,
    this.videoPublishedAt,
  });
}

@immutable
class GetPastListsData {
  final List<GetPastListsPrayerLists> prayerLists;
  GetPastListsData.fromJson(dynamic json):
  
  prayerLists = (json['prayerLists'] as List<dynamic>)
        .map((e) => GetPastListsPrayerLists.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetPastListsData otherTyped = other as GetPastListsData;
    return prayerLists == otherTyped.prayerLists;
    
  }
  @override
  int get hashCode => prayerLists.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerLists'] = prayerLists.map((e) => e.toJson()).toList();
    return json;
  }

  GetPastListsData({
    required this.prayerLists,
  });
}

@immutable
class GetPastListsVariables {
  late final Optional<int>limit;
  late final Optional<int>offset;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetPastListsVariables.fromJson(Map<String, dynamic> json) {
  
  
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

    final GetPastListsVariables otherTyped = other as GetPastListsVariables;
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

  GetPastListsVariables({
    required this.limit,
    required this.offset,
  });
}

