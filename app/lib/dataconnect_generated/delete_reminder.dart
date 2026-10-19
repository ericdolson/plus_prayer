part of 'plusprayer.dart';

class DeleteReminderVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteReminderVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteReminderData> dataDeserializer = (dynamic json)  => DeleteReminderData.fromJson(jsonDecode(json));
  Serializer<DeleteReminderVariables> varsSerializer = (DeleteReminderVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteReminderData, DeleteReminderVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteReminderData, DeleteReminderVariables> ref() {
    DeleteReminderVariables vars= DeleteReminderVariables(id: id,);
    return _dataConnect.mutation("DeleteReminder", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteReminderData {
  final int reminderPreference_deleteMany;
  DeleteReminderData.fromJson(dynamic json):
  
  reminderPreference_deleteMany = nativeFromJson<int>(json['reminderPreference_deleteMany']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteReminderData otherTyped = other as DeleteReminderData;
    return reminderPreference_deleteMany == otherTyped.reminderPreference_deleteMany;
    
  }
  @override
  int get hashCode => reminderPreference_deleteMany.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['reminderPreference_deleteMany'] = nativeToJson<int>(reminderPreference_deleteMany);
    return json;
  }

  DeleteReminderData({
    required this.reminderPreference_deleteMany,
  });
}

@immutable
class DeleteReminderVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteReminderVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteReminderVariables otherTyped = other as DeleteReminderVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteReminderVariables({
    required this.id,
  });
}

