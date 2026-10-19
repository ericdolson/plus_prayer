part of 'plusprayer.dart';

class GetMyPortionVariablesBuilder {
  Optional<String> _listId = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;
  GetMyPortionVariablesBuilder listId(String? t) {
   _listId.value = t;
   return this;
  }

  GetMyPortionVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyPortionData> dataDeserializer = (dynamic json)  => GetMyPortionData.fromJson(jsonDecode(json));
  Serializer<GetMyPortionVariables> varsSerializer = (GetMyPortionVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetMyPortionData, GetMyPortionVariables>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyPortionData, GetMyPortionVariables> ref() {
    GetMyPortionVariables vars= GetMyPortionVariables(listId: _listId,);
    return _dataConnect.query("GetMyPortion", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetMyPortionUser {
  final String planTier;
  final int includeLimit;
  final Timestamp? trialStartedAt;
  final Timestamp? entitlementExpiresAt;
  GetMyPortionUser.fromJson(dynamic json):
  
  planTier = nativeFromJson<String>(json['planTier']),
  includeLimit = nativeFromJson<int>(json['includeLimit']),
  trialStartedAt = json['trialStartedAt'] == null ? null : Timestamp.fromJson(json['trialStartedAt']),
  entitlementExpiresAt = json['entitlementExpiresAt'] == null ? null : Timestamp.fromJson(json['entitlementExpiresAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionUser otherTyped = other as GetMyPortionUser;
    return planTier == otherTyped.planTier && 
    includeLimit == otherTyped.includeLimit && 
    trialStartedAt == otherTyped.trialStartedAt && 
    entitlementExpiresAt == otherTyped.entitlementExpiresAt;
    
  }
  @override
  int get hashCode => Object.hashAll([planTier.hashCode, includeLimit.hashCode, trialStartedAt.hashCode, entitlementExpiresAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['planTier'] = nativeToJson<String>(planTier);
    json['includeLimit'] = nativeToJson<int>(includeLimit);
    if (trialStartedAt != null) {
      json['trialStartedAt'] = trialStartedAt!.toJson();
    }
    if (entitlementExpiresAt != null) {
      json['entitlementExpiresAt'] = entitlementExpiresAt!.toJson();
    }
    return json;
  }

  GetMyPortionUser({
    required this.planTier,
    required this.includeLimit,
    this.trialStartedAt,
    this.entitlementExpiresAt,
  });
}

@immutable
class GetMyPortionItems {
  final String id;
  final EnumValue<SubjectKind> kind;
  final GetMyPortionItemsParent? parent;
  final String publicName;
  final String? personalLabel;
  final bool isSelf;
  final bool isCarried;
  final int sortOrder;
  final int? avatarTone;
  GetMyPortionItems.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  kind = subjectKindDeserializer(json['kind']),
  parent = json['parent'] == null ? null : GetMyPortionItemsParent.fromJson(json['parent']),
  publicName = nativeFromJson<String>(json['publicName']),
  personalLabel = json['personalLabel'] == null ? null : nativeFromJson<String>(json['personalLabel']),
  isSelf = nativeFromJson<bool>(json['isSelf']),
  isCarried = nativeFromJson<bool>(json['isCarried']),
  sortOrder = nativeFromJson<int>(json['sortOrder']),
  avatarTone = json['avatarTone'] == null ? null : nativeFromJson<int>(json['avatarTone']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionItems otherTyped = other as GetMyPortionItems;
    return id == otherTyped.id && 
    kind == otherTyped.kind && 
    parent == otherTyped.parent && 
    publicName == otherTyped.publicName && 
    personalLabel == otherTyped.personalLabel && 
    isSelf == otherTyped.isSelf && 
    isCarried == otherTyped.isCarried && 
    sortOrder == otherTyped.sortOrder && 
    avatarTone == otherTyped.avatarTone;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, kind.hashCode, parent.hashCode, publicName.hashCode, personalLabel.hashCode, isSelf.hashCode, isCarried.hashCode, sortOrder.hashCode, avatarTone.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['kind'] = 
    subjectKindSerializer(kind)
    ;
    if (parent != null) {
      json['parent'] = parent!.toJson();
    }
    json['publicName'] = nativeToJson<String>(publicName);
    if (personalLabel != null) {
      json['personalLabel'] = nativeToJson<String?>(personalLabel);
    }
    json['isSelf'] = nativeToJson<bool>(isSelf);
    json['isCarried'] = nativeToJson<bool>(isCarried);
    json['sortOrder'] = nativeToJson<int>(sortOrder);
    if (avatarTone != null) {
      json['avatarTone'] = nativeToJson<int?>(avatarTone);
    }
    return json;
  }

  GetMyPortionItems({
    required this.id,
    required this.kind,
    this.parent,
    required this.publicName,
    this.personalLabel,
    required this.isSelf,
    required this.isCarried,
    required this.sortOrder,
    this.avatarTone,
  });
}

@immutable
class GetMyPortionItemsParent {
  final String id;
  GetMyPortionItemsParent.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionItemsParent otherTyped = other as GetMyPortionItemsParent;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMyPortionItemsParent({
    required this.id,
  });
}

@immutable
class GetMyPortionNotPrinted {
  final String id;
  final EnumValue<ReasonCategory>? reasonCategory;
  final GetMyPortionNotPrintedSubject? subject;
  GetMyPortionNotPrinted.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  reasonCategory = json['reasonCategory'] == null ? null : reasonCategoryDeserializer(json['reasonCategory']),
  subject = json['subject'] == null ? null : GetMyPortionNotPrintedSubject.fromJson(json['subject']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionNotPrinted otherTyped = other as GetMyPortionNotPrinted;
    return id == otherTyped.id && 
    reasonCategory == otherTyped.reasonCategory && 
    subject == otherTyped.subject;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, reasonCategory.hashCode, subject.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
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

  GetMyPortionNotPrinted({
    required this.id,
    this.reasonCategory,
    this.subject,
  });
}

@immutable
class GetMyPortionNotPrintedSubject {
  final String id;
  GetMyPortionNotPrintedSubject.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionNotPrintedSubject otherTyped = other as GetMyPortionNotPrintedSubject;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetMyPortionNotPrintedSubject({
    required this.id,
  });
}

@immutable
class GetMyPortionData {
  final GetMyPortionUser? user;
  final List<GetMyPortionItems> items;
  final List<GetMyPortionNotPrinted> notPrinted;
  GetMyPortionData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetMyPortionUser.fromJson(json['user']),
  items = (json['items'] as List<dynamic>)
        .map((e) => GetMyPortionItems.fromJson(e))
        .toList(),
  notPrinted = (json['notPrinted'] as List<dynamic>)
        .map((e) => GetMyPortionNotPrinted.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionData otherTyped = other as GetMyPortionData;
    return user == otherTyped.user && 
    items == otherTyped.items && 
    notPrinted == otherTyped.notPrinted;
    
  }
  @override
  int get hashCode => Object.hashAll([user.hashCode, items.hashCode, notPrinted.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    json['items'] = items.map((e) => e.toJson()).toList();
    json['notPrinted'] = notPrinted.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyPortionData({
    this.user,
    required this.items,
    required this.notPrinted,
  });
}

@immutable
class GetMyPortionVariables {
  late final Optional<String>listId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetMyPortionVariables.fromJson(Map<String, dynamic> json) {
  
  
    listId = Optional.optional(nativeFromJson, nativeToJson);
    listId.value = json['listId'] == null ? null : nativeFromJson<String>(json['listId']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyPortionVariables otherTyped = other as GetMyPortionVariables;
    return listId == otherTyped.listId;
    
  }
  @override
  int get hashCode => listId.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if(listId.state == OptionalState.set) {
      json['listId'] = listId.toJson();
    }
    return json;
  }

  GetMyPortionVariables({
    required this.listId,
  });
}

