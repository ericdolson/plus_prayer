part of 'plusprayer.dart';

class GetMyPrayerTimeVariablesBuilder {
  DateTime weekStart;

  final FirebaseDataConnect _dataConnect;
  GetMyPrayerTimeVariablesBuilder(this._dataConnect, {required  this.weekStart,});
  Deserializer<GetMyPrayerTimeData> dataDeserializer = (dynamic json)  => GetMyPrayerTimeData.fromJson(jsonDecode(json));
  Serializer<GetMyPrayerTimeVariables> varsSerializer = (GetMyPrayerTimeVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyPrayerTimeData, GetMyPrayerTimeVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyPrayerTimeData, GetMyPrayerTimeVariables> ref() {
    GetMyPrayerTimeVariables vars= GetMyPrayerTimeVariables(weekStart: weekStart,);
    return _dataConnect.query("GetMyPrayerTime", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyPrayerTimeWeek {
  final int? durationSeconds_sum;
  final int count_;
  GetMyPrayerTimeWeek.fromJson(dynamic json):
  
  durationSeconds_sum = json['durationSeconds_sum'] == null ? null : nativeFromJson<int>(json['durationSeconds_sum']),
  count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerTimeWeek otherTyped = other as GetMyPrayerTimeWeek;
    return durationSeconds_sum == otherTyped.durationSeconds_sum && 
    count_ == otherTyped.count_;
    
  }
  @override
  int get hashCode => Object.hashAll([durationSeconds_sum.hashCode, count_.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (durationSeconds_sum != null) {
      json['durationSeconds_sum'] = nativeToJson<int?>(durationSeconds_sum);
    }
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetMyPrayerTimeWeek({
    this.durationSeconds_sum,
    required this.count_,
  });
}

@immutable
class GetMyPrayerTimeAllTime {
  final int? durationSeconds_sum;
  final int count_;
  GetMyPrayerTimeAllTime.fromJson(dynamic json):
  
  durationSeconds_sum = json['durationSeconds_sum'] == null ? null : nativeFromJson<int>(json['durationSeconds_sum']),
  count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerTimeAllTime otherTyped = other as GetMyPrayerTimeAllTime;
    return durationSeconds_sum == otherTyped.durationSeconds_sum && 
    count_ == otherTyped.count_;
    
  }
  @override
  int get hashCode => Object.hashAll([durationSeconds_sum.hashCode, count_.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (durationSeconds_sum != null) {
      json['durationSeconds_sum'] = nativeToJson<int?>(durationSeconds_sum);
    }
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetMyPrayerTimeAllTime({
    this.durationSeconds_sum,
    required this.count_,
  });
}

@immutable
class GetMyPrayerTimeData {
  final List<GetMyPrayerTimeWeek> week;
  final List<GetMyPrayerTimeAllTime> allTime;
  GetMyPrayerTimeData.fromJson(dynamic json):
  
  week = (json['week'] as List<dynamic>)
        .map((e) => GetMyPrayerTimeWeek.fromJson(e))
        .toList(),
  allTime = (json['allTime'] as List<dynamic>)
        .map((e) => GetMyPrayerTimeAllTime.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerTimeData otherTyped = other as GetMyPrayerTimeData;
    return week == otherTyped.week && 
    allTime == otherTyped.allTime;
    
  }
  @override
  int get hashCode => Object.hashAll([week.hashCode, allTime.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['week'] = week.map((e) => e.toJson()).toList();
    json['allTime'] = allTime.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyPrayerTimeData({
    required this.week,
    required this.allTime,
  });
}

@immutable
class GetMyPrayerTimeVariables {
  final DateTime weekStart;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyPrayerTimeVariables.fromJson(Map<String, dynamic> json):
  
  weekStart = nativeFromJson<DateTime>(json['weekStart']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPrayerTimeVariables otherTyped = other as GetMyPrayerTimeVariables;
    return weekStart == otherTyped.weekStart;
    
  }
  @override
  int get hashCode => weekStart.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['weekStart'] = nativeToJson<DateTime>(weekStart);
    return json;
  }

  GetMyPrayerTimeVariables({
    required this.weekStart,
  });
}

