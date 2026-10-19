# plusprayer_connector SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
PlusprayerConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetCurrentListMeta
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getCurrentListMeta().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCurrentListMetaData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getCurrentListMeta();
GetCurrentListMetaData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getCurrentListMeta().ref();
ref.execute();

ref.subscribe(...);
```


### GetPastLists
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getPastLists().execute();
```

#### Optional Arguments
We return a builder for each query. For GetPastLists, we created `GetPastListsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetPastListsVariablesBuilder {
  ...
 
  GetPastListsVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }
  GetPastListsVariablesBuilder offset(int? t) {
   _offset.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.getPastLists()
.limit(limit)
.offset(offset)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetPastListsData, GetPastListsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getPastLists();
GetPastListsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getPastLists().ref();
ref.execute();

ref.subscribe(...);
```


### GetMyHeader
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getMyHeader().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyHeaderData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyHeader();
GetMyHeaderData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getMyHeader().ref();
ref.execute();

ref.subscribe(...);
```


### GetMySubjects
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getMySubjects().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMySubjectsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMySubjects();
GetMySubjectsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getMySubjects().ref();
ref.execute();

ref.subscribe(...);
```


### SearchMySubjects
#### Required Arguments
```dart
String query = ...;
PlusprayerConnector.instance.searchMySubjects(
  query: query,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<SearchMySubjectsData, SearchMySubjectsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.searchMySubjects(
  query: query,
);
SearchMySubjectsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String query = ...;

final ref = PlusprayerConnector.instance.searchMySubjects(
  query: query,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMyListStatus
#### Required Arguments
```dart
String listId = ...;
PlusprayerConnector.instance.getMyListStatus(
  listId: listId,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyListStatusData, GetMyListStatusVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyListStatus(
  listId: listId,
);
GetMyListStatusData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String listId = ...;

final ref = PlusprayerConnector.instance.getMyListStatus(
  listId: listId,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMyPortion
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getMyPortion().execute();
```

#### Optional Arguments
We return a builder for each query. For GetMyPortion, we created `GetMyPortionBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetMyPortionVariablesBuilder {
  ...
 
  GetMyPortionVariablesBuilder listId(String? t) {
   _listId.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.getMyPortion()
.listId(listId)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetMyPortionData, GetMyPortionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyPortion();
GetMyPortionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getMyPortion().ref();
ref.execute();

ref.subscribe(...);
```


### GetSubjectDetail
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.getSubjectDetail(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For GetSubjectDetail, we created `GetSubjectDetailBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetSubjectDetailVariablesBuilder {
  ...
   GetSubjectDetailVariablesBuilder prayerLimit(int? t) {
   _prayerLimit.value = t;
   return this;
  }
  GetSubjectDetailVariablesBuilder prayerOffset(int? t) {
   _prayerOffset.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.getSubjectDetail(
  id: id,
)
.prayerLimit(prayerLimit)
.prayerOffset(prayerOffset)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetSubjectDetailData, GetSubjectDetailVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getSubjectDetail(
  id: id,
);
GetSubjectDetailData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.getSubjectDetail(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMyPrayerHistory
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getMyPrayerHistory().execute();
```

#### Optional Arguments
We return a builder for each query. For GetMyPrayerHistory, we created `GetMyPrayerHistoryBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class GetMyPrayerHistoryVariablesBuilder {
  ...
 
  GetMyPrayerHistoryVariablesBuilder limit(int? t) {
   _limit.value = t;
   return this;
  }
  GetMyPrayerHistoryVariablesBuilder offset(int? t) {
   _offset.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.getMyPrayerHistory()
.limit(limit)
.offset(offset)
.execute();
```

#### Return Type
`execute()` returns a `QueryResult<GetMyPrayerHistoryData, GetMyPrayerHistoryVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyPrayerHistory();
GetMyPrayerHistoryData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getMyPrayerHistory().ref();
ref.execute();

ref.subscribe(...);
```


### GetMyPrayerTime
#### Required Arguments
```dart
DateTime weekStart = ...;
PlusprayerConnector.instance.getMyPrayerTime(
  weekStart: weekStart,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyPrayerTimeData, GetMyPrayerTimeVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyPrayerTime(
  weekStart: weekStart,
);
GetMyPrayerTimeData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
DateTime weekStart = ...;

final ref = PlusprayerConnector.instance.getMyPrayerTime(
  weekStart: weekStart,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetPrayer
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.getPrayer(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetPrayerData, GetPrayerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getPrayer(
  id: id,
);
GetPrayerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.getPrayer(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMyMonth
#### Required Arguments
```dart
DateTime from = ...;
DateTime to = ...;
PlusprayerConnector.instance.getMyMonth(
  from: from,
  to: to,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyMonthData, GetMyMonthVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyMonth(
  from: from,
  to: to,
);
GetMyMonthData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
DateTime from = ...;
DateTime to = ...;

final ref = PlusprayerConnector.instance.getMyMonth(
  from: from,
  to: to,
).ref();
ref.execute();

ref.subscribe(...);
```


### GetMyArchivedSubjects
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getMyArchivedSubjects().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyArchivedSubjectsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyArchivedSubjects();
GetMyArchivedSubjectsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getMyArchivedSubjects().ref();
ref.execute();

ref.subscribe(...);
```


### GetMyReminders
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.getMyReminders().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetMyRemindersData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await PlusprayerConnector.instance.getMyReminders();
GetMyRemindersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.getMyReminders().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### LogPrayer
#### Required Arguments
```dart
String id = ...;
Timestamp startedAt = ...;
Timestamp prayedAt = ...;
int durationSeconds = ...;
DateTime localDate = ...;
String timezone = ...;
int listContextNumber = ...;
String subjectIds = ...;
PlusprayerConnector.instance.logPrayer(
  id: id,
  startedAt: startedAt,
  prayedAt: prayedAt,
  durationSeconds: durationSeconds,
  localDate: localDate,
  timezone: timezone,
  listContextNumber: listContextNumber,
  subjectIds: subjectIds,
).execute();
```

#### Optional Arguments
We return a builder for each query. For LogPrayer, we created `LogPrayerBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class LogPrayerVariablesBuilder {
  ...
   LogPrayerVariablesBuilder communityListId(String? t) {
   _communityListId.value = t;
   return this;
  }
  LogPrayerVariablesBuilder note(String? t) {
   _note.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.logPrayer(
  id: id,
  startedAt: startedAt,
  prayedAt: prayedAt,
  durationSeconds: durationSeconds,
  localDate: localDate,
  timezone: timezone,
  listContextNumber: listContextNumber,
  subjectIds: subjectIds,
)
.communityListId(communityListId)
.note(note)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<LogPrayerData, LogPrayerVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.logPrayer(
  id: id,
  startedAt: startedAt,
  prayedAt: prayedAt,
  durationSeconds: durationSeconds,
  localDate: localDate,
  timezone: timezone,
  listContextNumber: listContextNumber,
  subjectIds: subjectIds,
);
LogPrayerData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
Timestamp startedAt = ...;
Timestamp prayedAt = ...;
int durationSeconds = ...;
DateTime localDate = ...;
String timezone = ...;
int listContextNumber = ...;
String subjectIds = ...;

final ref = PlusprayerConnector.instance.logPrayer(
  id: id,
  startedAt: startedAt,
  prayedAt: prayedAt,
  durationSeconds: durationSeconds,
  localDate: localDate,
  timezone: timezone,
  listContextNumber: listContextNumber,
  subjectIds: subjectIds,
).ref();
ref.execute();
```


### UpdatePrayerNote
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.updatePrayerNote(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdatePrayerNote, we created `UpdatePrayerNoteBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdatePrayerNoteVariablesBuilder {
  ...
   UpdatePrayerNoteVariablesBuilder note(String? t) {
   _note.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.updatePrayerNote(
  id: id,
)
.note(note)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdatePrayerNoteData, UpdatePrayerNoteVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.updatePrayerNote(
  id: id,
);
UpdatePrayerNoteData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.updatePrayerNote(
  id: id,
).ref();
ref.execute();
```


### ReorderSubjects
#### Required Arguments
```dart
String orderedIds = ...;
PlusprayerConnector.instance.reorderSubjects(
  orderedIds: orderedIds,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ReorderSubjectsData, ReorderSubjectsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.reorderSubjects(
  orderedIds: orderedIds,
);
ReorderSubjectsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String orderedIds = ...;

final ref = PlusprayerConnector.instance.reorderSubjects(
  orderedIds: orderedIds,
).ref();
ref.execute();
```


### MarkIntentionAnswered
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.markIntentionAnswered(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<MarkIntentionAnsweredData, MarkIntentionAnsweredVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.markIntentionAnswered(
  id: id,
);
MarkIntentionAnsweredData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.markIntentionAnswered(
  id: id,
).ref();
ref.execute();
```


### ReleaseIntention
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.releaseIntention(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ReleaseIntentionData, ReleaseIntentionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.releaseIntention(
  id: id,
);
ReleaseIntentionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.releaseIntention(
  id: id,
).ref();
ref.execute();
```


### ArchiveSubject
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.archiveSubject(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<ArchiveSubjectData, ArchiveSubjectVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.archiveSubject(
  id: id,
);
ArchiveSubjectData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.archiveSubject(
  id: id,
).ref();
ref.execute();
```


### RestoreSubject
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.restoreSubject(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<RestoreSubjectData, RestoreSubjectVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.restoreSubject(
  id: id,
);
RestoreSubjectData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.restoreSubject(
  id: id,
).ref();
ref.execute();
```


### PurgeSubject
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.purgeSubject(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<PurgeSubjectData, PurgeSubjectVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.purgeSubject(
  id: id,
);
PurgeSubjectData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.purgeSubject(
  id: id,
).ref();
ref.execute();
```


### SetSubjectAvatarTone
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.setSubjectAvatarTone(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For SetSubjectAvatarTone, we created `SetSubjectAvatarToneBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class SetSubjectAvatarToneVariablesBuilder {
  ...
   SetSubjectAvatarToneVariablesBuilder avatarTone(int? t) {
   _avatarTone.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.setSubjectAvatarTone(
  id: id,
)
.avatarTone(avatarTone)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<SetSubjectAvatarToneData, SetSubjectAvatarToneVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.setSubjectAvatarTone(
  id: id,
);
SetSubjectAvatarToneData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.setSubjectAvatarTone(
  id: id,
).ref();
ref.execute();
```


### UpdateMySettings
#### Required Arguments
```dart
// No required arguments
PlusprayerConnector.instance.updateMySettings().execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateMySettings, we created `UpdateMySettingsBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateMySettingsVariablesBuilder {
  ...
 
  UpdateMySettingsVariablesBuilder locale(String? t) {
   _locale.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder timezone(String? t) {
   _timezone.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder listLiveOptIn(bool? t) {
   _listLiveOptIn.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder showNamesInNotifications(bool? t) {
   _showNamesInNotifications.value = t;
   return this;
  }
  UpdateMySettingsVariablesBuilder graceOffersEnabled(bool? t) {
   _graceOffersEnabled.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.updateMySettings()
.locale(locale)
.timezone(timezone)
.listLiveOptIn(listLiveOptIn)
.showNamesInNotifications(showNamesInNotifications)
.graceOffersEnabled(graceOffersEnabled)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateMySettingsData, UpdateMySettingsVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.updateMySettings();
UpdateMySettingsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = PlusprayerConnector.instance.updateMySettings().ref();
ref.execute();
```


### CreateReminder
#### Required Arguments
```dart
ReminderSlot slot = ...;
String localTime = ...;
PlusprayerConnector.instance.createReminder(
  slot: slot,
  localTime: localTime,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateReminder, we created `CreateReminderBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateReminderVariablesBuilder {
  ...
   CreateReminderVariablesBuilder enabled(bool? t) {
   _enabled.value = t;
   return this;
  }
  CreateReminderVariablesBuilder label(String? t) {
   _label.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.createReminder(
  slot: slot,
  localTime: localTime,
)
.enabled(enabled)
.label(label)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateReminderData, CreateReminderVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.createReminder(
  slot: slot,
  localTime: localTime,
);
CreateReminderData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
ReminderSlot slot = ...;
String localTime = ...;

final ref = PlusprayerConnector.instance.createReminder(
  slot: slot,
  localTime: localTime,
).ref();
ref.execute();
```


### UpdateReminder
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.updateReminder(
  id: id,
).execute();
```

#### Optional Arguments
We return a builder for each query. For UpdateReminder, we created `UpdateReminderBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class UpdateReminderVariablesBuilder {
  ...
   UpdateReminderVariablesBuilder enabled(bool? t) {
   _enabled.value = t;
   return this;
  }
  UpdateReminderVariablesBuilder localTime(String? t) {
   _localTime.value = t;
   return this;
  }
  UpdateReminderVariablesBuilder label(String? t) {
   _label.value = t;
   return this;
  }

  ...
}
PlusprayerConnector.instance.updateReminder(
  id: id,
)
.enabled(enabled)
.localTime(localTime)
.label(label)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<UpdateReminderData, UpdateReminderVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.updateReminder(
  id: id,
);
UpdateReminderData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.updateReminder(
  id: id,
).ref();
ref.execute();
```


### DeleteReminder
#### Required Arguments
```dart
String id = ...;
PlusprayerConnector.instance.deleteReminder(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteReminderData, DeleteReminderVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await PlusprayerConnector.instance.deleteReminder(
  id: id,
);
DeleteReminderData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = PlusprayerConnector.instance.deleteReminder(
  id: id,
).ref();
ref.execute();
```

