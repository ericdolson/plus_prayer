import Foundation

import FirebaseCore
import FirebaseDataConnect




















// MARK: Common Enums

public enum OrderDirection: String, Codable, Sendable {
  case ASC = "ASC"
  case DESC = "DESC"
  }

public enum SearchQueryFormat: String, Codable, Sendable {
  case QUERY = "QUERY"
  case PLAIN = "PLAIN"
  case PHRASE = "PHRASE"
  case ADVANCED = "ADVANCED"
  }


// MARK: Connector Enums

public enum EntrySource: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case APP
  case SOCIAL
  case BASE_SET
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .APP: return "APP"
    case .SOCIAL: return "SOCIAL"
    case .BASE_SET: return "BASE_SET"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "APP": self = .APP
    case "SOCIAL": self = .SOCIAL
    case "BASE_SET": self = .BASE_SET
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = EntrySource(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: EntrySource, rhs: EntrySource) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum ExternalSource: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case SOCIAL
  case BASE_SET
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .SOCIAL: return "SOCIAL"
    case .BASE_SET: return "BASE_SET"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "SOCIAL": self = .SOCIAL
    case "BASE_SET": self = .BASE_SET
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = ExternalSource(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: ExternalSource, rhs: ExternalSource) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum ListScope: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case GLOBAL
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .GLOBAL: return "GLOBAL"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "GLOBAL": self = .GLOBAL
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = ListScope(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: ListScope, rhs: ListScope) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum ModerationStatus: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case APPROVED
  case HELD
  case EXCLUDED
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .APPROVED: return "APPROVED"
    case .HELD: return "HELD"
    case .EXCLUDED: return "EXCLUDED"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "APPROVED": self = .APPROVED
    case "HELD": self = .HELD
    case "EXCLUDED": self = .EXCLUDED
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = ModerationStatus(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: ModerationStatus, rhs: ModerationStatus) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum PrayerEndedBy: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case AMEN
  case AUTO
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .AMEN: return "AMEN"
    case .AUTO: return "AUTO"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "AMEN": self = .AMEN
    case "AUTO": self = .AUTO
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = PrayerEndedBy(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: PrayerEndedBy, rhs: PrayerEndedBy) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum PrayerMode: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case MANUAL
  case GUIDED
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .MANUAL: return "MANUAL"
    case .GUIDED: return "GUIDED"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "MANUAL": self = .MANUAL
    case "GUIDED": self = .GUIDED
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = PrayerMode(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: PrayerMode, rhs: PrayerMode) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum ReasonCategory: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case LANGUAGE
  case CONTACT_OR_LINK
  case NAME_CHANGES
  case OTHER
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .LANGUAGE: return "LANGUAGE"
    case .CONTACT_OR_LINK: return "CONTACT_OR_LINK"
    case .NAME_CHANGES: return "NAME_CHANGES"
    case .OTHER: return "OTHER"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "LANGUAGE": self = .LANGUAGE
    case "CONTACT_OR_LINK": self = .CONTACT_OR_LINK
    case "NAME_CHANGES": self = .NAME_CHANGES
    case "OTHER": self = .OTHER
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = ReasonCategory(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: ReasonCategory, rhs: ReasonCategory) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum ReminderSlot: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case MORNING
  case MIDDAY
  case EVENING
  case CUSTOM
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .MORNING: return "MORNING"
    case .MIDDAY: return "MIDDAY"
    case .EVENING: return "EVENING"
    case .CUSTOM: return "CUSTOM"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "MORNING": self = .MORNING
    case "MIDDAY": self = .MIDDAY
    case "EVENING": self = .EVENING
    case "CUSTOM": self = .CUSTOM
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = ReminderSlot(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: ReminderSlot, rhs: ReminderSlot) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum SubjectKind: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case SOUL
  case INTENTION
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .SOUL: return "SOUL"
    case .INTENTION: return "INTENTION"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "SOUL": self = .SOUL
    case "INTENTION": self = .INTENTION
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = SubjectKind(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: SubjectKind, rhs: SubjectKind) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum SubjectResolution: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case ANSWERED
  case RELEASED
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .ANSWERED: return "ANSWERED"
    case .RELEASED: return "RELEASED"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "ANSWERED": self = .ANSWERED
    case "RELEASED": self = .RELEASED
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = SubjectResolution(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: SubjectResolution, rhs: SubjectResolution) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

public enum SubjectStatus: Codable, Equatable, Hashable, RawRepresentable, Sendable {
  public typealias RawValue = String

  case ACTIVE
  case ARCHIVED
  case PURGED
  
  case _UNKNOWN(String) /// Sending _UNKNOWN as a Variable to server in a mutation is an error.

  public var rawValue: String {
    switch self {
    case .ACTIVE: return "ACTIVE"
    case .ARCHIVED: return "ARCHIVED"
    case .PURGED: return "PURGED"
    case ._UNKNOWN(let value): return value
    }
  }

  public init?(rawValue: String) {
    switch rawValue {
    case "ACTIVE": self = .ACTIVE
    case "ARCHIVED": self = .ARCHIVED
    case "PURGED": self = .PURGED
    default: self = ._UNKNOWN(rawValue)
    }
  }

  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)

    if let _self = SubjectStatus(rawValue: value) {
      self = _self
    } else {
      self = ._UNKNOWN(value)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case ._UNKNOWN(_): try container.encode("_UNKNOWN")
    default: try container.encode(rawValue)
    }
  }

  public static func == (lhs: SubjectStatus, rhs: SubjectStatus) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }
}

// End enum definitions









public class LogPrayerMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "LogPrayer"

  public typealias Ref = MutationRef<LogPrayerMutation.Data,LogPrayerMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID

  
        
        public var
startedAt: Timestamp

  
        
        public var
prayedAt: Timestamp

  
        
        public var
durationSeconds: Int

  
        
        public var
localDate: LocalDate

  
        
        public var
timezone: String

  
        @OptionalVariable
        public var
communityListId: UUID?

  
        
        public var
listContextNumber: Int

  
        @OptionalVariable
        public var
note: String?

  
        
        public var
subjectIds: [UUID]


    
    
    
    public init (
        
id: UUID
,
        
startedAt: Timestamp
,
        
prayedAt: Timestamp
,
        
durationSeconds: Int
,
        
localDate: LocalDate
,
        
timezone: String
,
        
listContextNumber: Int
,
        
subjectIds: [UUID]

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.id = id
        self.startedAt = startedAt
        self.prayedAt = prayedAt
        self.durationSeconds = durationSeconds
        self.localDate = localDate
        self.timezone = timezone
        self.listContextNumber = listContextNumber
        self.subjectIds = subjectIds
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id && 
              lhs.startedAt == rhs.startedAt && 
              lhs.prayedAt == rhs.prayedAt && 
              lhs.durationSeconds == rhs.durationSeconds && 
              lhs.localDate == rhs.localDate && 
              lhs.timezone == rhs.timezone && 
              lhs.communityListId == rhs.communityListId && 
              lhs.listContextNumber == rhs.listContextNumber && 
              lhs.note == rhs.note && 
              lhs.subjectIds == rhs.subjectIds
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
  hasher.combine(startedAt)
  
  hasher.combine(prayedAt)
  
  hasher.combine(durationSeconds)
  
  hasher.combine(localDate)
  
  hasher.combine(timezone)
  
  hasher.combine(communityListId)
  
  hasher.combine(listContextNumber)
  
  hasher.combine(note)
  
  hasher.combine(subjectIds)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
      case startedAt
      
      case prayedAt
      
      case durationSeconds
      
      case localDate
      
      case timezone
      
      case communityListId
      
      case listContextNumber
      
      case note
      
      case subjectIds
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
      
      try codecHelper.encode(startedAt, forKey: .startedAt, container: &container)
      
      
      
      try codecHelper.encode(prayedAt, forKey: .prayedAt, container: &container)
      
      
      
      try codecHelper.encode(durationSeconds, forKey: .durationSeconds, container: &container)
      
      
      
      try codecHelper.encode(localDate, forKey: .localDate, container: &container)
      
      
      
      try codecHelper.encode(timezone, forKey: .timezone, container: &container)
      
      
      if $communityListId.isSet { 
      try codecHelper.encode(communityListId, forKey: .communityListId, container: &container)
      }
      
      
      try codecHelper.encode(listContextNumber, forKey: .listContextNumber, container: &container)
      
      
      if $note.isSet { 
      try codecHelper.encode(note, forKey: .note, container: &container)
      }
      
      
      try codecHelper.encode(subjectIds, forKey: .subjectIds, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
_execute: Int?

  }

  public func ref(
        
id: UUID
,
startedAt: Timestamp
,
prayedAt: Timestamp
,
durationSeconds: Int
,
localDate: LocalDate
,
timezone: String
,
listContextNumber: Int
,
subjectIds: [UUID]

        
        ,
        _ optionalVars: ((inout LogPrayerMutation.Variables)->())? = nil
        ) -> MutationRef<LogPrayerMutation.Data,LogPrayerMutation.Variables>  {
        var variables = LogPrayerMutation.Variables(id:id,startedAt:startedAt,prayedAt:prayedAt,durationSeconds:durationSeconds,localDate:localDate,timezone:timezone,listContextNumber:listContextNumber,subjectIds:subjectIds)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "LogPrayer", variables: variables, resultsDataType:LogPrayerMutation.Data.self)
        return ref as MutationRef<LogPrayerMutation.Data,LogPrayerMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID
,
startedAt: Timestamp
,
prayedAt: Timestamp
,
durationSeconds: Int
,
localDate: LocalDate
,
timezone: String
,
listContextNumber: Int
,
subjectIds: [UUID]

        
        ,
        _ optionalVars: (@MainActor (inout LogPrayerMutation.Variables)->())? = nil
        ) async throws -> OperationResult<LogPrayerMutation.Data> {
        var variables = LogPrayerMutation.Variables(id:id,startedAt:startedAt,prayedAt:prayedAt,durationSeconds:durationSeconds,localDate:localDate,timezone:timezone,listContextNumber:listContextNumber,subjectIds:subjectIds)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "LogPrayer", variables: variables, resultsDataType:LogPrayerMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class UpdatePrayerNoteMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "UpdatePrayerNote"

  public typealias Ref = MutationRef<UpdatePrayerNoteMutation.Data,UpdatePrayerNoteMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID

  
        @OptionalVariable
        public var
note: String?


    
    
    
    public init (
        
id: UUID

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.id = id
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id && 
              lhs.note == rhs.note
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
  hasher.combine(note)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
      case note
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
      if $note.isSet { 
      try codecHelper.encode(note, forKey: .note, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
prayer_updateMany: Int

  }

  public func ref(
        
id: UUID

        
        ,
        _ optionalVars: ((inout UpdatePrayerNoteMutation.Variables)->())? = nil
        ) -> MutationRef<UpdatePrayerNoteMutation.Data,UpdatePrayerNoteMutation.Variables>  {
        var variables = UpdatePrayerNoteMutation.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "UpdatePrayerNote", variables: variables, resultsDataType:UpdatePrayerNoteMutation.Data.self)
        return ref as MutationRef<UpdatePrayerNoteMutation.Data,UpdatePrayerNoteMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        
        ,
        _ optionalVars: (@MainActor (inout UpdatePrayerNoteMutation.Variables)->())? = nil
        ) async throws -> OperationResult<UpdatePrayerNoteMutation.Data> {
        var variables = UpdatePrayerNoteMutation.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "UpdatePrayerNote", variables: variables, resultsDataType:UpdatePrayerNoteMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class ReorderSubjectsMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "ReorderSubjects"

  public typealias Ref = MutationRef<ReorderSubjectsMutation.Data,ReorderSubjectsMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
orderedIds: [UUID]


    
    
    
    public init (
        
orderedIds: [UUID]

        
        ) {
        self.orderedIds = orderedIds
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.orderedIds == rhs.orderedIds
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(orderedIds)
  
}

    enum CodingKeys: String, CodingKey {
      
      case orderedIds
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(orderedIds, forKey: .orderedIds, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
_execute: Int?

  }

  public func ref(
        
orderedIds: [UUID]

        ) -> MutationRef<ReorderSubjectsMutation.Data,ReorderSubjectsMutation.Variables>  {
        var variables = ReorderSubjectsMutation.Variables(orderedIds:orderedIds)
        

        let ref = dataConnect.mutation(name: "ReorderSubjects", variables: variables, resultsDataType:ReorderSubjectsMutation.Data.self)
        return ref as MutationRef<ReorderSubjectsMutation.Data,ReorderSubjectsMutation.Variables>
   }

  @MainActor
   public func execute( 
        
orderedIds: [UUID]

        ) async throws -> OperationResult<ReorderSubjectsMutation.Data> {
        var variables = ReorderSubjectsMutation.Variables(orderedIds:orderedIds)
        

        let ref = dataConnect.mutation(name: "ReorderSubjects", variables: variables, resultsDataType:ReorderSubjectsMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class MarkIntentionAnsweredMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "MarkIntentionAnswered"

  public typealias Ref = MutationRef<MarkIntentionAnsweredMutation.Data,MarkIntentionAnsweredMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID


    
    
    
    public init (
        
id: UUID

        
        ) {
        self.id = id
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
prayerSubject_updateMany: Int

  }

  public func ref(
        
id: UUID

        ) -> MutationRef<MarkIntentionAnsweredMutation.Data,MarkIntentionAnsweredMutation.Variables>  {
        var variables = MarkIntentionAnsweredMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "MarkIntentionAnswered", variables: variables, resultsDataType:MarkIntentionAnsweredMutation.Data.self)
        return ref as MutationRef<MarkIntentionAnsweredMutation.Data,MarkIntentionAnsweredMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        ) async throws -> OperationResult<MarkIntentionAnsweredMutation.Data> {
        var variables = MarkIntentionAnsweredMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "MarkIntentionAnswered", variables: variables, resultsDataType:MarkIntentionAnsweredMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class ReleaseIntentionMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "ReleaseIntention"

  public typealias Ref = MutationRef<ReleaseIntentionMutation.Data,ReleaseIntentionMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID


    
    
    
    public init (
        
id: UUID

        
        ) {
        self.id = id
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
prayerSubject_updateMany: Int

  }

  public func ref(
        
id: UUID

        ) -> MutationRef<ReleaseIntentionMutation.Data,ReleaseIntentionMutation.Variables>  {
        var variables = ReleaseIntentionMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "ReleaseIntention", variables: variables, resultsDataType:ReleaseIntentionMutation.Data.self)
        return ref as MutationRef<ReleaseIntentionMutation.Data,ReleaseIntentionMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        ) async throws -> OperationResult<ReleaseIntentionMutation.Data> {
        var variables = ReleaseIntentionMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "ReleaseIntention", variables: variables, resultsDataType:ReleaseIntentionMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class ArchiveSubjectMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "ArchiveSubject"

  public typealias Ref = MutationRef<ArchiveSubjectMutation.Data,ArchiveSubjectMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID


    
    
    
    public init (
        
id: UUID

        
        ) {
        self.id = id
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
prayerSubject_updateMany: Int



public var 
cascade: Int

  }

  public func ref(
        
id: UUID

        ) -> MutationRef<ArchiveSubjectMutation.Data,ArchiveSubjectMutation.Variables>  {
        var variables = ArchiveSubjectMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "ArchiveSubject", variables: variables, resultsDataType:ArchiveSubjectMutation.Data.self)
        return ref as MutationRef<ArchiveSubjectMutation.Data,ArchiveSubjectMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        ) async throws -> OperationResult<ArchiveSubjectMutation.Data> {
        var variables = ArchiveSubjectMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "ArchiveSubject", variables: variables, resultsDataType:ArchiveSubjectMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class PurgeSubjectMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "PurgeSubject"

  public typealias Ref = MutationRef<PurgeSubjectMutation.Data,PurgeSubjectMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID


    
    
    
    public init (
        
id: UUID

        
        ) {
        self.id = id
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
prayerSubject_updateMany: Int



public var 
cascade: Int

  }

  public func ref(
        
id: UUID

        ) -> MutationRef<PurgeSubjectMutation.Data,PurgeSubjectMutation.Variables>  {
        var variables = PurgeSubjectMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "PurgeSubject", variables: variables, resultsDataType:PurgeSubjectMutation.Data.self)
        return ref as MutationRef<PurgeSubjectMutation.Data,PurgeSubjectMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        ) async throws -> OperationResult<PurgeSubjectMutation.Data> {
        var variables = PurgeSubjectMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "PurgeSubject", variables: variables, resultsDataType:PurgeSubjectMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class SetSubjectAvatarToneMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "SetSubjectAvatarTone"

  public typealias Ref = MutationRef<SetSubjectAvatarToneMutation.Data,SetSubjectAvatarToneMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID

  
        @OptionalVariable
        public var
avatarTone: Int?


    
    
    
    public init (
        
id: UUID

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.id = id
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id && 
              lhs.avatarTone == rhs.avatarTone
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
  hasher.combine(avatarTone)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
      case avatarTone
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
      if $avatarTone.isSet { 
      try codecHelper.encode(avatarTone, forKey: .avatarTone, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
prayerSubject_updateMany: Int

  }

  public func ref(
        
id: UUID

        
        ,
        _ optionalVars: ((inout SetSubjectAvatarToneMutation.Variables)->())? = nil
        ) -> MutationRef<SetSubjectAvatarToneMutation.Data,SetSubjectAvatarToneMutation.Variables>  {
        var variables = SetSubjectAvatarToneMutation.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "SetSubjectAvatarTone", variables: variables, resultsDataType:SetSubjectAvatarToneMutation.Data.self)
        return ref as MutationRef<SetSubjectAvatarToneMutation.Data,SetSubjectAvatarToneMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        
        ,
        _ optionalVars: (@MainActor (inout SetSubjectAvatarToneMutation.Variables)->())? = nil
        ) async throws -> OperationResult<SetSubjectAvatarToneMutation.Data> {
        var variables = SetSubjectAvatarToneMutation.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "SetSubjectAvatarTone", variables: variables, resultsDataType:SetSubjectAvatarToneMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class UpdateMySettingsMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "UpdateMySettings"

  public typealias Ref = MutationRef<UpdateMySettingsMutation.Data,UpdateMySettingsMutation.Variables>

  public struct Variables: OperationVariable {
  
        @OptionalVariable
        public var
locale: String?

  
        @OptionalVariable
        public var
timezone: String?

  
        @OptionalVariable
        public var
listLiveOptIn: Bool?

  
        @OptionalVariable
        public var
showNamesInNotifications: Bool?

  
        @OptionalVariable
        public var
graceOffersEnabled: Bool?


    
    
    
    public init (
        
        
        
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.locale == rhs.locale && 
              lhs.timezone == rhs.timezone && 
              lhs.listLiveOptIn == rhs.listLiveOptIn && 
              lhs.showNamesInNotifications == rhs.showNamesInNotifications && 
              lhs.graceOffersEnabled == rhs.graceOffersEnabled
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(locale)
  
  hasher.combine(timezone)
  
  hasher.combine(listLiveOptIn)
  
  hasher.combine(showNamesInNotifications)
  
  hasher.combine(graceOffersEnabled)
  
}

    enum CodingKeys: String, CodingKey {
      
      case locale
      
      case timezone
      
      case listLiveOptIn
      
      case showNamesInNotifications
      
      case graceOffersEnabled
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      if $locale.isSet { 
      try codecHelper.encode(locale, forKey: .locale, container: &container)
      }
      
      if $timezone.isSet { 
      try codecHelper.encode(timezone, forKey: .timezone, container: &container)
      }
      
      if $listLiveOptIn.isSet { 
      try codecHelper.encode(listLiveOptIn, forKey: .listLiveOptIn, container: &container)
      }
      
      if $showNamesInNotifications.isSet { 
      try codecHelper.encode(showNamesInNotifications, forKey: .showNamesInNotifications, container: &container)
      }
      
      if $graceOffersEnabled.isSet { 
      try codecHelper.encode(graceOffersEnabled, forKey: .graceOffersEnabled, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
user_update: UserKey?

  }

  public func ref(
        
        
        
        _ optionalVars: ((inout UpdateMySettingsMutation.Variables)->())? = nil
        ) -> MutationRef<UpdateMySettingsMutation.Data,UpdateMySettingsMutation.Variables>  {
        var variables = UpdateMySettingsMutation.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "UpdateMySettings", variables: variables, resultsDataType:UpdateMySettingsMutation.Data.self)
        return ref as MutationRef<UpdateMySettingsMutation.Data,UpdateMySettingsMutation.Variables>
   }

  @MainActor
   public func execute( 
        
        
        
        _ optionalVars: (@MainActor (inout UpdateMySettingsMutation.Variables)->())? = nil
        ) async throws -> OperationResult<UpdateMySettingsMutation.Data> {
        var variables = UpdateMySettingsMutation.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "UpdateMySettings", variables: variables, resultsDataType:UpdateMySettingsMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class CreateReminderMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "CreateReminder"

  public typealias Ref = MutationRef<CreateReminderMutation.Data,CreateReminderMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
slot: ReminderSlot

  
        @OptionalVariable
        public var
enabled: Bool?

  
        
        public var
localTime: String

  
        @OptionalVariable
        public var
label: String?


    
    
    
    public init (
        
slot: ReminderSlot
,
        
localTime: String

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.slot = slot
        self.localTime = localTime
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.slot == rhs.slot && 
              lhs.enabled == rhs.enabled && 
              lhs.localTime == rhs.localTime && 
              lhs.label == rhs.label
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(slot)
  
  hasher.combine(enabled)
  
  hasher.combine(localTime)
  
  hasher.combine(label)
  
}

    enum CodingKeys: String, CodingKey {
      
      case slot
      
      case enabled
      
      case localTime
      
      case label
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(slot, forKey: .slot, container: &container)
      
      
      if $enabled.isSet { 
      try codecHelper.encode(enabled, forKey: .enabled, container: &container)
      }
      
      
      try codecHelper.encode(localTime, forKey: .localTime, container: &container)
      
      
      if $label.isSet { 
      try codecHelper.encode(label, forKey: .label, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {



public var 
reminderPreference_insert: ReminderPreferenceKey

  }

  public func ref(
        
slot: ReminderSlot
,
localTime: String

        
        ,
        _ optionalVars: ((inout CreateReminderMutation.Variables)->())? = nil
        ) -> MutationRef<CreateReminderMutation.Data,CreateReminderMutation.Variables>  {
        var variables = CreateReminderMutation.Variables(slot:slot,localTime:localTime)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "CreateReminder", variables: variables, resultsDataType:CreateReminderMutation.Data.self)
        return ref as MutationRef<CreateReminderMutation.Data,CreateReminderMutation.Variables>
   }

  @MainActor
   public func execute( 
        
slot: ReminderSlot
,
localTime: String

        
        ,
        _ optionalVars: (@MainActor (inout CreateReminderMutation.Variables)->())? = nil
        ) async throws -> OperationResult<CreateReminderMutation.Data> {
        var variables = CreateReminderMutation.Variables(slot:slot,localTime:localTime)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "CreateReminder", variables: variables, resultsDataType:CreateReminderMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class UpdateReminderMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "UpdateReminder"

  public typealias Ref = MutationRef<UpdateReminderMutation.Data,UpdateReminderMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID

  
        @OptionalVariable
        public var
enabled: Bool?

  
        @OptionalVariable
        public var
localTime: String?

  
        @OptionalVariable
        public var
label: String?


    
    
    
    public init (
        
id: UUID

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.id = id
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id && 
              lhs.enabled == rhs.enabled && 
              lhs.localTime == rhs.localTime && 
              lhs.label == rhs.label
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
  hasher.combine(enabled)
  
  hasher.combine(localTime)
  
  hasher.combine(label)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
      case enabled
      
      case localTime
      
      case label
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
      if $enabled.isSet { 
      try codecHelper.encode(enabled, forKey: .enabled, container: &container)
      }
      
      if $localTime.isSet { 
      try codecHelper.encode(localTime, forKey: .localTime, container: &container)
      }
      
      if $label.isSet { 
      try codecHelper.encode(label, forKey: .label, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
reminderPreference_updateMany: Int

  }

  public func ref(
        
id: UUID

        
        ,
        _ optionalVars: ((inout UpdateReminderMutation.Variables)->())? = nil
        ) -> MutationRef<UpdateReminderMutation.Data,UpdateReminderMutation.Variables>  {
        var variables = UpdateReminderMutation.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "UpdateReminder", variables: variables, resultsDataType:UpdateReminderMutation.Data.self)
        return ref as MutationRef<UpdateReminderMutation.Data,UpdateReminderMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        
        ,
        _ optionalVars: (@MainActor (inout UpdateReminderMutation.Variables)->())? = nil
        ) async throws -> OperationResult<UpdateReminderMutation.Data> {
        var variables = UpdateReminderMutation.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.mutation(name: "UpdateReminder", variables: variables, resultsDataType:UpdateReminderMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class DeleteReminderMutation{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "DeleteReminder"

  public typealias Ref = MutationRef<DeleteReminderMutation.Data,DeleteReminderMutation.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID


    
    
    
    public init (
        
id: UUID

        
        ) {
        self.id = id
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {


public var 
reminderPreference_deleteMany: Int

  }

  public func ref(
        
id: UUID

        ) -> MutationRef<DeleteReminderMutation.Data,DeleteReminderMutation.Variables>  {
        var variables = DeleteReminderMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "DeleteReminder", variables: variables, resultsDataType:DeleteReminderMutation.Data.self)
        return ref as MutationRef<DeleteReminderMutation.Data,DeleteReminderMutation.Variables>
   }

  @MainActor
   public func execute( 
        
id: UUID

        ) async throws -> OperationResult<DeleteReminderMutation.Data> {
        var variables = DeleteReminderMutation.Variables(id:id)
        

        let ref = dataConnect.mutation(name: "DeleteReminder", variables: variables, resultsDataType:DeleteReminderMutation.Data.self)
        
        return try await ref.execute()
        
   }
}






public class GetCurrentListMetaQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetCurrentListMeta"

  public typealias Ref = QueryRefObservation<GetCurrentListMetaQuery.Data,GetCurrentListMetaQuery.Variables>

  public struct Variables: OperationVariable {

    
    
  }

  public struct Data: Decodable, Sendable {




public struct PrayerList: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
listNumber: Int



public var 
listDate: LocalDate



public var 
status: String



public var 
currentFrom: Timestamp?



public var 
closesAt: Timestamp?



public var 
videoPublishedAt: Timestamp?



public var 
videoPath: String?



public var 
sealVariant: Int?



public var 
soulCount: Int



public var 
intentionCount: Int



public var 
prayerCount: Int



public var 
prayerSeconds: Int





public struct PrayerListPost: Decodable, Sendable  {
  


public var 
platform: String



public var 
url: String?


  

  
  enum CodingKeys: String, CodingKey {
    
    case platform
    
    case url
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.platform = try codecHelper.decode(String.self, forKey: .platform, container: &container)
    
    
    
    self.url = try codecHelper.decode(String?.self, forKey: .url, container: &container)
    
    
  }
}
public var 
prayerListPosts_on_list: [PrayerListPost]


  
  public var prayerListKey: PrayerListKey {
    return PrayerListKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerList, rhs: PrayerList) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case listNumber
    
    case listDate
    
    case status
    
    case currentFrom
    
    case closesAt
    
    case videoPublishedAt
    
    case videoPath
    
    case sealVariant
    
    case soulCount
    
    case intentionCount
    
    case prayerCount
    
    case prayerSeconds
    
    case prayerListPosts_on_list
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.listNumber = try codecHelper.decode(Int.self, forKey: .listNumber, container: &container)
    
    
    
    self.listDate = try codecHelper.decode(LocalDate.self, forKey: .listDate, container: &container)
    
    
    
    self.status = try codecHelper.decode(String.self, forKey: .status, container: &container)
    
    
    
    self.currentFrom = try codecHelper.decode(Timestamp?.self, forKey: .currentFrom, container: &container)
    
    
    
    self.closesAt = try codecHelper.decode(Timestamp?.self, forKey: .closesAt, container: &container)
    
    
    
    self.videoPublishedAt = try codecHelper.decode(Timestamp?.self, forKey: .videoPublishedAt, container: &container)
    
    
    
    self.videoPath = try codecHelper.decode(String?.self, forKey: .videoPath, container: &container)
    
    
    
    self.sealVariant = try codecHelper.decode(Int?.self, forKey: .sealVariant, container: &container)
    
    
    
    self.soulCount = try codecHelper.decode(Int.self, forKey: .soulCount, container: &container)
    
    
    
    self.intentionCount = try codecHelper.decode(Int.self, forKey: .intentionCount, container: &container)
    
    
    
    self.prayerCount = try codecHelper.decode(Int.self, forKey: .prayerCount, container: &container)
    
    
    
    self.prayerSeconds = try codecHelper.decode(Int.self, forKey: .prayerSeconds, container: &container)
    
    
    self.prayerListPosts_on_list = try codecHelper.decode([PrayerListPost].self, forKey: .prayerListPosts_on_list, container: &container)
    
    
  }
}
public var 
prayerLists: [PrayerList]

  }

  public func ref(
        
        ) -> QueryRefObservation<GetCurrentListMetaQuery.Data,GetCurrentListMetaQuery.Variables>  {
        var variables = GetCurrentListMetaQuery.Variables()
        

        let ref = dataConnect.query(name: "GetCurrentListMeta", variables: variables, resultsDataType:GetCurrentListMetaQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetCurrentListMetaQuery.Data,GetCurrentListMetaQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        ) async throws -> OperationResult<GetCurrentListMetaQuery.Data> {
        var variables = GetCurrentListMetaQuery.Variables()
        

        let ref = dataConnect.query(name: "GetCurrentListMeta", variables: variables, resultsDataType:GetCurrentListMetaQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetCurrentListMetaQuery.Data,GetCurrentListMetaQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetPastListsQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetPastLists"

  public typealias Ref = QueryRefObservation<GetPastListsQuery.Data,GetPastListsQuery.Variables>

  public struct Variables: OperationVariable {
  
        @OptionalVariable
        public var
limit: Int?

  
        @OptionalVariable
        public var
offset: Int?


    
    
    
    public init (
        
        
        
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.limit == rhs.limit && 
              lhs.offset == rhs.offset
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(limit)
  
  hasher.combine(offset)
  
}

    enum CodingKeys: String, CodingKey {
      
      case limit
      
      case offset
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      if $limit.isSet { 
      try codecHelper.encode(limit, forKey: .limit, container: &container)
      }
      
      if $offset.isSet { 
      try codecHelper.encode(offset, forKey: .offset, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct PrayerList: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
listNumber: Int



public var 
listDate: LocalDate



public var 
sealVariant: Int?



public var 
soulCount: Int



public var 
intentionCount: Int



public var 
prayerCount: Int



public var 
prayerSeconds: Int



public var 
videoPath: String?



public var 
videoPublishedAt: Timestamp?


  
  public var prayerListKey: PrayerListKey {
    return PrayerListKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerList, rhs: PrayerList) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case listNumber
    
    case listDate
    
    case sealVariant
    
    case soulCount
    
    case intentionCount
    
    case prayerCount
    
    case prayerSeconds
    
    case videoPath
    
    case videoPublishedAt
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.listNumber = try codecHelper.decode(Int.self, forKey: .listNumber, container: &container)
    
    
    
    self.listDate = try codecHelper.decode(LocalDate.self, forKey: .listDate, container: &container)
    
    
    
    self.sealVariant = try codecHelper.decode(Int?.self, forKey: .sealVariant, container: &container)
    
    
    
    self.soulCount = try codecHelper.decode(Int.self, forKey: .soulCount, container: &container)
    
    
    
    self.intentionCount = try codecHelper.decode(Int.self, forKey: .intentionCount, container: &container)
    
    
    
    self.prayerCount = try codecHelper.decode(Int.self, forKey: .prayerCount, container: &container)
    
    
    
    self.prayerSeconds = try codecHelper.decode(Int.self, forKey: .prayerSeconds, container: &container)
    
    
    
    self.videoPath = try codecHelper.decode(String?.self, forKey: .videoPath, container: &container)
    
    
    
    self.videoPublishedAt = try codecHelper.decode(Timestamp?.self, forKey: .videoPublishedAt, container: &container)
    
    
  }
}
public var 
prayerLists: [PrayerList]

  }

  public func ref(
        
        
        
        _ optionalVars: ((inout GetPastListsQuery.Variables)->())? = nil
        ) -> QueryRefObservation<GetPastListsQuery.Data,GetPastListsQuery.Variables>  {
        var variables = GetPastListsQuery.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetPastLists", variables: variables, resultsDataType:GetPastListsQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetPastListsQuery.Data,GetPastListsQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        
        
        _ optionalVars: (@MainActor (inout GetPastListsQuery.Variables)->())? = nil
        ) async throws -> OperationResult<GetPastListsQuery.Data> {
        var variables = GetPastListsQuery.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetPastLists", variables: variables, resultsDataType:GetPastListsQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetPastListsQuery.Data,GetPastListsQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyHeaderQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyHeader"

  public typealias Ref = QueryRefObservation<GetMyHeaderQuery.Data,GetMyHeaderQuery.Variables>

  public struct Variables: OperationVariable {

    
    
  }

  public struct Data: Decodable, Sendable {




public struct User: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: String



public var 
displayName: String?



public var 
locale: String?



public var 
timezone: String?



public var 
planTier: String



public var 
includeLimit: Int



public var 
trialStartedAt: Timestamp?



public var 
entitlementExpiresAt: Timestamp?



public var 
currentStreak: Int



public var 
bestStreak: Int



public var 
lastListLocalDate: LocalDate?



public var 
graceDays: Int



public var 
graceOfferPending: Bool



public var 
graceOffersEnabled: Bool



public var 
listLiveOptIn: Bool



public var 
showNamesInNotifications: Bool



public var 
selfNameChangedAt: Timestamp?





public struct PrayerSubjectSelfSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
publicName: String



public var 
avatarTone: Int?



public var 
avatarPath: String?


  
  public var prayerSubjectSelfSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectSelfSubject, rhs: PrayerSubjectSelfSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case publicName
    
    case avatarTone
    
    case avatarPath
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.avatarTone = try codecHelper.decode(Int?.self, forKey: .avatarTone, container: &container)
    
    
    
    self.avatarPath = try codecHelper.decode(String?.self, forKey: .avatarPath, container: &container)
    
    
  }
}
public var 
selfSubject: [PrayerSubjectSelfSubject]


  
  public var userKey: UserKey {
    return UserKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: User, rhs: User) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case displayName
    
    case locale
    
    case timezone
    
    case planTier
    
    case includeLimit
    
    case trialStartedAt
    
    case entitlementExpiresAt
    
    case currentStreak
    
    case bestStreak
    
    case lastListLocalDate
    
    case graceDays
    
    case graceOfferPending
    
    case graceOffersEnabled
    
    case listLiveOptIn
    
    case showNamesInNotifications
    
    case selfNameChangedAt
    
    case selfSubject
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(String.self, forKey: .id, container: &container)
    
    
    
    self.displayName = try codecHelper.decode(String?.self, forKey: .displayName, container: &container)
    
    
    
    self.locale = try codecHelper.decode(String?.self, forKey: .locale, container: &container)
    
    
    
    self.timezone = try codecHelper.decode(String?.self, forKey: .timezone, container: &container)
    
    
    
    self.planTier = try codecHelper.decode(String.self, forKey: .planTier, container: &container)
    
    
    
    self.includeLimit = try codecHelper.decode(Int.self, forKey: .includeLimit, container: &container)
    
    
    
    self.trialStartedAt = try codecHelper.decode(Timestamp?.self, forKey: .trialStartedAt, container: &container)
    
    
    
    self.entitlementExpiresAt = try codecHelper.decode(Timestamp?.self, forKey: .entitlementExpiresAt, container: &container)
    
    
    
    self.currentStreak = try codecHelper.decode(Int.self, forKey: .currentStreak, container: &container)
    
    
    
    self.bestStreak = try codecHelper.decode(Int.self, forKey: .bestStreak, container: &container)
    
    
    
    self.lastListLocalDate = try codecHelper.decode(LocalDate?.self, forKey: .lastListLocalDate, container: &container)
    
    
    
    self.graceDays = try codecHelper.decode(Int.self, forKey: .graceDays, container: &container)
    
    
    
    self.graceOfferPending = try codecHelper.decode(Bool.self, forKey: .graceOfferPending, container: &container)
    
    
    
    self.graceOffersEnabled = try codecHelper.decode(Bool.self, forKey: .graceOffersEnabled, container: &container)
    
    
    
    self.listLiveOptIn = try codecHelper.decode(Bool.self, forKey: .listLiveOptIn, container: &container)
    
    
    
    self.showNamesInNotifications = try codecHelper.decode(Bool.self, forKey: .showNamesInNotifications, container: &container)
    
    
    
    self.selfNameChangedAt = try codecHelper.decode(Timestamp?.self, forKey: .selfNameChangedAt, container: &container)
    
    
    self.selfSubject = try codecHelper.decode([PrayerSubjectSelfSubject].self, forKey: .selfSubject, container: &container)
    
    
  }
}
public var 
user: User?

  }

  public func ref(
        
        ) -> QueryRefObservation<GetMyHeaderQuery.Data,GetMyHeaderQuery.Variables>  {
        var variables = GetMyHeaderQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMyHeader", variables: variables, resultsDataType:GetMyHeaderQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyHeaderQuery.Data,GetMyHeaderQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        ) async throws -> OperationResult<GetMyHeaderQuery.Data> {
        var variables = GetMyHeaderQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMyHeader", variables: variables, resultsDataType:GetMyHeaderQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyHeaderQuery.Data,GetMyHeaderQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMySubjectsQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMySubjects"

  public typealias Ref = QueryRefObservation<GetMySubjectsQuery.Data,GetMySubjectsQuery.Variables>

  public struct Variables: OperationVariable {

    
    
  }

  public struct Data: Decodable, Sendable {




public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
parentId: UUID?



public var 
publicName: String



public var 
personalLabel: String?



public var 
note: String?



public var 
isSelf: Bool



public var 
isCarried: Bool



public var 
sortOrder: Int



public var 
avatarTone: Int?



public var 
avatarPath: String?



public var 
resolution: SubjectResolution?



public var 
resolvedAt: Timestamp?



public var 
createdAt: Timestamp





public struct PrayerSubjectLinkLastPrayed: Decodable, Sendable  {
  




public struct Prayer: Decodable, Sendable  {
  


public var 
localDate: LocalDate


  

  
  enum CodingKeys: String, CodingKey {
    
    case localDate
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.localDate = try codecHelper.decode(LocalDate.self, forKey: .localDate, container: &container)
    
    
  }
}
public var 
prayer: Prayer


  

  
  enum CodingKeys: String, CodingKey {
    
    case prayer
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.prayer = try codecHelper.decode(Prayer.self, forKey: .prayer, container: &container)
    
    
  }
}
public var 
lastPrayed: [PrayerSubjectLinkLastPrayed]


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case parentId
    
    case publicName
    
    case personalLabel
    
    case note
    
    case isSelf
    
    case isCarried
    
    case sortOrder
    
    case avatarTone
    
    case avatarPath
    
    case resolution
    
    case resolvedAt
    
    case createdAt
    
    case lastPrayed
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.parentId = try codecHelper.decode(UUID?.self, forKey: .parentId, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.note = try codecHelper.decode(String?.self, forKey: .note, container: &container)
    
    
    
    self.isSelf = try codecHelper.decode(Bool.self, forKey: .isSelf, container: &container)
    
    
    
    self.isCarried = try codecHelper.decode(Bool.self, forKey: .isCarried, container: &container)
    
    
    
    self.sortOrder = try codecHelper.decode(Int.self, forKey: .sortOrder, container: &container)
    
    
    
    self.avatarTone = try codecHelper.decode(Int?.self, forKey: .avatarTone, container: &container)
    
    
    
    self.avatarPath = try codecHelper.decode(String?.self, forKey: .avatarPath, container: &container)
    
    
    
    self.resolution = try codecHelper.decode(SubjectResolution?.self, forKey: .resolution, container: &container)
    
    
    
    self.resolvedAt = try codecHelper.decode(Timestamp?.self, forKey: .resolvedAt, container: &container)
    
    
    
    self.createdAt = try codecHelper.decode(Timestamp.self, forKey: .createdAt, container: &container)
    
    
    self.lastPrayed = try codecHelper.decode([PrayerSubjectLinkLastPrayed].self, forKey: .lastPrayed, container: &container)
    
    
  }
}
public var 
prayerSubjects: [PrayerSubject]

  }

  public func ref(
        
        ) -> QueryRefObservation<GetMySubjectsQuery.Data,GetMySubjectsQuery.Variables>  {
        var variables = GetMySubjectsQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMySubjects", variables: variables, resultsDataType:GetMySubjectsQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMySubjectsQuery.Data,GetMySubjectsQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        ) async throws -> OperationResult<GetMySubjectsQuery.Data> {
        var variables = GetMySubjectsQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMySubjects", variables: variables, resultsDataType:GetMySubjectsQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMySubjectsQuery.Data,GetMySubjectsQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class SearchMySubjectsQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "SearchMySubjects"

  public typealias Ref = QueryRefObservation<SearchMySubjectsQuery.Data,SearchMySubjectsQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
query: String


    
    
    
    public init (
        
query: String

        
        ) {
        self.query = query
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.query == rhs.query
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(query)
  
}

    enum CodingKeys: String, CodingKey {
      
      case query
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(query, forKey: .query, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
parentId: UUID?



public var 
publicName: String



public var 
personalLabel: String?



public var 
status: SubjectStatus



public var 
isSelf: Bool


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case parentId
    
    case publicName
    
    case personalLabel
    
    case status
    
    case isSelf
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.parentId = try codecHelper.decode(UUID?.self, forKey: .parentId, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.status = try codecHelper.decode(SubjectStatus.self, forKey: .status, container: &container)
    
    
    
    self.isSelf = try codecHelper.decode(Bool.self, forKey: .isSelf, container: &container)
    
    
  }
}
public var 
prayerSubjects_search: [PrayerSubject]

  }

  public func ref(
        
query: String

        ) -> QueryRefObservation<SearchMySubjectsQuery.Data,SearchMySubjectsQuery.Variables>  {
        var variables = SearchMySubjectsQuery.Variables(query:query)
        

        let ref = dataConnect.query(name: "SearchMySubjects", variables: variables, resultsDataType:SearchMySubjectsQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<SearchMySubjectsQuery.Data,SearchMySubjectsQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
query: String

        ) async throws -> OperationResult<SearchMySubjectsQuery.Data> {
        var variables = SearchMySubjectsQuery.Variables(query:query)
        

        let ref = dataConnect.query(name: "SearchMySubjects", variables: variables, resultsDataType:SearchMySubjectsQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<SearchMySubjectsQuery.Data,SearchMySubjectsQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyListStatusQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyListStatus"

  public typealias Ref = QueryRefObservation<GetMyListStatusQuery.Data,GetMyListStatusQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
listId: UUID


    
    
    
    public init (
        
listId: UUID

        
        ) {
        self.listId = listId
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.listId == rhs.listId
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(listId)
  
}

    enum CodingKeys: String, CodingKey {
      
      case listId
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(listId, forKey: .listId, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct PrayerListEntryMyEntries: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
publicName: String





public struct PrayerListEntry: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID


  
  public var prayerListEntryKey: PrayerListEntryKey {
    return PrayerListEntryKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerListEntry, rhs: PrayerListEntry) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
  }
}
public var 
parentEntry: PrayerListEntry?





public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
isSelf: Bool


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case isSelf
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.isSelf = try codecHelper.decode(Bool.self, forKey: .isSelf, container: &container)
    
    
  }
}
public var 
subject: PrayerSubject?


  
  public var prayerListEntryMyEntriesKey: PrayerListEntryKey {
    return PrayerListEntryKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerListEntryMyEntries, rhs: PrayerListEntryMyEntries) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case publicName
    
    case parentEntry
    
    case subject
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.parentEntry = try codecHelper.decode(PrayerListEntry?.self, forKey: .parentEntry, container: &container)
    
    
    
    self.subject = try codecHelper.decode(PrayerSubject?.self, forKey: .subject, container: &container)
    
    
  }
}
public var 
myEntries: [PrayerListEntryMyEntries]





public struct PrayerListEntryNotPrinted: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
publicName: String



public var 
reasonCategory: ReasonCategory?





public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
  }
}
public var 
subject: PrayerSubject?


  
  public var prayerListEntryNotPrintedKey: PrayerListEntryKey {
    return PrayerListEntryKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerListEntryNotPrinted, rhs: PrayerListEntryNotPrinted) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case publicName
    
    case reasonCategory
    
    case subject
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.reasonCategory = try codecHelper.decode(ReasonCategory?.self, forKey: .reasonCategory, container: &container)
    
    
    
    self.subject = try codecHelper.decode(PrayerSubject?.self, forKey: .subject, container: &container)
    
    
  }
}
public var 
notPrinted: [PrayerListEntryNotPrinted]





public struct PrayerMyPrayersWithList: Decodable, Sendable  {
  


public var 
_count: Int


  

  
  enum CodingKeys: String, CodingKey {
    
    case _count
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self._count = try codecHelper.decode(Int.self, forKey: ._count, container: &container)
    
    
  }
}
public var 
myPrayersWithList: [PrayerMyPrayersWithList]





public struct PrayerListEntryCarriedLists: Decodable, Sendable  {
  


public var 
_count: Int


  

  
  enum CodingKeys: String, CodingKey {
    
    case _count
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self._count = try codecHelper.decode(Int.self, forKey: ._count, container: &container)
    
    
  }
}
public var 
carriedLists: [PrayerListEntryCarriedLists]

  }

  public func ref(
        
listId: UUID

        ) -> QueryRefObservation<GetMyListStatusQuery.Data,GetMyListStatusQuery.Variables>  {
        var variables = GetMyListStatusQuery.Variables(listId:listId)
        

        let ref = dataConnect.query(name: "GetMyListStatus", variables: variables, resultsDataType:GetMyListStatusQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyListStatusQuery.Data,GetMyListStatusQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
listId: UUID

        ) async throws -> OperationResult<GetMyListStatusQuery.Data> {
        var variables = GetMyListStatusQuery.Variables(listId:listId)
        

        let ref = dataConnect.query(name: "GetMyListStatus", variables: variables, resultsDataType:GetMyListStatusQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyListStatusQuery.Data,GetMyListStatusQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyPortionQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyPortion"

  public typealias Ref = QueryRefObservation<GetMyPortionQuery.Data,GetMyPortionQuery.Variables>

  public struct Variables: OperationVariable {
  
        @OptionalVariable
        public var
listId: UUID?


    
    
    
    public init (
        
        
        
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.listId == rhs.listId
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(listId)
  
}

    enum CodingKeys: String, CodingKey {
      
      case listId
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      if $listId.isSet { 
      try codecHelper.encode(listId, forKey: .listId, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct User: Decodable, Sendable  {
  


public var 
planTier: String



public var 
includeLimit: Int



public var 
trialStartedAt: Timestamp?



public var 
entitlementExpiresAt: Timestamp?


  

  
  enum CodingKeys: String, CodingKey {
    
    case planTier
    
    case includeLimit
    
    case trialStartedAt
    
    case entitlementExpiresAt
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.planTier = try codecHelper.decode(String.self, forKey: .planTier, container: &container)
    
    
    
    self.includeLimit = try codecHelper.decode(Int.self, forKey: .includeLimit, container: &container)
    
    
    
    self.trialStartedAt = try codecHelper.decode(Timestamp?.self, forKey: .trialStartedAt, container: &container)
    
    
    
    self.entitlementExpiresAt = try codecHelper.decode(Timestamp?.self, forKey: .entitlementExpiresAt, container: &container)
    
    
  }
}
public var 
user: User?





public struct PrayerSubjectItems: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
parentId: UUID?



public var 
publicName: String



public var 
personalLabel: String?



public var 
isSelf: Bool



public var 
isCarried: Bool



public var 
sortOrder: Int



public var 
avatarTone: Int?


  
  public var prayerSubjectItemsKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectItems, rhs: PrayerSubjectItems) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case parentId
    
    case publicName
    
    case personalLabel
    
    case isSelf
    
    case isCarried
    
    case sortOrder
    
    case avatarTone
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.parentId = try codecHelper.decode(UUID?.self, forKey: .parentId, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.isSelf = try codecHelper.decode(Bool.self, forKey: .isSelf, container: &container)
    
    
    
    self.isCarried = try codecHelper.decode(Bool.self, forKey: .isCarried, container: &container)
    
    
    
    self.sortOrder = try codecHelper.decode(Int.self, forKey: .sortOrder, container: &container)
    
    
    
    self.avatarTone = try codecHelper.decode(Int?.self, forKey: .avatarTone, container: &container)
    
    
  }
}
public var 
items: [PrayerSubjectItems]





public struct PrayerListEntryNotPrinted: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
reasonCategory: ReasonCategory?





public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
  }
}
public var 
subject: PrayerSubject?


  
  public var prayerListEntryNotPrintedKey: PrayerListEntryKey {
    return PrayerListEntryKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerListEntryNotPrinted, rhs: PrayerListEntryNotPrinted) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case reasonCategory
    
    case subject
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.reasonCategory = try codecHelper.decode(ReasonCategory?.self, forKey: .reasonCategory, container: &container)
    
    
    
    self.subject = try codecHelper.decode(PrayerSubject?.self, forKey: .subject, container: &container)
    
    
  }
}
public var 
notPrinted: [PrayerListEntryNotPrinted]

  }

  public func ref(
        
        
        
        _ optionalVars: ((inout GetMyPortionQuery.Variables)->())? = nil
        ) -> QueryRefObservation<GetMyPortionQuery.Data,GetMyPortionQuery.Variables>  {
        var variables = GetMyPortionQuery.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetMyPortion", variables: variables, resultsDataType:GetMyPortionQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyPortionQuery.Data,GetMyPortionQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        
        
        _ optionalVars: (@MainActor (inout GetMyPortionQuery.Variables)->())? = nil
        ) async throws -> OperationResult<GetMyPortionQuery.Data> {
        var variables = GetMyPortionQuery.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetMyPortion", variables: variables, resultsDataType:GetMyPortionQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyPortionQuery.Data,GetMyPortionQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetSubjectDetailQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetSubjectDetail"

  public typealias Ref = QueryRefObservation<GetSubjectDetailQuery.Data,GetSubjectDetailQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID

  
        @OptionalVariable
        public var
prayerLimit: Int?

  
        @OptionalVariable
        public var
prayerOffset: Int?


    
    
    
    public init (
        
id: UUID

        
        
        ,
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        self.id = id
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id && 
              lhs.prayerLimit == rhs.prayerLimit && 
              lhs.prayerOffset == rhs.prayerOffset
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
  hasher.combine(prayerLimit)
  
  hasher.combine(prayerOffset)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
      case prayerLimit
      
      case prayerOffset
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
      if $prayerLimit.isSet { 
      try codecHelper.encode(prayerLimit, forKey: .prayerLimit, container: &container)
      }
      
      if $prayerOffset.isSet { 
      try codecHelper.encode(prayerOffset, forKey: .prayerOffset, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
publicName: String



public var 
personalLabel: String?



public var 
note: String?



public var 
isSelf: Bool



public var 
isCarried: Bool



public var 
status: SubjectStatus



public var 
sortOrder: Int



public var 
avatarTone: Int?



public var 
avatarPath: String?



public var 
resolution: SubjectResolution?



public var 
resolvedAt: Timestamp?



public var 
createdAt: Timestamp





public struct PrayerSubjectParentSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
publicName: String



public var 
personalLabel: String?



public var 
isCarried: Bool



public var 
isSelf: Bool


  
  public var prayerSubjectParentSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectParentSubject, rhs: PrayerSubjectParentSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case publicName
    
    case personalLabel
    
    case isCarried
    
    case isSelf
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.isCarried = try codecHelper.decode(Bool.self, forKey: .isCarried, container: &container)
    
    
    
    self.isSelf = try codecHelper.decode(Bool.self, forKey: .isSelf, container: &container)
    
    
  }
}
public var 
parentSubject: PrayerSubjectParentSubject?





public struct PrayerSubjectIntentions: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
publicName: String



public var 
isCarried: Bool



public var 
status: SubjectStatus



public var 
resolution: SubjectResolution?



public var 
resolvedAt: Timestamp?


  
  public var prayerSubjectIntentionsKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectIntentions, rhs: PrayerSubjectIntentions) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case publicName
    
    case isCarried
    
    case status
    
    case resolution
    
    case resolvedAt
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.isCarried = try codecHelper.decode(Bool.self, forKey: .isCarried, container: &container)
    
    
    
    self.status = try codecHelper.decode(SubjectStatus.self, forKey: .status, container: &container)
    
    
    
    self.resolution = try codecHelper.decode(SubjectResolution?.self, forKey: .resolution, container: &container)
    
    
    
    self.resolvedAt = try codecHelper.decode(Timestamp?.self, forKey: .resolvedAt, container: &container)
    
    
  }
}
public var 
intentions: [PrayerSubjectIntentions]





public struct PrayerListEntryEntries: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID





public struct PrayerList: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
listNumber: Int



public var 
listDate: LocalDate



public var 
status: String



public var 
currentFrom: Timestamp?



public var 
sealVariant: Int?



public var 
prayerCount: Int


  
  public var prayerListKey: PrayerListKey {
    return PrayerListKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerList, rhs: PrayerList) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case listNumber
    
    case listDate
    
    case status
    
    case currentFrom
    
    case sealVariant
    
    case prayerCount
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.listNumber = try codecHelper.decode(Int.self, forKey: .listNumber, container: &container)
    
    
    
    self.listDate = try codecHelper.decode(LocalDate.self, forKey: .listDate, container: &container)
    
    
    
    self.status = try codecHelper.decode(String.self, forKey: .status, container: &container)
    
    
    
    self.currentFrom = try codecHelper.decode(Timestamp?.self, forKey: .currentFrom, container: &container)
    
    
    
    self.sealVariant = try codecHelper.decode(Int?.self, forKey: .sealVariant, container: &container)
    
    
    
    self.prayerCount = try codecHelper.decode(Int.self, forKey: .prayerCount, container: &container)
    
    
  }
}
public var 
list: PrayerList


  
  public var prayerListEntryEntriesKey: PrayerListEntryKey {
    return PrayerListEntryKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerListEntryEntries, rhs: PrayerListEntryEntries) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case list
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.list = try codecHelper.decode(PrayerList.self, forKey: .list, container: &container)
    
    
  }
}
public var 
entries: [PrayerListEntryEntries]





public struct PrayerSubjectLinkPrayers: Decodable, Sendable  {
  




public struct Prayer: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
startedAt: Timestamp



public var 
prayedAt: Timestamp



public var 
localDate: LocalDate



public var 
durationSeconds: Int



public var 
endedBy: PrayerEndedBy



public var 
listContextNumber: Int



public var 
note: String?


  
  public var prayerKey: PrayerKey {
    return PrayerKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: Prayer, rhs: Prayer) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case startedAt
    
    case prayedAt
    
    case localDate
    
    case durationSeconds
    
    case endedBy
    
    case listContextNumber
    
    case note
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.startedAt = try codecHelper.decode(Timestamp.self, forKey: .startedAt, container: &container)
    
    
    
    self.prayedAt = try codecHelper.decode(Timestamp.self, forKey: .prayedAt, container: &container)
    
    
    
    self.localDate = try codecHelper.decode(LocalDate.self, forKey: .localDate, container: &container)
    
    
    
    self.durationSeconds = try codecHelper.decode(Int.self, forKey: .durationSeconds, container: &container)
    
    
    
    self.endedBy = try codecHelper.decode(PrayerEndedBy.self, forKey: .endedBy, container: &container)
    
    
    
    self.listContextNumber = try codecHelper.decode(Int.self, forKey: .listContextNumber, container: &container)
    
    
    
    self.note = try codecHelper.decode(String?.self, forKey: .note, container: &container)
    
    
  }
}
public var 
prayer: Prayer


  

  
  enum CodingKeys: String, CodingKey {
    
    case prayer
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.prayer = try codecHelper.decode(Prayer.self, forKey: .prayer, container: &container)
    
    
  }
}
public var 
prayers: [PrayerSubjectLinkPrayers]


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case publicName
    
    case personalLabel
    
    case note
    
    case isSelf
    
    case isCarried
    
    case status
    
    case sortOrder
    
    case avatarTone
    
    case avatarPath
    
    case resolution
    
    case resolvedAt
    
    case createdAt
    
    case parentSubject
    
    case intentions
    
    case entries
    
    case prayers
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.note = try codecHelper.decode(String?.self, forKey: .note, container: &container)
    
    
    
    self.isSelf = try codecHelper.decode(Bool.self, forKey: .isSelf, container: &container)
    
    
    
    self.isCarried = try codecHelper.decode(Bool.self, forKey: .isCarried, container: &container)
    
    
    
    self.status = try codecHelper.decode(SubjectStatus.self, forKey: .status, container: &container)
    
    
    
    self.sortOrder = try codecHelper.decode(Int.self, forKey: .sortOrder, container: &container)
    
    
    
    self.avatarTone = try codecHelper.decode(Int?.self, forKey: .avatarTone, container: &container)
    
    
    
    self.avatarPath = try codecHelper.decode(String?.self, forKey: .avatarPath, container: &container)
    
    
    
    self.resolution = try codecHelper.decode(SubjectResolution?.self, forKey: .resolution, container: &container)
    
    
    
    self.resolvedAt = try codecHelper.decode(Timestamp?.self, forKey: .resolvedAt, container: &container)
    
    
    
    self.createdAt = try codecHelper.decode(Timestamp.self, forKey: .createdAt, container: &container)
    
    
    
    self.parentSubject = try codecHelper.decode(PrayerSubjectParentSubject?.self, forKey: .parentSubject, container: &container)
    
    
    self.intentions = try codecHelper.decode([PrayerSubjectIntentions].self, forKey: .intentions, container: &container)
    
    
    self.entries = try codecHelper.decode([PrayerListEntryEntries].self, forKey: .entries, container: &container)
    
    
    self.prayers = try codecHelper.decode([PrayerSubjectLinkPrayers].self, forKey: .prayers, container: &container)
    
    
  }
}
public var 
prayerSubjects: [PrayerSubject]

  }

  public func ref(
        
id: UUID

        
        ,
        _ optionalVars: ((inout GetSubjectDetailQuery.Variables)->())? = nil
        ) -> QueryRefObservation<GetSubjectDetailQuery.Data,GetSubjectDetailQuery.Variables>  {
        var variables = GetSubjectDetailQuery.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetSubjectDetail", variables: variables, resultsDataType:GetSubjectDetailQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetSubjectDetailQuery.Data,GetSubjectDetailQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
id: UUID

        
        ,
        _ optionalVars: (@MainActor (inout GetSubjectDetailQuery.Variables)->())? = nil
        ) async throws -> OperationResult<GetSubjectDetailQuery.Data> {
        var variables = GetSubjectDetailQuery.Variables(id:id)
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetSubjectDetail", variables: variables, resultsDataType:GetSubjectDetailQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetSubjectDetailQuery.Data,GetSubjectDetailQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyPrayerHistoryQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyPrayerHistory"

  public typealias Ref = QueryRefObservation<GetMyPrayerHistoryQuery.Data,GetMyPrayerHistoryQuery.Variables>

  public struct Variables: OperationVariable {
  
        @OptionalVariable
        public var
limit: Int?

  
        @OptionalVariable
        public var
offset: Int?


    
    
    
    public init (
        
        
        
        _ optionalVars: ((inout Variables)->())? = nil
        ) {
        

        
        if let optionalVars {
            optionalVars(&self)
        }
        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.limit == rhs.limit && 
              lhs.offset == rhs.offset
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(limit)
  
  hasher.combine(offset)
  
}

    enum CodingKeys: String, CodingKey {
      
      case limit
      
      case offset
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      if $limit.isSet { 
      try codecHelper.encode(limit, forKey: .limit, container: &container)
      }
      
      if $offset.isSet { 
      try codecHelper.encode(offset, forKey: .offset, container: &container)
      }
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct Prayer: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
startedAt: Timestamp



public var 
prayedAt: Timestamp



public var 
localDate: LocalDate



public var 
timezone: String



public var 
durationSeconds: Int



public var 
endedBy: PrayerEndedBy



public var 
mode: PrayerMode



public var 
note: String?





public struct PrayerList: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
listNumber: Int



public var 
sealVariant: Int?


  
  public var prayerListKey: PrayerListKey {
    return PrayerListKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerList, rhs: PrayerList) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case listNumber
    
    case sealVariant
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.listNumber = try codecHelper.decode(Int.self, forKey: .listNumber, container: &container)
    
    
    
    self.sealVariant = try codecHelper.decode(Int?.self, forKey: .sealVariant, container: &container)
    
    
  }
}
public var 
communityList: PrayerList?





public struct PrayerSubjectHeld: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
publicName: String



public var 
personalLabel: String?


  
  public var prayerSubjectHeldKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectHeld, rhs: PrayerSubjectHeld) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case publicName
    
    case personalLabel
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
  }
}
public var 
held: [PrayerSubjectHeld]


  
  public var prayerKey: PrayerKey {
    return PrayerKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: Prayer, rhs: Prayer) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case startedAt
    
    case prayedAt
    
    case localDate
    
    case timezone
    
    case durationSeconds
    
    case endedBy
    
    case mode
    
    case note
    
    case communityList
    
    case held
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.startedAt = try codecHelper.decode(Timestamp.self, forKey: .startedAt, container: &container)
    
    
    
    self.prayedAt = try codecHelper.decode(Timestamp.self, forKey: .prayedAt, container: &container)
    
    
    
    self.localDate = try codecHelper.decode(LocalDate.self, forKey: .localDate, container: &container)
    
    
    
    self.timezone = try codecHelper.decode(String.self, forKey: .timezone, container: &container)
    
    
    
    self.durationSeconds = try codecHelper.decode(Int.self, forKey: .durationSeconds, container: &container)
    
    
    
    self.endedBy = try codecHelper.decode(PrayerEndedBy.self, forKey: .endedBy, container: &container)
    
    
    
    self.mode = try codecHelper.decode(PrayerMode.self, forKey: .mode, container: &container)
    
    
    
    self.note = try codecHelper.decode(String?.self, forKey: .note, container: &container)
    
    
    
    self.communityList = try codecHelper.decode(PrayerList?.self, forKey: .communityList, container: &container)
    
    
    self.held = try codecHelper.decode([PrayerSubjectHeld].self, forKey: .held, container: &container)
    
    
  }
}
public var 
prayers: [Prayer]

  }

  public func ref(
        
        
        
        _ optionalVars: ((inout GetMyPrayerHistoryQuery.Variables)->())? = nil
        ) -> QueryRefObservation<GetMyPrayerHistoryQuery.Data,GetMyPrayerHistoryQuery.Variables>  {
        var variables = GetMyPrayerHistoryQuery.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetMyPrayerHistory", variables: variables, resultsDataType:GetMyPrayerHistoryQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyPrayerHistoryQuery.Data,GetMyPrayerHistoryQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        
        
        _ optionalVars: (@MainActor (inout GetMyPrayerHistoryQuery.Variables)->())? = nil
        ) async throws -> OperationResult<GetMyPrayerHistoryQuery.Data> {
        var variables = GetMyPrayerHistoryQuery.Variables()
        
        if let optionalVars {
            optionalVars(&variables)
        }
        

        let ref = dataConnect.query(name: "GetMyPrayerHistory", variables: variables, resultsDataType:GetMyPrayerHistoryQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyPrayerHistoryQuery.Data,GetMyPrayerHistoryQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyPrayerTimeQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyPrayerTime"

  public typealias Ref = QueryRefObservation<GetMyPrayerTimeQuery.Data,GetMyPrayerTimeQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
weekStart: LocalDate


    
    
    
    public init (
        
weekStart: LocalDate

        
        ) {
        self.weekStart = weekStart
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.weekStart == rhs.weekStart
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(weekStart)
  
}

    enum CodingKeys: String, CodingKey {
      
      case weekStart
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(weekStart, forKey: .weekStart, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct PrayerWeek: Decodable, Sendable  {
  


public var 
durationSeconds_sum: Int?



public var 
_count: Int


  

  
  enum CodingKeys: String, CodingKey {
    
    case durationSeconds_sum
    
    case _count
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.durationSeconds_sum = try codecHelper.decode(Int?.self, forKey: .durationSeconds_sum, container: &container)
    
    
    
    self._count = try codecHelper.decode(Int.self, forKey: ._count, container: &container)
    
    
  }
}
public var 
week: [PrayerWeek]





public struct PrayerAllTime: Decodable, Sendable  {
  


public var 
durationSeconds_sum: Int?



public var 
_count: Int


  

  
  enum CodingKeys: String, CodingKey {
    
    case durationSeconds_sum
    
    case _count
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.durationSeconds_sum = try codecHelper.decode(Int?.self, forKey: .durationSeconds_sum, container: &container)
    
    
    
    self._count = try codecHelper.decode(Int.self, forKey: ._count, container: &container)
    
    
  }
}
public var 
allTime: [PrayerAllTime]

  }

  public func ref(
        
weekStart: LocalDate

        ) -> QueryRefObservation<GetMyPrayerTimeQuery.Data,GetMyPrayerTimeQuery.Variables>  {
        var variables = GetMyPrayerTimeQuery.Variables(weekStart:weekStart)
        

        let ref = dataConnect.query(name: "GetMyPrayerTime", variables: variables, resultsDataType:GetMyPrayerTimeQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyPrayerTimeQuery.Data,GetMyPrayerTimeQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
weekStart: LocalDate

        ) async throws -> OperationResult<GetMyPrayerTimeQuery.Data> {
        var variables = GetMyPrayerTimeQuery.Variables(weekStart:weekStart)
        

        let ref = dataConnect.query(name: "GetMyPrayerTime", variables: variables, resultsDataType:GetMyPrayerTimeQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyPrayerTimeQuery.Data,GetMyPrayerTimeQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetPrayerQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetPrayer"

  public typealias Ref = QueryRefObservation<GetPrayerQuery.Data,GetPrayerQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
id: UUID


    
    
    
    public init (
        
id: UUID

        
        ) {
        self.id = id
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.id == rhs.id
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}

    enum CodingKeys: String, CodingKey {
      
      case id
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(id, forKey: .id, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct Prayer: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
startedAt: Timestamp



public var 
prayedAt: Timestamp



public var 
localDate: LocalDate



public var 
timezone: String



public var 
durationSeconds: Int



public var 
endedBy: PrayerEndedBy



public var 
mode: PrayerMode



public var 
note: String?



public var 
listContextNumber: Int





public struct PrayerList: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
listNumber: Int



public var 
sealVariant: Int?


  
  public var prayerListKey: PrayerListKey {
    return PrayerListKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerList, rhs: PrayerList) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case listNumber
    
    case sealVariant
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.listNumber = try codecHelper.decode(Int.self, forKey: .listNumber, container: &container)
    
    
    
    self.sealVariant = try codecHelper.decode(Int?.self, forKey: .sealVariant, container: &container)
    
    
  }
}
public var 
communityList: PrayerList?





public struct PrayerSubjectHeld: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind



public var 
publicName: String



public var 
personalLabel: String?


  
  public var prayerSubjectHeldKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectHeld, rhs: PrayerSubjectHeld) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case publicName
    
    case personalLabel
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
  }
}
public var 
held: [PrayerSubjectHeld]


  
  public var prayerKey: PrayerKey {
    return PrayerKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: Prayer, rhs: Prayer) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case startedAt
    
    case prayedAt
    
    case localDate
    
    case timezone
    
    case durationSeconds
    
    case endedBy
    
    case mode
    
    case note
    
    case listContextNumber
    
    case communityList
    
    case held
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.startedAt = try codecHelper.decode(Timestamp.self, forKey: .startedAt, container: &container)
    
    
    
    self.prayedAt = try codecHelper.decode(Timestamp.self, forKey: .prayedAt, container: &container)
    
    
    
    self.localDate = try codecHelper.decode(LocalDate.self, forKey: .localDate, container: &container)
    
    
    
    self.timezone = try codecHelper.decode(String.self, forKey: .timezone, container: &container)
    
    
    
    self.durationSeconds = try codecHelper.decode(Int.self, forKey: .durationSeconds, container: &container)
    
    
    
    self.endedBy = try codecHelper.decode(PrayerEndedBy.self, forKey: .endedBy, container: &container)
    
    
    
    self.mode = try codecHelper.decode(PrayerMode.self, forKey: .mode, container: &container)
    
    
    
    self.note = try codecHelper.decode(String?.self, forKey: .note, container: &container)
    
    
    
    self.listContextNumber = try codecHelper.decode(Int.self, forKey: .listContextNumber, container: &container)
    
    
    
    self.communityList = try codecHelper.decode(PrayerList?.self, forKey: .communityList, container: &container)
    
    
    self.held = try codecHelper.decode([PrayerSubjectHeld].self, forKey: .held, container: &container)
    
    
  }
}
public var 
prayers: [Prayer]

  }

  public func ref(
        
id: UUID

        ) -> QueryRefObservation<GetPrayerQuery.Data,GetPrayerQuery.Variables>  {
        var variables = GetPrayerQuery.Variables(id:id)
        

        let ref = dataConnect.query(name: "GetPrayer", variables: variables, resultsDataType:GetPrayerQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetPrayerQuery.Data,GetPrayerQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
id: UUID

        ) async throws -> OperationResult<GetPrayerQuery.Data> {
        var variables = GetPrayerQuery.Variables(id:id)
        

        let ref = dataConnect.query(name: "GetPrayer", variables: variables, resultsDataType:GetPrayerQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetPrayerQuery.Data,GetPrayerQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyMonthQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyMonth"

  public typealias Ref = QueryRefObservation<GetMyMonthQuery.Data,GetMyMonthQuery.Variables>

  public struct Variables: OperationVariable {
  
        
        public var
from: LocalDate

  
        
        public var
to: LocalDate


    
    
    
    public init (
        
from: LocalDate
,
        
to: LocalDate

        
        ) {
        self.from = from
        self.to = to
        

        
    }

    public static func == (lhs: Variables, rhs: Variables) -> Bool {
      
        return lhs.from == rhs.from && 
              lhs.to == rhs.to
              
    }

    
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(from)
  
  hasher.combine(to)
  
}

    enum CodingKeys: String, CodingKey {
      
      case from
      
      case to
      
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      let codecHelper = CodecHelper<CodingKeys>()
      
      
      try codecHelper.encode(from, forKey: .from, container: &container)
      
      
      
      try codecHelper.encode(to, forKey: .to, container: &container)
      
      
    }

  }

  public struct Data: Decodable, Sendable {




public struct Prayer: Decodable, Sendable  {
  


public var 
localDate: LocalDate





public struct PrayerList: Decodable, Sendable  {
  


public var 
listNumber: Int



public var 
sealVariant: Int?


  

  
  enum CodingKeys: String, CodingKey {
    
    case listNumber
    
    case sealVariant
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.listNumber = try codecHelper.decode(Int.self, forKey: .listNumber, container: &container)
    
    
    
    self.sealVariant = try codecHelper.decode(Int?.self, forKey: .sealVariant, container: &container)
    
    
  }
}
public var 
communityList: PrayerList?


  

  
  enum CodingKeys: String, CodingKey {
    
    case localDate
    
    case communityList
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.localDate = try codecHelper.decode(LocalDate.self, forKey: .localDate, container: &container)
    
    
    
    self.communityList = try codecHelper.decode(PrayerList?.self, forKey: .communityList, container: &container)
    
    
  }
}
public var 
prayers: [Prayer]

  }

  public func ref(
        
from: LocalDate
,
to: LocalDate

        ) -> QueryRefObservation<GetMyMonthQuery.Data,GetMyMonthQuery.Variables>  {
        var variables = GetMyMonthQuery.Variables(from:from,to:to)
        

        let ref = dataConnect.query(name: "GetMyMonth", variables: variables, resultsDataType:GetMyMonthQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyMonthQuery.Data,GetMyMonthQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
from: LocalDate
,
to: LocalDate

        ) async throws -> OperationResult<GetMyMonthQuery.Data> {
        var variables = GetMyMonthQuery.Variables(from:from,to:to)
        

        let ref = dataConnect.query(name: "GetMyMonth", variables: variables, resultsDataType:GetMyMonthQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyMonthQuery.Data,GetMyMonthQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyArchivedSubjectsQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyArchivedSubjects"

  public typealias Ref = QueryRefObservation<GetMyArchivedSubjectsQuery.Data,GetMyArchivedSubjectsQuery.Variables>

  public struct Variables: OperationVariable {

    
    
  }

  public struct Data: Decodable, Sendable {




public struct PrayerSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
kind: SubjectKind





public struct PrayerSubjectParentSubject: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
publicName: String



public var 
personalLabel: String?



public var 
status: SubjectStatus


  
  public var prayerSubjectParentSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubjectParentSubject, rhs: PrayerSubjectParentSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case publicName
    
    case personalLabel
    
    case status
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.status = try codecHelper.decode(SubjectStatus.self, forKey: .status, container: &container)
    
    
  }
}
public var 
parentSubject: PrayerSubjectParentSubject?



public var 
publicName: String



public var 
personalLabel: String?



public var 
resolution: SubjectResolution?



public var 
resolvedAt: Timestamp?



public var 
archivedByCascade: Bool


  
  public var prayerSubjectKey: PrayerSubjectKey {
    return PrayerSubjectKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: PrayerSubject, rhs: PrayerSubject) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case kind
    
    case parentSubject
    
    case publicName
    
    case personalLabel
    
    case resolution
    
    case resolvedAt
    
    case archivedByCascade
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.kind = try codecHelper.decode(SubjectKind.self, forKey: .kind, container: &container)
    
    
    
    self.parentSubject = try codecHelper.decode(PrayerSubjectParentSubject?.self, forKey: .parentSubject, container: &container)
    
    
    
    self.publicName = try codecHelper.decode(String.self, forKey: .publicName, container: &container)
    
    
    
    self.personalLabel = try codecHelper.decode(String?.self, forKey: .personalLabel, container: &container)
    
    
    
    self.resolution = try codecHelper.decode(SubjectResolution?.self, forKey: .resolution, container: &container)
    
    
    
    self.resolvedAt = try codecHelper.decode(Timestamp?.self, forKey: .resolvedAt, container: &container)
    
    
    
    self.archivedByCascade = try codecHelper.decode(Bool.self, forKey: .archivedByCascade, container: &container)
    
    
  }
}
public var 
prayerSubjects: [PrayerSubject]

  }

  public func ref(
        
        ) -> QueryRefObservation<GetMyArchivedSubjectsQuery.Data,GetMyArchivedSubjectsQuery.Variables>  {
        var variables = GetMyArchivedSubjectsQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMyArchivedSubjects", variables: variables, resultsDataType:GetMyArchivedSubjectsQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyArchivedSubjectsQuery.Data,GetMyArchivedSubjectsQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        ) async throws -> OperationResult<GetMyArchivedSubjectsQuery.Data> {
        var variables = GetMyArchivedSubjectsQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMyArchivedSubjects", variables: variables, resultsDataType:GetMyArchivedSubjectsQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyArchivedSubjectsQuery.Data,GetMyArchivedSubjectsQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}






public class GetMyRemindersQuery{

  let dataConnect: DataConnect

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect
  }

  public static let OperationName = "GetMyReminders"

  public typealias Ref = QueryRefObservation<GetMyRemindersQuery.Data,GetMyRemindersQuery.Variables>

  public struct Variables: OperationVariable {

    
    
  }

  public struct Data: Decodable, Sendable {




public struct ReminderPreference: Decodable, Sendable ,Hashable, Equatable, Identifiable {
  


public var 
id: UUID



public var 
slot: ReminderSlot



public var 
enabled: Bool



public var 
localTime: String



public var 
label: String?


  
  public var reminderPreferenceKey: ReminderPreferenceKey {
    return ReminderPreferenceKey(
      
      id: id
    )
  }

  
public func hash(into hasher: inout Hasher) {
  
  hasher.combine(id)
  
}
public static func == (lhs: ReminderPreference, rhs: ReminderPreference) -> Bool {
    
    return lhs.id == rhs.id 
        
  }

  

  
  enum CodingKeys: String, CodingKey {
    
    case id
    
    case slot
    
    case enabled
    
    case localTime
    
    case label
    
  }

  public init(from decoder: any Decoder) throws {
    var container = try decoder.container(keyedBy: CodingKeys.self)
    let codecHelper = CodecHelper<CodingKeys>()

    
    
    self.id = try codecHelper.decode(UUID.self, forKey: .id, container: &container)
    
    
    
    self.slot = try codecHelper.decode(ReminderSlot.self, forKey: .slot, container: &container)
    
    
    
    self.enabled = try codecHelper.decode(Bool.self, forKey: .enabled, container: &container)
    
    
    
    self.localTime = try codecHelper.decode(String.self, forKey: .localTime, container: &container)
    
    
    
    self.label = try codecHelper.decode(String?.self, forKey: .label, container: &container)
    
    
  }
}
public var 
reminderPreferences: [ReminderPreference]

  }

  public func ref(
        
        ) -> QueryRefObservation<GetMyRemindersQuery.Data,GetMyRemindersQuery.Variables>  {
        var variables = GetMyRemindersQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMyReminders", variables: variables, resultsDataType:GetMyRemindersQuery.Data.self, publisher: .observableMacro)
        return ref as! QueryRefObservation<GetMyRemindersQuery.Data,GetMyRemindersQuery.Variables>
   }

  @MainActor
   public func execute( fetchPolicy: QueryFetchPolicy = .preferCache,  
        
        ) async throws -> OperationResult<GetMyRemindersQuery.Data> {
        var variables = GetMyRemindersQuery.Variables()
        

        let ref = dataConnect.query(name: "GetMyReminders", variables: variables, resultsDataType:GetMyRemindersQuery.Data.self, publisher: .observableMacro)
        
        let refCast = ref as! QueryRefObservation<GetMyRemindersQuery.Data,GetMyRemindersQuery.Variables>
        return try await refCast.execute(fetchPolicy: fetchPolicy)
        
   }
}


