library plusprayer_connector;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'log_prayer.dart';

part 'update_prayer_note.dart';

part 'reorder_subjects.dart';

part 'mark_intention_answered.dart';

part 'release_intention.dart';

part 'archive_subject.dart';

part 'restore_subject.dart';

part 'purge_subject.dart';

part 'set_subject_avatar_tone.dart';

part 'update_my_settings.dart';

part 'create_reminder.dart';

part 'update_reminder.dart';

part 'delete_reminder.dart';

part 'get_current_list_meta.dart';

part 'get_past_lists.dart';

part 'get_my_header.dart';

part 'get_my_subjects.dart';

part 'search_my_subjects.dart';

part 'get_my_list_status.dart';

part 'get_my_portion.dart';

part 'get_subject_detail.dart';

part 'get_my_prayer_history.dart';

part 'get_my_prayer_time.dart';

part 'get_prayer.dart';

part 'get_my_month.dart';

part 'get_my_archived_subjects.dart';

part 'get_my_reminders.dart';



  enum PrayerEndedBy {
    
      AMEN,
    
      AUTO,
    
  }
  
  String prayerEndedBySerializer(EnumValue<PrayerEndedBy> e) {
    return e.stringValue;
  }
  EnumValue<PrayerEndedBy> prayerEndedByDeserializer(dynamic data) {
    switch (data) {
      
      case 'AMEN':
        return const Known(PrayerEndedBy.AMEN);
      
      case 'AUTO':
        return const Known(PrayerEndedBy.AUTO);
      
      default:
        return Unknown(data);
    }
  }
  

  enum PrayerMode {
    
      MANUAL,
    
      GUIDED,
    
  }
  
  String prayerModeSerializer(EnumValue<PrayerMode> e) {
    return e.stringValue;
  }
  EnumValue<PrayerMode> prayerModeDeserializer(dynamic data) {
    switch (data) {
      
      case 'MANUAL':
        return const Known(PrayerMode.MANUAL);
      
      case 'GUIDED':
        return const Known(PrayerMode.GUIDED);
      
      default:
        return Unknown(data);
    }
  }
  

  enum ReasonCategory {
    
      LANGUAGE,
    
      CONTACT_OR_LINK,
    
      NAME_CHANGES,
    
      OTHER,
    
  }
  
  String reasonCategorySerializer(EnumValue<ReasonCategory> e) {
    return e.stringValue;
  }
  EnumValue<ReasonCategory> reasonCategoryDeserializer(dynamic data) {
    switch (data) {
      
      case 'LANGUAGE':
        return const Known(ReasonCategory.LANGUAGE);
      
      case 'CONTACT_OR_LINK':
        return const Known(ReasonCategory.CONTACT_OR_LINK);
      
      case 'NAME_CHANGES':
        return const Known(ReasonCategory.NAME_CHANGES);
      
      case 'OTHER':
        return const Known(ReasonCategory.OTHER);
      
      default:
        return Unknown(data);
    }
  }
  

  enum ReminderSlot {
    
      MORNING,
    
      MIDDAY,
    
      EVENING,
    
      CUSTOM,
    
  }
  
  String reminderSlotSerializer(EnumValue<ReminderSlot> e) {
    return e.stringValue;
  }
  EnumValue<ReminderSlot> reminderSlotDeserializer(dynamic data) {
    switch (data) {
      
      case 'MORNING':
        return const Known(ReminderSlot.MORNING);
      
      case 'MIDDAY':
        return const Known(ReminderSlot.MIDDAY);
      
      case 'EVENING':
        return const Known(ReminderSlot.EVENING);
      
      case 'CUSTOM':
        return const Known(ReminderSlot.CUSTOM);
      
      default:
        return Unknown(data);
    }
  }
  

  enum SubjectKind {
    
      SOUL,
    
      INTENTION,
    
  }
  
  String subjectKindSerializer(EnumValue<SubjectKind> e) {
    return e.stringValue;
  }
  EnumValue<SubjectKind> subjectKindDeserializer(dynamic data) {
    switch (data) {
      
      case 'SOUL':
        return const Known(SubjectKind.SOUL);
      
      case 'INTENTION':
        return const Known(SubjectKind.INTENTION);
      
      default:
        return Unknown(data);
    }
  }
  

  enum SubjectResolution {
    
      ANSWERED,
    
      RELEASED,
    
  }
  
  String subjectResolutionSerializer(EnumValue<SubjectResolution> e) {
    return e.stringValue;
  }
  EnumValue<SubjectResolution> subjectResolutionDeserializer(dynamic data) {
    switch (data) {
      
      case 'ANSWERED':
        return const Known(SubjectResolution.ANSWERED);
      
      case 'RELEASED':
        return const Known(SubjectResolution.RELEASED);
      
      default:
        return Unknown(data);
    }
  }
  

  enum SubjectStatus {
    
      ACTIVE,
    
      ARCHIVED,
    
      PURGED,
    
  }
  
  String subjectStatusSerializer(EnumValue<SubjectStatus> e) {
    return e.stringValue;
  }
  EnumValue<SubjectStatus> subjectStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'ACTIVE':
        return const Known(SubjectStatus.ACTIVE);
      
      case 'ARCHIVED':
        return const Known(SubjectStatus.ARCHIVED);
      
      case 'PURGED':
        return const Known(SubjectStatus.PURGED);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class PlusprayerConnector {
  
  
  LogPrayerVariablesBuilder logPrayer ({required String id, required Timestamp startedAt, required Timestamp prayedAt, required int durationSeconds, required DateTime localDate, required String timezone, required int listContextNumber, required List<String> subjectIds, }) {
    return LogPrayerVariablesBuilder(dataConnect, id: id,startedAt: startedAt,prayedAt: prayedAt,durationSeconds: durationSeconds,localDate: localDate,timezone: timezone,listContextNumber: listContextNumber,subjectIds: subjectIds,);
  }
  
  
  UpdatePrayerNoteVariablesBuilder updatePrayerNote ({required String id, }) {
    return UpdatePrayerNoteVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ReorderSubjectsVariablesBuilder reorderSubjects ({required List<String> orderedIds, }) {
    return ReorderSubjectsVariablesBuilder(dataConnect, orderedIds: orderedIds,);
  }
  
  
  MarkIntentionAnsweredVariablesBuilder markIntentionAnswered ({required String id, }) {
    return MarkIntentionAnsweredVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ReleaseIntentionVariablesBuilder releaseIntention ({required String id, }) {
    return ReleaseIntentionVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ArchiveSubjectVariablesBuilder archiveSubject ({required String id, }) {
    return ArchiveSubjectVariablesBuilder(dataConnect, id: id,);
  }
  
  
  RestoreSubjectVariablesBuilder restoreSubject ({required String id, }) {
    return RestoreSubjectVariablesBuilder(dataConnect, id: id,);
  }
  
  
  PurgeSubjectVariablesBuilder purgeSubject ({required String id, }) {
    return PurgeSubjectVariablesBuilder(dataConnect, id: id,);
  }
  
  
  SetSubjectAvatarToneVariablesBuilder setSubjectAvatarTone ({required String id, }) {
    return SetSubjectAvatarToneVariablesBuilder(dataConnect, id: id,);
  }
  
  
  UpdateMySettingsVariablesBuilder updateMySettings () {
    return UpdateMySettingsVariablesBuilder(dataConnect, );
  }
  
  
  CreateReminderVariablesBuilder createReminder ({required ReminderSlot slot, required String localTime, }) {
    return CreateReminderVariablesBuilder(dataConnect, slot: slot,localTime: localTime,);
  }
  
  
  UpdateReminderVariablesBuilder updateReminder ({required String id, }) {
    return UpdateReminderVariablesBuilder(dataConnect, id: id,);
  }
  
  
  DeleteReminderVariablesBuilder deleteReminder ({required String id, }) {
    return DeleteReminderVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetCurrentListMetaVariablesBuilder getCurrentListMeta () {
    return GetCurrentListMetaVariablesBuilder(dataConnect, );
  }
  
  
  GetPastListsVariablesBuilder getPastLists () {
    return GetPastListsVariablesBuilder(dataConnect, );
  }
  
  
  GetMyHeaderVariablesBuilder getMyHeader () {
    return GetMyHeaderVariablesBuilder(dataConnect, );
  }
  
  
  GetMySubjectsVariablesBuilder getMySubjects () {
    return GetMySubjectsVariablesBuilder(dataConnect, );
  }
  
  
  SearchMySubjectsVariablesBuilder searchMySubjects ({required String query, }) {
    return SearchMySubjectsVariablesBuilder(dataConnect, query: query,);
  }
  
  
  GetMyListStatusVariablesBuilder getMyListStatus ({required String listId, }) {
    return GetMyListStatusVariablesBuilder(dataConnect, listId: listId,);
  }
  
  
  GetMyPortionVariablesBuilder getMyPortion () {
    return GetMyPortionVariablesBuilder(dataConnect, );
  }
  
  
  GetSubjectDetailVariablesBuilder getSubjectDetail ({required String id, }) {
    return GetSubjectDetailVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetMyPrayerHistoryVariablesBuilder getMyPrayerHistory () {
    return GetMyPrayerHistoryVariablesBuilder(dataConnect, );
  }
  
  
  GetMyPrayerTimeVariablesBuilder getMyPrayerTime ({required DateTime weekStart, }) {
    return GetMyPrayerTimeVariablesBuilder(dataConnect, weekStart: weekStart,);
  }
  
  
  GetPrayerVariablesBuilder getPrayer ({required String id, }) {
    return GetPrayerVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetMyMonthVariablesBuilder getMyMonth ({required DateTime from, required DateTime to, }) {
    return GetMyMonthVariablesBuilder(dataConnect, from: from,to: to,);
  }
  
  
  GetMyArchivedSubjectsVariablesBuilder getMyArchivedSubjects () {
    return GetMyArchivedSubjectsVariablesBuilder(dataConnect, );
  }
  
  
  GetMyRemindersVariablesBuilder getMyReminders () {
    return GetMyRemindersVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'plusprayer',
    'plusprayer-service',
  );

  PlusprayerConnector({required this.dataConnect});
  static PlusprayerConnector get instance {
    
    return PlusprayerConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
