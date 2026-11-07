This Swift package contains the generated Swift code for the connector `plusprayer`.

You can use this package by adding it as a local Swift package dependency in your project.

# Accessing the connector

Add the necessary imports

```
import FirebaseDataConnect
import PlusPrayerConnector

```

The connector can be accessed using the following code:

```
let connector = DataConnect.plusprayerConnector

```


## Connecting to the local Emulator
By default, the connector will connect to the production service.

To connect to the emulator, you can use the following code, which can be called from the `init` function of your SwiftUI app

```
connector.useEmulator()
```

# Queries

## GetCurrentListMetaQuery


### Using the Query Reference
```
struct MyView: View {
   var getCurrentListMetaQueryRef = DataConnect.plusprayerConnector.getCurrentListMetaQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getCurrentListMetaQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getCurrentListMetaQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getCurrentListMetaQuery.execute(...)
```


## GetPastListsQuery
### Variables


#### Optional
```swift

let limit: Int = ...
let offset: Int = ...
```



### Using the Query Reference
```
struct MyView: View {
   var getPastListsQueryRef = DataConnect.plusprayerConnector.getPastListsQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getPastListsQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getPastListsQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getPastListsQuery.execute(...)
```


## GetMyHeaderQuery


### Using the Query Reference
```
struct MyView: View {
   var getMyHeaderQueryRef = DataConnect.plusprayerConnector.getMyHeaderQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyHeaderQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyHeaderQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyHeaderQuery.execute(...)
```


## GetMySubjectsQuery


### Using the Query Reference
```
struct MyView: View {
   var getMySubjectsQueryRef = DataConnect.plusprayerConnector.getMySubjectsQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMySubjectsQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMySubjectsQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMySubjectsQuery.execute(...)
```


## SearchMySubjectsQuery
### Variables
#### Required
```swift

let query: String = ...
```




### Using the Query Reference
```
struct MyView: View {
   var searchMySubjectsQueryRef = DataConnect.plusprayerConnector.searchMySubjectsQuery.ref(...)

  var body: some View {
    VStack {
      if let data = searchMySubjectsQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await searchMySubjectsQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.searchMySubjectsQuery.execute(...)
```


## GetMyListStatusQuery
### Variables
#### Required
```swift

let listId: UUID = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getMyListStatusQueryRef = DataConnect.plusprayerConnector.getMyListStatusQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyListStatusQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyListStatusQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyListStatusQuery.execute(...)
```


## GetMyPortionQuery
### Variables


#### Optional
```swift

let listId: UUID = ...
```



### Using the Query Reference
```
struct MyView: View {
   var getMyPortionQueryRef = DataConnect.plusprayerConnector.getMyPortionQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyPortionQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyPortionQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyPortionQuery.execute(...)
```


## GetSubjectDetailQuery
### Variables
#### Required
```swift

let id: UUID = ...
```


#### Optional
```swift

let prayerLimit: Int = ...
let prayerOffset: Int = ...
```



### Using the Query Reference
```
struct MyView: View {
   var getSubjectDetailQueryRef = DataConnect.plusprayerConnector.getSubjectDetailQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getSubjectDetailQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getSubjectDetailQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getSubjectDetailQuery.execute(...)
```


## GetMyPrayerHistoryQuery
### Variables


#### Optional
```swift

let limit: Int = ...
let offset: Int = ...
```



### Using the Query Reference
```
struct MyView: View {
   var getMyPrayerHistoryQueryRef = DataConnect.plusprayerConnector.getMyPrayerHistoryQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyPrayerHistoryQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyPrayerHistoryQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyPrayerHistoryQuery.execute(...)
```


## GetMyPrayerTimeQuery
### Variables
#### Required
```swift

let weekStart: LocalDate = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getMyPrayerTimeQueryRef = DataConnect.plusprayerConnector.getMyPrayerTimeQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyPrayerTimeQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyPrayerTimeQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyPrayerTimeQuery.execute(...)
```


## GetPrayerQuery
### Variables
#### Required
```swift

let id: UUID = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getPrayerQueryRef = DataConnect.plusprayerConnector.getPrayerQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getPrayerQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getPrayerQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getPrayerQuery.execute(...)
```


## GetMyMonthQuery
### Variables
#### Required
```swift

let from: LocalDate = ...
let to: LocalDate = ...
```




### Using the Query Reference
```
struct MyView: View {
   var getMyMonthQueryRef = DataConnect.plusprayerConnector.getMyMonthQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyMonthQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyMonthQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyMonthQuery.execute(...)
```


## GetMyArchivedSubjectsQuery


### Using the Query Reference
```
struct MyView: View {
   var getMyArchivedSubjectsQueryRef = DataConnect.plusprayerConnector.getMyArchivedSubjectsQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyArchivedSubjectsQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyArchivedSubjectsQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyArchivedSubjectsQuery.execute(...)
```


## GetMyRemindersQuery


### Using the Query Reference
```
struct MyView: View {
   var getMyRemindersQueryRef = DataConnect.plusprayerConnector.getMyRemindersQuery.ref(...)

  var body: some View {
    VStack {
      if let data = getMyRemindersQueryRef.data {
        // use data in View
      }
      else {
        Text("Loading...")
      }
    }
    .task {
        do {
          let _ = try await getMyRemindersQueryRef.execute()
        } catch {
        }
      }
  }
}
```

### One-shot execute
```
DataConnect.plusprayerConnector.getMyRemindersQuery.execute(...)
```


# Mutations
## LogPrayerMutation

### Variables

#### Required
```swift

let id: UUID = ...
let startedAt: Timestamp = ...
let prayedAt: Timestamp = ...
let durationSeconds: Int = ...
let localDate: LocalDate = ...
let timezone: String = ...
let listContextNumber: Int = ...
let subjectIds: UUID = ...
```
 

#### Optional
```swift

let communityListId: UUID = ...
let note: String = ...
```

### One-shot execute
```
DataConnect.plusprayerConnector.logPrayerMutation.execute(...)
```

## UpdatePrayerNoteMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

#### Optional
```swift

let note: String = ...
```

### One-shot execute
```
DataConnect.plusprayerConnector.updatePrayerNoteMutation.execute(...)
```

## ReorderSubjectsMutation

### Variables

#### Required
```swift

let orderedIds: UUID = ...
```
 

### One-shot execute
```
DataConnect.plusprayerConnector.reorderSubjectsMutation.execute(...)
```

## MarkIntentionAnsweredMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

### One-shot execute
```
DataConnect.plusprayerConnector.markIntentionAnsweredMutation.execute(...)
```

## ReleaseIntentionMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

### One-shot execute
```
DataConnect.plusprayerConnector.releaseIntentionMutation.execute(...)
```

## ArchiveSubjectMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

### One-shot execute
```
DataConnect.plusprayerConnector.archiveSubjectMutation.execute(...)
```

## PurgeSubjectMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

### One-shot execute
```
DataConnect.plusprayerConnector.purgeSubjectMutation.execute(...)
```

## SetSubjectAvatarToneMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

#### Optional
```swift

let avatarTone: Int = ...
```

### One-shot execute
```
DataConnect.plusprayerConnector.setSubjectAvatarToneMutation.execute(...)
```

## UpdateMySettingsMutation

### Variables
 

#### Optional
```swift

let locale: String = ...
let timezone: String = ...
let listLiveOptIn: Bool = ...
let showNamesInNotifications: Bool = ...
let graceOffersEnabled: Bool = ...
```

### One-shot execute
```
DataConnect.plusprayerConnector.updateMySettingsMutation.execute(...)
```

## CreateReminderMutation

### Variables

#### Required
```swift

let slot: ReminderSlot = ...
let localTime: String = ...
```
 

#### Optional
```swift

let enabled: Bool = ...
let label: String = ...
```

### One-shot execute
```
DataConnect.plusprayerConnector.createReminderMutation.execute(...)
```

## UpdateReminderMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

#### Optional
```swift

let enabled: Bool = ...
let localTime: String = ...
let label: String = ...
```

### One-shot execute
```
DataConnect.plusprayerConnector.updateReminderMutation.execute(...)
```

## DeleteReminderMutation

### Variables

#### Required
```swift

let id: UUID = ...
```
 

### One-shot execute
```
DataConnect.plusprayerConnector.deleteReminderMutation.execute(...)
```

