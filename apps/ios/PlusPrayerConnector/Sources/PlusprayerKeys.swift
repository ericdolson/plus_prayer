import Foundation

import FirebaseCore
import FirebaseDataConnect




public struct DailyStatsKey {
  
  public private(set) var date: LocalDate
  

  enum CodingKeys: String, CodingKey {
    
    case  date
    
  }
}

extension DailyStatsKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.date = try codecHelper.decode(LocalDate.self, forKey: .date, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(date, forKey: .date, container: &container)
      
      
    }
}

extension DailyStatsKey : Equatable {
  public static func == (lhs: DailyStatsKey, rhs: DailyStatsKey) -> Bool {
    
    if lhs.date != rhs.date {
      return false
    }
    
    return true
  }
}

extension DailyStatsKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.date)
    
  }
}

extension DailyStatsKey : Sendable {}



public struct ExternalPersonKey {
  
  public private(set) var id: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension ExternalPersonKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension ExternalPersonKey : Equatable {
  public static func == (lhs: ExternalPersonKey, rhs: ExternalPersonKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension ExternalPersonKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension ExternalPersonKey : Sendable {}



public struct PrayerListEntryKey {
  
  public private(set) var id: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension PrayerListEntryKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension PrayerListEntryKey : Equatable {
  public static func == (lhs: PrayerListEntryKey, rhs: PrayerListEntryKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension PrayerListEntryKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension PrayerListEntryKey : Sendable {}



public struct PrayerListPostKey {
  
  public private(set) var listId: UUID
  
  public private(set) var platform: String
  

  enum CodingKeys: String, CodingKey {
    
    case  listId
    
    case  platform
    
  }
}

extension PrayerListPostKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.listId = try codecHelper.decode(UUID.self, forKey: .listId, container: &container)
    
    self.platform = try codecHelper.decode(String.self, forKey: .platform, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(listId, forKey: .listId, container: &container)
      
      
      
      try codecHelper.encode(platform, forKey: .platform, container: &container)
      
      
    }
}

extension PrayerListPostKey : Equatable {
  public static func == (lhs: PrayerListPostKey, rhs: PrayerListPostKey) -> Bool {
    
    if lhs.listId != rhs.listId {
      return false
    }
    
    if lhs.platform != rhs.platform {
      return false
    }
    
    return true
  }
}

extension PrayerListPostKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.listId)
    
    hasher.combine(self.platform)
    
  }
}

extension PrayerListPostKey : Sendable {}



public struct PrayerListKey {
  
  public private(set) var id: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension PrayerListKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension PrayerListKey : Equatable {
  public static func == (lhs: PrayerListKey, rhs: PrayerListKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension PrayerListKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension PrayerListKey : Sendable {}



public struct PrayerSubjectLinkKey {
  
  public private(set) var prayerId: UUID
  
  public private(set) var subjectId: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  prayerId
    
    case  subjectId
    
  }
}

extension PrayerSubjectLinkKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.prayerId = try codecHelper.decode(UUID.self, forKey: .prayerId, container: &container)
    
    self.subjectId = try codecHelper.decode(UUID.self, forKey: .subjectId, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(prayerId, forKey: .prayerId, container: &container)
      
      
      
      try codecHelper.encode(subjectId, forKey: .subjectId, container: &container)
      
      
    }
}

extension PrayerSubjectLinkKey : Equatable {
  public static func == (lhs: PrayerSubjectLinkKey, rhs: PrayerSubjectLinkKey) -> Bool {
    
    if lhs.prayerId != rhs.prayerId {
      return false
    }
    
    if lhs.subjectId != rhs.subjectId {
      return false
    }
    
    return true
  }
}

extension PrayerSubjectLinkKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.prayerId)
    
    hasher.combine(self.subjectId)
    
  }
}

extension PrayerSubjectLinkKey : Sendable {}



public struct PrayerSubjectKey {
  
  public private(set) var id: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension PrayerSubjectKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension PrayerSubjectKey : Equatable {
  public static func == (lhs: PrayerSubjectKey, rhs: PrayerSubjectKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension PrayerSubjectKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension PrayerSubjectKey : Sendable {}



public struct PrayerKey {
  
  public private(set) var id: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension PrayerKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension PrayerKey : Equatable {
  public static func == (lhs: PrayerKey, rhs: PrayerKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension PrayerKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension PrayerKey : Sendable {}



public struct ReminderPreferenceKey {
  
  public private(set) var id: UUID
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension ReminderPreferenceKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension ReminderPreferenceKey : Equatable {
  public static func == (lhs: ReminderPreferenceKey, rhs: ReminderPreferenceKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension ReminderPreferenceKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension ReminderPreferenceKey : Sendable {}



public struct UserKey {
  
  public private(set) var id: String
  

  enum CodingKeys: String, CodingKey {
    
    case  id
    
  }
}

extension UserKey : Codable {
  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    self.id = try codecHelper.decode(String.self, forKey: .id, container: &container)
    
  }

  public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }
}

extension UserKey : Equatable {
  public static func == (lhs: UserKey, rhs: UserKey) -> Bool {
    
    if lhs.id != rhs.id {
      return false
    }
    
    return true
  }
}

extension UserKey : Hashable {
  public func hash(into hasher: inout Hasher) {
    
    hasher.combine(self.id)
    
  }
}

extension UserKey : Sendable {}


