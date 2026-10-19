part of 'plusprayer.dart';

class GetCurrentListMetaVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCurrentListMetaVariablesBuilder(this._dataConnect, );
  Deserializer<GetCurrentListMetaData> dataDeserializer = (dynamic json)  => GetCurrentListMetaData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCurrentListMetaData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetCurrentListMetaData, void> ref() {
    
    return _dataConnect.query("GetCurrentListMeta", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCurrentListMetaPrayerLists {
  final String id;
  final int listNumber;
  final DateTime listDate;
  final String status;
  final Timestamp? currentFrom;
  final Timestamp? closesAt;
  final Timestamp? videoPublishedAt;
  final String? videoPath;
  final int? sealVariant;
  final int soulCount;
  final int intentionCount;
  final int prayerCount;
  final int prayerSeconds;
  final List<GetCurrentListMetaPrayerListsPrayerListPostsOnList> prayerListPosts_on_list;
  GetCurrentListMetaPrayerLists.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  listNumber = nativeFromJson<int>(json['listNumber']),
  listDate = nativeFromJson<DateTime>(json['listDate']),
  status = nativeFromJson<String>(json['status']),
  currentFrom = json['currentFrom'] == null ? null : Timestamp.fromJson(json['currentFrom']),
  closesAt = json['closesAt'] == null ? null : Timestamp.fromJson(json['closesAt']),
  videoPublishedAt = json['videoPublishedAt'] == null ? null : Timestamp.fromJson(json['videoPublishedAt']),
  videoPath = json['videoPath'] == null ? null : nativeFromJson<String>(json['videoPath']),
  sealVariant = json['sealVariant'] == null ? null : nativeFromJson<int>(json['sealVariant']),
  soulCount = nativeFromJson<int>(json['soulCount']),
  intentionCount = nativeFromJson<int>(json['intentionCount']),
  prayerCount = nativeFromJson<int>(json['prayerCount']),
  prayerSeconds = nativeFromJson<int>(json['prayerSeconds']),
  prayerListPosts_on_list = (json['prayerListPosts_on_list'] as List<dynamic>)
        .map((e) => GetCurrentListMetaPrayerListsPrayerListPostsOnList.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentListMetaPrayerLists otherTyped = other as GetCurrentListMetaPrayerLists;
    return id == otherTyped.id && 
    listNumber == otherTyped.listNumber && 
    listDate == otherTyped.listDate && 
    status == otherTyped.status && 
    currentFrom == otherTyped.currentFrom && 
    closesAt == otherTyped.closesAt && 
    videoPublishedAt == otherTyped.videoPublishedAt && 
    videoPath == otherTyped.videoPath && 
    sealVariant == otherTyped.sealVariant && 
    soulCount == otherTyped.soulCount && 
    intentionCount == otherTyped.intentionCount && 
    prayerCount == otherTyped.prayerCount && 
    prayerSeconds == otherTyped.prayerSeconds && 
    prayerListPosts_on_list == otherTyped.prayerListPosts_on_list;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, listNumber.hashCode, listDate.hashCode, status.hashCode, currentFrom.hashCode, closesAt.hashCode, videoPublishedAt.hashCode, videoPath.hashCode, sealVariant.hashCode, soulCount.hashCode, intentionCount.hashCode, prayerCount.hashCode, prayerSeconds.hashCode, prayerListPosts_on_list.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['listNumber'] = nativeToJson<int>(listNumber);
    json['listDate'] = nativeToJson<DateTime>(listDate);
    json['status'] = nativeToJson<String>(status);
    if (currentFrom != null) {
      json['currentFrom'] = currentFrom!.toJson();
    }
    if (closesAt != null) {
      json['closesAt'] = closesAt!.toJson();
    }
    if (videoPublishedAt != null) {
      json['videoPublishedAt'] = videoPublishedAt!.toJson();
    }
    if (videoPath != null) {
      json['videoPath'] = nativeToJson<String?>(videoPath);
    }
    if (sealVariant != null) {
      json['sealVariant'] = nativeToJson<int?>(sealVariant);
    }
    json['soulCount'] = nativeToJson<int>(soulCount);
    json['intentionCount'] = nativeToJson<int>(intentionCount);
    json['prayerCount'] = nativeToJson<int>(prayerCount);
    json['prayerSeconds'] = nativeToJson<int>(prayerSeconds);
    json['prayerListPosts_on_list'] = prayerListPosts_on_list.map((e) => e.toJson()).toList();
    return json;
  }

  GetCurrentListMetaPrayerLists({
    required this.id,
    required this.listNumber,
    required this.listDate,
    required this.status,
    this.currentFrom,
    this.closesAt,
    this.videoPublishedAt,
    this.videoPath,
    this.sealVariant,
    required this.soulCount,
    required this.intentionCount,
    required this.prayerCount,
    required this.prayerSeconds,
    required this.prayerListPosts_on_list,
  });
}

@immutable
class GetCurrentListMetaPrayerListsPrayerListPostsOnList {
  final String platform;
  final String? url;
  GetCurrentListMetaPrayerListsPrayerListPostsOnList.fromJson(dynamic json):
  
  platform = nativeFromJson<String>(json['platform']),
  url = json['url'] == null ? null : nativeFromJson<String>(json['url']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentListMetaPrayerListsPrayerListPostsOnList otherTyped = other as GetCurrentListMetaPrayerListsPrayerListPostsOnList;
    return platform == otherTyped.platform && 
    url == otherTyped.url;
    
  }
  @override
  int get hashCode => Object.hashAll([platform.hashCode, url.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['platform'] = nativeToJson<String>(platform);
    if (url != null) {
      json['url'] = nativeToJson<String?>(url);
    }
    return json;
  }

  GetCurrentListMetaPrayerListsPrayerListPostsOnList({
    required this.platform,
    this.url,
  });
}

@immutable
class GetCurrentListMetaData {
  final List<GetCurrentListMetaPrayerLists> prayerLists;
  GetCurrentListMetaData.fromJson(dynamic json):
  
  prayerLists = (json['prayerLists'] as List<dynamic>)
        .map((e) => GetCurrentListMetaPrayerLists.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentListMetaData otherTyped = other as GetCurrentListMetaData;
    return prayerLists == otherTyped.prayerLists;
    
  }
  @override
  int get hashCode => prayerLists.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerLists'] = prayerLists.map((e) => e.toJson()).toList();
    return json;
  }

  GetCurrentListMetaData({
    required this.prayerLists,
  });
}

