# Basic Usage

```dart
PlusprayerConnector.instance.LogPrayer(logPrayerVariables).execute();
PlusprayerConnector.instance.UpdatePrayerNote(updatePrayerNoteVariables).execute();
PlusprayerConnector.instance.ReorderSubjects(reorderSubjectsVariables).execute();
PlusprayerConnector.instance.MarkIntentionAnswered(markIntentionAnsweredVariables).execute();
PlusprayerConnector.instance.ReleaseIntention(releaseIntentionVariables).execute();
PlusprayerConnector.instance.ArchiveSubject(archiveSubjectVariables).execute();
PlusprayerConnector.instance.RestoreSubject(restoreSubjectVariables).execute();
PlusprayerConnector.instance.PurgeSubject(purgeSubjectVariables).execute();
PlusprayerConnector.instance.SetSubjectAvatarTone(setSubjectAvatarToneVariables).execute();
PlusprayerConnector.instance.UpdateMySettings(updateMySettingsVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await PlusprayerConnector.instance.GetMyPrayerHistory({ ... })
.limit(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

