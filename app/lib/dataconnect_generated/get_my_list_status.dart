part of 'plusprayer.dart';

class GetMyListStatusVariablesBuilder {
  String listId;

  final FirebaseDataConnect _dataConnect;
  GetMyListStatusVariablesBuilder(this._dataConnect, {required  this.listId,});
  Deserializer<GetMyListStatusData> dataDeserializer = (dynamic json)  => GetMyListStatusData.fromJson(jsonDecode(json));
  Serializer<GetMyListStatusVariables> varsSerializer = (GetMyListStatusVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyListStatusData, GetMyListStatusVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyListStatusData, GetMyListStatusVariables> ref() {
    GetMyListStatusVariables vars= GetMyListStatusVariables(listId: listId,);
    return _dataConnect.query("GetMyListStatus", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyListStatusMyEntries {
  final String id;
  final EnumValue<SubjectKind> kind;
  final String publicName;
  final GetMyListStatusMyEntriesParentEntry? parentEntry;
  final GetMyListStatusMyEntriesSubject? subject;
  GetMyListStatusMyEntries.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  publicName = nativeFromJson<String>(json['publicName']),
  parentEntry = json['parentEntry'] == null ? null : GetMyListStatusMyEntriesParentEntry.fromJson(json['parentEntry']),
  subject = json['subject'] == null ? null : GetMyListStatusMyEntriesSubject.fromJson(json['subject']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusMyEntries otherTyped = other as GetMyListStatusMyEntries;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    publicName == otherTyped.publicName && 
    parentEntry == otherTyped.parentEntry && 
    subject == otherTyped.subject;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, publicName.hashCode, parentEntry.hashCode, subject.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    json['publicName'] = nativeToJson<String>(publicName);
    if (parentEntry != null) {
      json['parentEntry'] = parentEntry!.toJson();
    }
    if (subject != null) {
      json['subject'] = subject!.toJson();
    }
    return json;
  }

  GetMyListStatusMyEntries({
    required this.id,
    required this.kind,
    required this.publicName,
    this.parentEntry,
    this.subject,
  });
}

@immutable
class GetMyListStatusMyEntriesParentEntry {
  final String id;
  GetMyListStatusMyEntriesParentEntry.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusMyEntriesParentEntry otherTyped = other as GetMyListStatusMyEntriesParentEntry;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMyListStatusMyEntriesParentEntry({
    required this.id,
  });
}

@immutable
class GetMyListStatusMyEntriesSubject {
  final String id;
  final bool isSelf;
  GetMyListStatusMyEntriesSubject.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  isSelf = nativeFromJson<bool>(json['isSelf']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusMyEntriesSubject otherTyped = other as GetMyListStatusMyEntriesSubject;
    return id == otherTyped.id && 
    isSelf == otherTyped.isSelf;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, isSelf.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['isSelf'] = nativeToJson<bool>(isSelf);
    return json;
  }

  GetMyListStatusMyEntriesSubject({
    required this.id,
    required this.isSelf,
  });
}

@immutable
class GetMyListStatusNotPrinted {
  final String id;
  final EnumValue<SubjectKind> kind;
  final String publicName;
  final EnumValue<ReasonCategory>? reasonCategory;
  final GetMyListStatusNotPrintedSubject? subject;
  GetMyListStatusNotPrinted.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  publicName = nativeFromJson<String>(json['publicName']),
  reasonCategory = json['reasonCategory'] == null ? null : reasonCategoryDeserializer(json['reasonCategory']),
  subject = json['subject'] == null ? null : GetMyListStatusNotPrintedSubject.fromJson(json['subject']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusNotPrinted otherTyped = other as GetMyListStatusNotPrinted;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    publicName == otherTyped.publicName && 
    reasonCategory == otherTyped.reasonCategory && 
    subject == otherTyped.subject;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, publicName.hashCode, reasonCategory.hashCode, subject.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    json['publicName'] = nativeToJson<String>(publicName);
    if (reasonCategory != null) {
      json['reasonCategory'] = 
    reasonCategorySerializer(reasonCategory!)
    ;
    }
    if (subject != null) {
      json['subject'] = subject!.toJson();
    }
    return json;
  }

  GetMyListStatusNotPrinted({
    required this.id,
    required this.kind,
    required this.publicName,
    this.reasonCategory,
    this.subject,
  });
}

@immutable
class GetMyListStatusNotPrintedSubject {
  final String id;
  GetMyListStatusNotPrintedSubject.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusNotPrintedSubject otherTyped = other as GetMyListStatusNotPrintedSubject;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMyListStatusNotPrintedSubject({
    required this.id,
  });
}

@immutable
class GetMyListStatusMyPrayersWithList {
  final int count_;
  GetMyListStatusMyPrayersWithList.fromJson(dynamic json):
  
  count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusMyPrayersWithList otherTyped = other as GetMyListStatusMyPrayersWithList;
    return count_ == otherTyped.count_;
    
  }
  @override
  int get hashCode => count_.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetMyListStatusMyPrayersWithList({
    required this.count_,
  });
}

@immutable
class GetMyListStatusCarriedLists {
  final int count_;
  GetMyListStatusCarriedLists.fromJson(dynamic json):
  
  count_ = nativeFromJson<int>(json['_count']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusCarriedLists otherTyped = other as GetMyListStatusCarriedLists;
    return count_ == otherTyped.count_;
    
  }
  @override
  int get hashCode => count_.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['_count'] = nativeToJson<int>(count_);
    return json;
  }

  GetMyListStatusCarriedLists({
    required this.count_,
  });
}

@immutable
class GetMyListStatusData {
  final List<GetMyListStatusMyEntries> myEntries;
  final List<GetMyListStatusNotPrinted> notPrinted;
  final List<GetMyListStatusMyPrayersWithList> myPrayersWithList;
  final List<GetMyListStatusCarriedLists> carriedLists;
  GetMyListStatusData.fromJson(dynamic json):
  
  myEntries = (json['myEntries'] as List<dynamic>)
        .map((e) => GetMyListStatusMyEntries.fromJson(e))
        .toList(),
  notPrinted = (json['notPrinted'] as List<dynamic>)
        .map((e) => GetMyListStatusNotPrinted.fromJson(e))
        .toList(),
  myPrayersWithList = (json['myPrayersWithList'] as List<dynamic>)
        .map((e) => GetMyListStatusMyPrayersWithList.fromJson(e))
        .toList(),
  carriedLists = (json['carriedLists'] as List<dynamic>)
        .map((e) => GetMyListStatusCarriedLists.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusData otherTyped = other as GetMyListStatusData;
    return myEntries == otherTyped.myEntries && 
    notPrinted == otherTyped.notPrinted && 
    myPrayersWithList == otherTyped.myPrayersWithList && 
    carriedLists == otherTyped.carriedLists;
    
  }
  @override
  int get hashCode => Object.hashAll([myEntries.hashCode, notPrinted.hashCode, myPrayersWithList.hashCode, carriedLists.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['myEntries'] = myEntries.map((e) => e.toJson()).toList();
    json['notPrinted'] = notPrinted.map((e) => e.toJson()).toList();
    json['myPrayersWithList'] = myPrayersWithList.map((e) => e.toJson()).toList();
    json['carriedLists'] = carriedLists.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyListStatusData({
    required this.myEntries,
    required this.notPrinted,
    required this.myPrayersWithList,
    required this.carriedLists,
  });
}

@immutable
class GetMyListStatusVariables {
  final String listId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyListStatusVariables.fromJson(Map<String, dynamic> json):
  
  listId = nativeFromJson<String>(json['listId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyListStatusVariables otherTyped = other as GetMyListStatusVariables;
    return listId == otherTyped.listId;
    
  }
  @override
  int get hashCode => listId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['listId'] = nativeToJson<String>(listId);
    return json;
  }

  GetMyListStatusVariables({
    required this.listId,
  });
}

