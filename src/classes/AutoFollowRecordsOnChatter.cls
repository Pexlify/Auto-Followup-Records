public  class AutoFollowRecordsOnChatter {
    private static AutoFollowRecordsOnChatter Instance;
    @TestVisible
    private String SobjectTypeString {
        set {
            SobjectTypeString = value;
            if(FieldsMap == null) {
                FieldsMap = Schema.getGlobalDescribe().get(SobjectTypeString).getDescribe().fields.getMap();
            }
        }
        get {
            return SobjectTypeString;
        }
    }
    private Map<String, Schema.SObjectField> FieldsMap;

    private AutoFollowRecordsOnChatter() {
    }

    public static AutoFollowRecordsOnChatter getInstance() {
        if(Instance == null) {
            Instance = new AutoFollowRecordsOnChatter();
        }
        return Instance;
    }

    public void subscribeUsersToRecords(List<Id> sobject_ids){
        List<Auto_Follow_Up__mdt> settings_list = getCustomMetadataSettings(sobject_ids);
        if(!settings_list.isEmpty()) {
            List<String> needed_fields = extractNeededObjectsFieldsFromSettings(settings_list);
            List<sObject> selected_objects = selectContextObjects(sobject_ids, needed_fields);
            SharingAccessChecker.getInstance().selectAllAccessesToRecords(sobject_ids);
            for(Auto_Follow_Up__mdt setting: settings_list) {
                String users_query = generateAllUsersQuery(setting);
                List<User> list_users = Database.query(users_query);
                Map<Id, Set<Id>> record_ids_set_by_user_id_want_to_subscribe = getWhoToWhatWantsToSubsribeBasedOnSetting(setting, list_users, selected_objects);
                List<Id> user_ids = new List<Id>(record_ids_set_by_user_id_want_to_subscribe.keySet());
                ChatterFeedFollower.getInstance().selectAlreadyExistedSubscriptions(sobject_ids, user_ids);
                for(Id user_id:record_ids_set_by_user_id_want_to_subscribe.keySet()) {
                    for(Id record_id: record_ids_set_by_user_id_want_to_subscribe.get(user_id)) {
                        if(SharingAccessChecker.getInstance().doesUserHasAccessToRecord(record_id, user_id)) {
                            ChatterFeedFollower.getInstance().subscribeToRecord(record_id, user_id);
                        }
                    }
                }
                ChatterFeedFollower.getInstance().insertNewlyCreatedSubscriptions();
            }
        }
    }

    @TestVisible
    private List<Auto_Follow_Up__mdt> getCustomMetadataSettings(List<Id> sobject_ids) {
        List<Auto_Follow_Up__mdt> result = new List<Auto_Follow_Up__mdt>();
        if(!sobject_ids.isEmpty()) {
            defineSobjectTypeStringValue(sobject_ids);
            result = [SELECT Criteria_Field__c, Is_User_Field__c, Operator__c, SObject__c, SObject_Field__c, Record_Type__c
                        FROM Auto_Follow_Up__mdt WHERE SObject__c =:SobjectTypeString];
        }
        return result;
    }

    @TestVisible
    private void defineSobjectTypeStringValue(List<Id> sobject_ids) {
        Id record_id = sobject_ids.get(0);
        SObjectType sobject_type = record_id.getSObjectType();
        SobjectTypeString = String.valueOf(sobject_type);
    }

    @TestVisible
    private List<String> extractNeededObjectsFieldsFromSettings(List<Auto_Follow_Up__mdt> settings_list) {
        Set<String> set_result = new Set<String>();
        for(Auto_Follow_Up__mdt setting: settings_list) {
            set_result.add(setting.SObject_Field__c);
        }
        return new List<String>(set_result);
    }

    @TestVisible
    private List<sObject> selectContextObjects(List<Id> sobject_ids, List<String> fields) {
        Set<String> all_fields = getAllFieldApiNames(sobject_ids.get(0).getSObjectType());
        if(all_fields.contains('recordtypeid')) {
            fields.add('RecordTypeId');
        }
        String query ='SELECT Id, '+String.join(fields, ', ')+' FROM '+SobjectTypeString+' WHERE Id IN :sobject_ids';
        return Database.query(query);
    }

    private static Set<String> getAllFieldApiNames(SObjectType stype){
        Schema.DescribeSObjectResult describe_result = stype.getDescribe();
        Set<String> all_fields = describe_result.fields.getMap().keySet();
        return all_fields;
    }

    @TestVisible
    private String generateAllUsersQuery(Auto_Follow_Up__mdt setting) {
        String query = 'SELECT Id';
        List<String> fields = new List<String>();
        if(setting.Is_User_Field__c) {
            fields.add(setting.Criteria_Field__c);
        }
        if(!fields.isEmpty()) {
            query+=', ';
            query+=String.join(fields, ', ');
        }
        query+=' FROM User';
        if(!fields.isEmpty()) {
            query+=' WHERE ';
            query+=String.join(fields, ' != null OR ');
            query+=' != null';
            query+=' AND isActive = true';
        }
        return query;
    }

    @TestVisible
    private Map<Id, Set<Id>> getWhoToWhatWantsToSubsribeBasedOnSetting(Auto_Follow_Up__mdt setting, List<User> users, List<sObject> selected_objects) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        for(sObject sobj: selected_objects) {
            SObjectType stype = sobj.getSobjectType();
            for(User usr:users) {
                if(isUserFieldForCriteriaisPopulated(setting, usr) && doesCriteriaIsMet(setting, usr, sobj, stype)) {
                    Set<Id> objects_ids = new Set<Id>();
                    if(result.containsKey(usr.Id)) {
                        objects_ids = result.get(usr.Id);
                        objects_ids.add(sobj.Id);
                    } else {
                        objects_ids.add(sobj.Id);
                    }
                    result.put(usr.Id, objects_ids);
                }
            }
        }
        return result;
    }

    private Boolean isUserFieldForCriteriaisPopulated(Auto_Follow_Up__mdt setting, User usr) {
        if(!setting.Is_User_Field__c) {
            return true;
        } else {
            Object usr_field = usr.get(setting.Criteria_Field__c);
            return usr_field == null ? false : true;
        }
    }

    @TestVisible
    private Boolean doesCriteriaIsMet(Auto_Follow_Up__mdt setting, User usr, SObject obj, SObjectType stype) {
        String stype_string = String.valueOf(stype);
        String setting_sobj_field = setting.SObject_Field__c;
        if(!FieldsMap.containsKey(setting_sobj_field)) {
            throw new FollowUpException('No '+setting_sobj_field+' field on '+stype_string+' sObject');
        }
        if(!doesRecordTypeIsMet(setting, obj)) {
            return false;
        }
        SObjectField s_field = FieldsMap.get(setting_sobj_field);
        SOAPType soap_type = s_field.getDescribe().getSOAPType();
        if(soap_type == SOAPType.STRING || soap_type == SOAPType.ID) {
            return doesCriteriaIsMetString(setting, usr, obj);
        } else if(soap_type == SOAPType.INTEGER || soap_type == SOAPType.DOUBLE){
            return doesCriteriaIsMetDecimal(setting, usr, obj);
        }
        return false;
    }

    @TestVisible
    private Boolean doesRecordTypeIsMet(Auto_Follow_Up__mdt setting, SObject obj){
        if(String.isBlank(setting.Record_Type__c)) {
            return true;
        }
        List<String> list_record_types = setting.Record_Type__c.split(';');
        String sobj_current_record_type_key = RecordTypeUtility.getInstance().getKeyById((Id)obj.get('RecordTypeId'));
        if(sobj_current_record_type_key == null) {
            return false;
        }
        for(String record_type :list_record_types) {
            String sobj_name_and_recordType = obj.getSobjectType()+'.'+record_type;
            if(sobj_current_record_type_key.equals(sobj_name_and_recordType)) {
                return true;
            }
        }
        return false;
    }

    @TestVisible
    private Boolean doesCriteriaIsMetString(Auto_Follow_Up__mdt setting, User usr, SObject obj) {
        Boolean result = false;
        String setting_sobj_field = setting.SObject_Field__c;
        Object obj_sobj_value = obj.get(setting_sobj_field);
        if(obj_sobj_value == null) {
            return result;
        }
        String str_sobj_value = String.valueOf(obj.get(setting_sobj_field));
        String str_user_value = null;
        if(setting.Is_User_Field__c) {
            String setting_user_field = setting.Criteria_Field__c;
            Object field_obj_value = usr.get(setting_user_field);
            if(field_obj_value == null) {
                return result;
            }
            str_user_value = String.valueOf(field_obj_value);
        } else {
            str_user_value = setting.Criteria_Field__c;
        }
        if(setting.Operator__c == 'equals') {
            result = str_sobj_value == str_user_value;
        } else if(setting.Operator__c == 'not equals to'){
            result = str_sobj_value != str_user_value;
        } else if(setting.Operator__c == 'contains'){
            result = str_sobj_value.contains(str_user_value);
        } else if(setting.Operator__c == 'does not contain'){
            result = !str_sobj_value.contains(str_user_value);
        } else if(setting.Operator__c == 'starts with'){
            result = str_sobj_value.startsWith(str_user_value);
        } else {
            throw new FollowUpException('Inapplicable logic operation for String type');
        }
        return result;
    }

    @TestVisible
    private Boolean doesCriteriaIsMetDecimal(Auto_Follow_Up__mdt setting, User usr, SObject obj) {
        Boolean result = false;
        String setting_sobj_field = setting.SObject_Field__c;
        Object obj_sobj_value = obj.get(setting_sobj_field);
        if(obj_sobj_value == null) {
            return false;
        }
        Decimal decimal_sobj_value = (Decimal) obj_sobj_value;
        Decimal decimal_user_value = null;
        if(setting.Is_User_Field__c) {
            String setting_user_field = setting.Criteria_Field__c;
            Object field_obj_value = usr.get(setting_user_field);
            if(field_obj_value == null) {
                return false;
            }
            decimal_user_value = (Decimal) field_obj_value;
        } else {
            decimal_user_value = Decimal.valueOf(setting.Criteria_Field__c);
        }
        Decimal converted_decimal_sobj_value = decimal_sobj_value;
        if(setting.Operator__c == 'equals') {
            result = converted_decimal_sobj_value == decimal_user_value;
        } else if(setting.Operator__c == 'not equals to'){
            result = converted_decimal_sobj_value != decimal_user_value;
        } else if(setting.Operator__c == 'less then'){
            result = converted_decimal_sobj_value < decimal_user_value;
        } else if(setting.Operator__c == 'greater then'){
            result = converted_decimal_sobj_value > decimal_user_value;
        } else if(setting.Operator__c == 'less or equal'){
            result = converted_decimal_sobj_value <= decimal_user_value;
        } else if(setting.Operator__c == 'greater or equal'){
            result = converted_decimal_sobj_value >= decimal_user_value;
        } else {
            throw new FollowUpException('Inapplicable logic operation for Decimal type');
        }
        return result;
    }

    private class FollowUpException extends Exception {}
}