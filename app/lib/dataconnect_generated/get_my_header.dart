part of 'plusprayer.dart';

class GetMyHeaderVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetMyHeaderVariablesBuilder(this._dataConnect, );
  Deserializer<GetMyHeaderData> dataDeserializer = (dynamic json)  => GetMyHeaderData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetMyHeaderData, void>> execute() {
    return ref().execute();
  }

  QueryRef<GetMyHeaderData, void> ref() {
    
    return _dataConnect.query("GetMyHeader", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetMyHeaderUser {
  final String id;
  final String? displayName;
  final String? locale;
  final String? timezone;
  final String planTier;
  final int includeLimit;
  final Timestamp? trialStartedAt;
  final Timestamp? entitlementExpiresAt;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastListLocalDate;
  final int graceDays;
  final bool graceOfferPending;
  final bool graceOffersEnabled;
  final bool listLiveOptIn;
  final bool showNamesInNotifications;
  final Timestamp? selfNameChangedAt;
  final List<GetMyHeaderUserSelf> self;
  GetMyHeaderUser.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  displayName = json['displayName'] == null ? null : nativeFromJson<String>(json['displayName']),
  locale = json['locale'] == null ? null : nativeFromJson<String>(json['locale']),
  timezone = json['timezone'] == null ? null : nativeFromJson<String>(json['timezone']),
  planTier = nativeFromJson<String>(json['planTier']),
  includeLimit = nativeFromJson<int>(json['includeLimit']),
  trialStartedAt = json['trialStartedAt'] == null ? null : Timestamp.fromJson(json['trialStartedAt']),
  entitlementExpiresAt = json['entitlementExpiresAt'] == null ? null : Timestamp.fromJson(json['entitlementExpiresAt']),
  currentStreak = nativeFromJson<int>(json['currentStreak']),
  bestStreak = nativeFromJson<int>(json['bestStreak']),
  lastListLocalDate = json['lastListLocalDate'] == null ? null : nativeFromJson<DateTime>(json['lastListLocalDate']),
  graceDays = nativeFromJson<int>(json['graceDays']),
  graceOfferPending = nativeFromJson<bool>(json['graceOfferPending']),
  graceOffersEnabled = nativeFromJson<bool>(json['graceOffersEnabled']),
  listLiveOptIn = nativeFromJson<bool>(json['listLiveOptIn']),
  showNamesInNotifications = nativeFromJson<bool>(json['showNamesInNotifications']),
  selfNameChangedAt = json['selfNameChangedAt'] == null ? null : Timestamp.fromJson(json['selfNameChangedAt']),
  self = (json['self'] as List<dynamic>)
        .map((e) => GetMyHeaderUserSelf.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyHeaderUser otherTyped = other as GetMyHeaderUser;
    return id == otherTyped.id && 
    displayName == otherTyped.displayName && 
    locale == otherTyped.locale && 
    timezone == otherTyped.timezone && 
    planTier == otherTyped.planTier && 
    includeLimit == otherTyped.includeLimit && 
    trialStartedAt == otherTyped.trialStartedAt && 
    entitlementExpiresAt == otherTyped.entitlementExpiresAt && 
    currentStreak == otherTyped.currentStreak && 
    bestStreak == otherTyped.bestStreak && 
    lastListLocalDate == otherTyped.lastListLocalDate && 
    graceDays == otherTyped.graceDays && 
    graceOfferPending == otherTyped.graceOfferPending && 
    graceOffersEnabled == otherTyped.graceOffersEnabled && 
    listLiveOptIn == otherTyped.listLiveOptIn && 
    showNamesInNotifications == otherTyped.showNamesInNotifications && 
    selfNameChangedAt == otherTyped.selfNameChangedAt && 
    self == otherTyped.self;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, displayName.hashCode, locale.hashCode, timezone.hashCode, planTier.hashCode, includeLimit.hashCode, trialStartedAt.hashCode, entitlementExpiresAt.hashCode, currentStreak.hashCode, bestStreak.hashCode, lastListLocalDate.hashCode, graceDays.hashCode, graceOfferPending.hashCode, graceOffersEnabled.hashCode, listLiveOptIn.hashCode, showNamesInNotifications.hashCode, selfNameChangedAt.hashCode, self.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    if (displayName != null) {
      json['displayName'] = nativeToJson<String?>(displayName);
    }
    if (locale != null) {
      json['locale'] = nativeToJson<String?>(locale);
    }
    if (timezone != null) {
      json['timezone'] = nativeToJson<String?>(timezone);
    }
    json['planTier'] = nativeToJson<String>(planTier);
    json['includeLimit'] = nativeToJson<int>(includeLimit);
    if (trialStartedAt != null) {
      json['trialStartedAt'] = trialStartedAt!.toJson();
    }
    if (entitlementExpiresAt != null) {
      json['entitlementExpiresAt'] = entitlementExpiresAt!.toJson();
    }
    json['currentStreak'] = nativeToJson<int>(currentStreak);
    json['bestStreak'] = nativeToJson<int>(bestStreak);
    if (lastListLocalDate != null) {
      json['lastListLocalDate'] = nativeToJson<DateTime?>(lastListLocalDate);
    }
    json['graceDays'] = nativeToJson<int>(graceDays);
    json['graceOfferPending'] = nativeToJson<bool>(graceOfferPending);
    json['graceOffersEnabled'] = nativeToJson<bool>(graceOffersEnabled);
    json['listLiveOptIn'] = nativeToJson<bool>(listLiveOptIn);
    json['showNamesInNotifications'] = nativeToJson<bool>(showNamesInNotifications);
    if (selfNameChangedAt != null) {
      json['selfNameChangedAt'] = selfNameChangedAt!.toJson();
    }
    json['self'] = self.map((e) => e.toJson()).toList();
    return json;
  }

  GetMyHeaderUser({
    required this.id,
    this.displayName,
    this.locale,
    this.timezone,
    required this.planTier,
    required this.includeLimit,
    this.trialStartedAt,
    this.entitlementExpiresAt,
    required this.currentStreak,
    required this.bestStreak,
    this.lastListLocalDate,
    required this.graceDays,
    required this.graceOfferPending,
    required this.graceOffersEnabled,
    required this.listLiveOptIn,
    required this.showNamesInNotifications,
    this.selfNameChangedAt,
    required this.self,
  });
}

@immutable
class GetMyHeaderUserSelf {
  final String id;
  final String publicName;
  final int? avatarTone;
  final String? avatarPath;
  GetMyHeaderUserSelf.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  publicName = nativeFromJson<String>(json['publicName']),
  avatarTone = json['avatarTone'] == null ? null : nativeFromJson<int>(json['avatarTone']),
  avatarPath = json['avatarPath'] == null ? null : nativeFromJson<String>(json['avatarPath']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyHeaderUserSelf otherTyped = other as GetMyHeaderUserSelf;
    return id == otherTyped.id && 
    publicName == otherTyped.publicName && 
    avatarTone == otherTyped.avatarTone && 
    avatarPath == otherTyped.avatarPath;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, publicName.hashCode, avatarTone.hashCode, avatarPath.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['publicName'] = nativeToJson<String>(publicName);
    if (avatarTone != null) {
      json['avatarTone'] = nativeToJson<int?>(avatarTone);
    }
    if (avatarPath != null) {
      json['avatarPath'] = nativeToJson<String?>(avatarPath);
    }
    return json;
  }

  GetMyHeaderUserSelf({
    required this.id,
    required this.publicName,
    this.avatarTone,
    this.avatarPath,
  });
}

@immutable
class GetMyHeaderData {
  final GetMyHeaderUser? user;
  GetMyHeaderData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetMyHeaderUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetMyHeaderData otherTyped = other as GetMyHeaderData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetMyHeaderData({
    this.user,
  });
}

