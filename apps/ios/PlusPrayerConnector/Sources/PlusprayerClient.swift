
import Foundation

import FirebaseCore
import FirebaseDataConnect
public extension DataConnect {

  static let plusprayerConnector: PlusprayerConnector = {
    let cacheSettings = CacheSettings(storage: .persistent, maxAge: 0)
    let settings = DataConnectSettings(cacheSettings: cacheSettings)

    let dc = DataConnect.dataConnect(connectorConfig: PlusprayerConnector.connectorConfig, settings: settings, callerSDKType: .generated)
    return PlusprayerConnector(dataConnect: dc)
  }()

}

public class PlusprayerConnector {

  let dataConnect: DataConnect

  public static let connectorConfig = ConnectorConfig(serviceId: "plusprayer-service", location: "us-central1", connector: "plusprayer")

  init(dataConnect: DataConnect) {
    self.dataConnect = dataConnect

    // init operations 
    self.logPrayerMutation = LogPrayerMutation(dataConnect: dataConnect)
    self.updatePrayerNoteMutation = UpdatePrayerNoteMutation(dataConnect: dataConnect)
    self.reorderSubjectsMutation = ReorderSubjectsMutation(dataConnect: dataConnect)
    self.markIntentionAnsweredMutation = MarkIntentionAnsweredMutation(dataConnect: dataConnect)
    self.releaseIntentionMutation = ReleaseIntentionMutation(dataConnect: dataConnect)
    self.archiveSubjectMutation = ArchiveSubjectMutation(dataConnect: dataConnect)
    self.restoreSubjectMutation = RestoreSubjectMutation(dataConnect: dataConnect)
    self.purgeSubjectMutation = PurgeSubjectMutation(dataConnect: dataConnect)
    self.setSubjectAvatarToneMutation = SetSubjectAvatarToneMutation(dataConnect: dataConnect)
    self.updateMySettingsMutation = UpdateMySettingsMutation(dataConnect: dataConnect)
    self.createReminderMutation = CreateReminderMutation(dataConnect: dataConnect)
    self.updateReminderMutation = UpdateReminderMutation(dataConnect: dataConnect)
    self.deleteReminderMutation = DeleteReminderMutation(dataConnect: dataConnect)
    self.getCurrentListMetaQuery = GetCurrentListMetaQuery(dataConnect: dataConnect)
    self.getPastListsQuery = GetPastListsQuery(dataConnect: dataConnect)
    self.getMyHeaderQuery = GetMyHeaderQuery(dataConnect: dataConnect)
    self.getMySubjectsQuery = GetMySubjectsQuery(dataConnect: dataConnect)
    self.searchMySubjectsQuery = SearchMySubjectsQuery(dataConnect: dataConnect)
    self.getMyListStatusQuery = GetMyListStatusQuery(dataConnect: dataConnect)
    self.getMyPortionQuery = GetMyPortionQuery(dataConnect: dataConnect)
    self.getSubjectDetailQuery = GetSubjectDetailQuery(dataConnect: dataConnect)
    self.getMyPrayerHistoryQuery = GetMyPrayerHistoryQuery(dataConnect: dataConnect)
    self.getMyPrayerTimeQuery = GetMyPrayerTimeQuery(dataConnect: dataConnect)
    self.getPrayerQuery = GetPrayerQuery(dataConnect: dataConnect)
    self.getMyMonthQuery = GetMyMonthQuery(dataConnect: dataConnect)
    self.getMyArchivedSubjectsQuery = GetMyArchivedSubjectsQuery(dataConnect: dataConnect)
    self.getMyRemindersQuery = GetMyRemindersQuery(dataConnect: dataConnect)
    
  }

  public func useEmulator(host: String = DataConnect.EmulatorDefaults.host, port: Int = DataConnect.EmulatorDefaults.port) {
    self.dataConnect.useEmulator(host: host, port: port)
  }

  // MARK: Operations
public let logPrayerMutation: LogPrayerMutation
public let updatePrayerNoteMutation: UpdatePrayerNoteMutation
public let reorderSubjectsMutation: ReorderSubjectsMutation
public let markIntentionAnsweredMutation: MarkIntentionAnsweredMutation
public let releaseIntentionMutation: ReleaseIntentionMutation
public let archiveSubjectMutation: ArchiveSubjectMutation
public let restoreSubjectMutation: RestoreSubjectMutation
public let purgeSubjectMutation: PurgeSubjectMutation
public let setSubjectAvatarToneMutation: SetSubjectAvatarToneMutation
public let updateMySettingsMutation: UpdateMySettingsMutation
public let createReminderMutation: CreateReminderMutation
public let updateReminderMutation: UpdateReminderMutation
public let deleteReminderMutation: DeleteReminderMutation
public let getCurrentListMetaQuery: GetCurrentListMetaQuery
public let getPastListsQuery: GetPastListsQuery
public let getMyHeaderQuery: GetMyHeaderQuery
public let getMySubjectsQuery: GetMySubjectsQuery
public let searchMySubjectsQuery: SearchMySubjectsQuery
public let getMyListStatusQuery: GetMyListStatusQuery
public let getMyPortionQuery: GetMyPortionQuery
public let getSubjectDetailQuery: GetSubjectDetailQuery
public let getMyPrayerHistoryQuery: GetMyPrayerHistoryQuery
public let getMyPrayerTimeQuery: GetMyPrayerTimeQuery
public let getPrayerQuery: GetPrayerQuery
public let getMyMonthQuery: GetMyMonthQuery
public let getMyArchivedSubjectsQuery: GetMyArchivedSubjectsQuery
public let getMyRemindersQuery: GetMyRemindersQuery


}
