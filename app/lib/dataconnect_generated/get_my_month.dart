part of 'plusprayer.dart';

class GetMyMonthVariablesBuilder {
  DateTime from;
  DateTime to;

  final FirebaseDataConnect _dataConnect;
  GetMyMonthVariablesBuilder(this._dataConnect, {required  this.from,required  this.to,});
  Deserializer<GetMyMonthData> dataDeserializer = (dynamic json)  => GetMyMonthData.fromJson(jsonDecode(json));
  Serializer<GetMyMonthVariables> varsSerializer = (GetMyMonthVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyMonthData, GetMyMonthVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyMonthData, GetMyMonthVariables> ref() {
    GetMyMonthVariables vars= GetMyMonthVariables(from: from,to: to,);
    return _dataConnect.query("GetMyMonth", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyMonthPrayers {
  final DateTime localDate;
  final GetMyMonthPrayersCommunityList? communityList;
  GetMyMonthPrayers.fromJson(dynamic json):
  
  localDate = nativeFromJson<DateTime>(json['localDate']),
  communityList = json['communityList'] == null ? null : GetMyMonthPrayersCommunityList.fromJson(json['communityList']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyMonthPrayers otherTyped = other as GetMyMonthPrayers;
    return localDate == otherTyped.localDate && 
    communityList == otherTyped.communityList;
    
  }
  @override
  int get hashCode => Object.hashAll([localDate.hashCode, communityList.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['localDate'] = nativeToJson<DateTime>(localDate);
    if (communityList != null) {
      json['communityList'] = communityList!.toJson();
    }
    return json;
  }

  GetMyMonthPrayers({
    required this.localDate,
    this.communityList,
  });
}

@immutable
class GetMyMonthPrayersCommunityList {
  final int listNumber;
  final int? sealVariant;
  GetMyMonthPrayersCommunityList.fromJson(dynamic json):
  
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

    final GetMyMonthPrayersCommunityList otherTyped = other as GetMyMonthPrayersCommunityList;
    return listNumber == otherTyped.listNumber && 
    sealVariant == otherTyped.sealVariant;
    
  }
  @override
  int get hashCode => Object.hashAll([listNumber.hashCode, sealVariant.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['listNumber'] = nativeToJson<int>(listNumber);
    if (sealVariant != null) {
      json['sealVariant'] = nativeToJson<int?>(sealVariant);
    }
    return json;
  }

  GetMyMonthPrayersCommunityList({
    required this.listNumber,
    this.sealVariant,
  });
}

@immutable
class GetMyMonthData {
  final List<GetMyMonthPrayers> prayers;
  GetMyMonthData.fromJson(dynamic json):
  
  prayers = (json['prayers'] as List<dynamic>)
        .map((e) => GetMyMonthPrayers.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyMonthData otherTyped = other as GetMyMonthData;
    return prayers == otherTyped.prayers;
    
  }
  @override
  int get hashCode => prayers.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayers'] = prayers.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyMonthData({
    required this.prayers,
  });
}

@immutable
class GetMyMonthVariables {
  final DateTime from;
  final DateTime to;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyMonthVariables.fromJson(Map<String, dynamic> json):
  
  from = nativeFromJson<DateTime>(json['from']),
  to = nativeFromJson<DateTime>(json['to']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyMonthVariables otherTyped = other as GetMyMonthVariables;
    return from == otherTyped.from && 
    to == otherTyped.to;
    
  }
  @override
  int get hashCode => Object.hashAll([from.hashCode, to.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['from'] = nativeToJson<DateTime>(from);
    json['to'] = nativeToJson<DateTime>(to);
    return json;
  }

  GetMyMonthVariables({
    required this.from,
    required this.to,
  });
}

