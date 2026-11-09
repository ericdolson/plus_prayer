part of 'plusprayer.dart';

class GetMyListEntriesVariablesBuilder {
  Optional<int> _limit = Optional.optional(nativeFromJson, nativeToJson);
  Optional<int> _offset = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetMyListEntriesVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }
  GetMyListEntriesVariablesBuilder offset(int? t) {
   _offset.value = t;
   return this;
  }

  GetMyListEntriesVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyListEntriesData> dataDeserializer = (dynamic json)  => GetMyListEntriesData.fromJson(jsonDecode(json));
  Serializer<GetMyListEntriesVariables> varsSerializer = (GetMyListEntriesVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyListEntriesData, GetMyListEntriesVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyListEntriesData, GetMyListEntriesVariables> ref() {
    GetMyListEntriesVariables vars= GetMyListEntriesVariables(limit: _limit,offset: _offset,);
    return _dataConnect.query("GetMyListEntries", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyListEntriesPrayerListEntries {
  final String id;
  final EnumValue<SubjectKind> kind;
  final GetMyListEntriesPrayerListEntriesSubject? subject;
  final GetMyListEntriesPrayerListEntriesList list;
  GetMyListEntriesPrayerListEntries.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  subject = json['subject'] == null ? null : GetMyListEntriesPrayerListEntriesSubject.fromJson(json['subject']),
  list = GetMyListEntriesPrayerListEntriesList.fromJson(json['list']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListEntriesPrayerListEntries otherTyped = other as GetMyListEntriesPrayerListEntries;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    subject == otherTyped.subject && 
    list == otherTyped.list;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, subject.hashCode, list.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    if (subject != null) {
      json['subject'] = subject!.toJson();
    }
    json['list'] = list.toJson();
    return json;
  }

  GetMyListEntriesPrayerListEntries({
    required this.id,
    required this.kind,
    this.subject,
    required this.list,
  });
}

@immutable
class GetMyListEntriesPrayerListEntriesSubject {
  final String id;
  GetMyListEntriesPrayerListEntriesSubject.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListEntriesPrayerListEntriesSubject otherTyped = other as GetMyListEntriesPrayerListEntriesSubject;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMyListEntriesPrayerListEntriesSubject({
    required this.id,
  });
}

@immutable
class GetMyListEntriesPrayerListEntriesList {
  final String id;
  final int listNumber;
  final DateTime listDate;
  final String status;
  final Timestamp? currentFrom;
  final int? sealVariant;
  final int prayerCount;
  GetMyListEntriesPrayerListEntriesList.fromJson(dynamic json):
  
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

    final GetMyListEntriesPrayerListEntriesList otherTyped = other as GetMyListEntriesPrayerListEntriesList;
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

  GetMyListEntriesPrayerListEntriesList({
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
class GetMyListEntriesData {
  final List<GetMyListEntriesPrayerListEntries> prayerListEntries;
  GetMyListEntriesData.fromJson(dynamic json):
  
  prayerListEntries = (json['prayerListEntries'] as List<dynamic>)
        .map((e) => GetMyListEntriesPrayerListEntries.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListEntriesData otherTyped = other as GetMyListEntriesData;
    return prayerListEntries == otherTyped.prayerListEntries;
    
  }
  @override
  int get hashCode => prayerListEntries.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['prayerListEntries'] = prayerListEntries.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyListEntriesData({
    required this.prayerListEntries,
  });
}

@immutable
class GetMyListEntriesVariables {
  late final Optional<int>limit;
  late final Optional<int>offset;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyListEntriesVariables.fromJson(Map<String, dynamic> json) {
  
  
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

    final GetMyListEntriesVariables otherTyped = other as GetMyListEntriesVariables;
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

  GetMyListEntriesVariables({
    required this.limit,
    required this.offset,
  });
}

