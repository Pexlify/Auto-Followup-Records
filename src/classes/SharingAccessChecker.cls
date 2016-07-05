public class SharingAccessChecker {
    private static final Set<SObjectType> ExceptionalObjectsWithDiffFieldName = new Set<SObjectType> {
        AccountShare.SObjectType,
        CampaignShare.SObjectType,
        CaseShare.SObjectType,
        ContactShare.SObjectType,
        LeadShare.SObjectType,
        OpportunityShare.SObjectType,
        UserShare.SObjectType
    };
    private static SharingAccessChecker Instance;
    @TestVisible
    private Set<ShareWrapper> ShareObjects = new Set<ShareWrapper>();
    private Map<String, Boolean> StandardObjectsAccess = new Map<String, Boolean>();

    private SharingAccessChecker() {

    }

    public static SharingAccessChecker getInstance() {
        if(Instance == null) {
            Instance = new SharingAccessChecker();
        }
        return Instance;
    }

    public void selectAllAccessesToRecords(List<Id> record_ids) {
        if(!record_ids.isEmpty() && !isRecordHasAtLeastPublicReadOWD(record_ids.get(0))) {
            AllDataVisibilityPermissionChecker.getInstance().getAllViewAccessToObject(record_ids.get(0).getSObjectType());
            List<sObject> sobject_selected = selectSharingObjects(record_ids);
            populateShareObjectsMap(sobject_selected);
        }
    }

    public Boolean doesUserHasAccessToRecord(Id record_id, Id user_id){
        if(isRecordHasAtLeastPublicReadOWD(record_id)) {
            return true;
        }
        ShareWrapper wrapper = new ShareWrapper(record_id, user_id);
        return ShareObjects.contains(wrapper) || AllDataVisibilityPermissionChecker.getInstance().doesUserHasViewDataPermission(user_id);
    }

    @TestVisible
    private Boolean isRecordHasAtLeastPublicReadOWD(Id record_id){
        SObjectType sobject_type = record_id.getSObjectType();
        DescribeSObjectResult describe_result = sobject_type.getDescribe();
        if(describe_result.isCustom()) {
            return isShareObjectOrgAccessible(sobject_type);
        } else {
            String string_object = String.valueOf(sobject_type);
            Set<String> objects_related_toaccounts =  new Set<String> {
                'Contract',
                'Asset'
            };
            if (objects_related_toaccounts.contains(string_object)) {
                string_object = 'Account';
            }
            if(StandardObjectsAccess.containsKey(string_object)) {
                return StandardObjectsAccess.get(string_object);
            } else {
                String query = 'SELECT Default'+string_object+'Access FROM Organization LIMIT 1';
                Organization org = Database.query(query);
                String default_access = String.valueOf(org.get('Default'+string_object+'Access'));
                Boolean access = isNotNoneAccess(default_access);
                StandardObjectsAccess.put(string_object, access);
                return access;
            }
        }
    }

    @TestVisible
    private Boolean isShareObjectOrgAccessible(SObjectType sobject_type) {
        Map<String,Schema.SObjectType> sharing = Schema.getGlobalDescribe();
        String share_object_string = String.valueOf(defineShareObjectType(sobject_type));
        if(share_object_string != null) {
            share_object_string = share_object_string.toLowerCase();
        }
        return !sharing.containsKey(share_object_string);
    }

    private Boolean isNotNoneAccess(String object_access) {
        return object_access != 'None';
    }

    @TestVisible
    private List<sObject> selectSharingObjects(List<Id> record_ids) {
        SObjectType sobject_type = record_ids.get(0).getSObjectType();
        SObjectType sobject_type_share = defineShareObjectType(sobject_type);
        String record_id_field_api_name = getRecordIdFieldApiName(sobject_type_share);
        String record_access_field_api_name = getAccessLevelFieldApiName(sobject_type_share);
        String query = 'SELECT '+record_id_field_api_name+', UserOrGroupId, '+record_access_field_api_name;
        query+=' FROM '+sobject_type_share+' WHERE '+record_id_field_api_name+' IN:record_ids';
        return Database.query(query);
    }

    @TestVisible
    private SObjectType defineShareObjectType(SObjectType sobject_type) {
        DescribeSObjectResult describe_result = sobject_type.getDescribe();
        String api_name = describe_result.getName();
        String share = 'Share';
        if(describe_result.isCustom()) {
            api_name = api_name.replace('__c', '');
            share='__'+share;
        }
        api_name+=share;
        SObjectType convertType = Schema.getGlobalDescribe().get(api_name);
        return convertType;
    }

    @TestVisible
    private void populateShareObjectsMap(List<sObject> sObject_list) {
        if(!sObject_list.isEmpty()) {
            SObjectType s_type = sObject_list.get(0).getSObjectType();
            for(sObject sobj: sObject_list) {
                Id record_id = getRelatedRecordId(sobj);
                String user_group_id_string = String.valueOf(sobj.get('UserOrGroupId'));
                Id user_group_id = Id.valueOf(user_group_id_string);
                String access_level = getAccessLevel(sobj);
                if(isIdAUserTypeId(user_group_id)) {
                    ShareWrapper wrapper = new ShareWrapper(record_id, user_group_id, access_level);
                    ShareObjects.add(wrapper);
                } else {
                    Set<Id> users_id = GroupUtility.getInstance().setQueryMode(true).getAllUsersIdFromGroupId(user_group_id);
                    for(Id user_id :users_id) {
                        ShareWrapper wrapper = new ShareWrapper(record_id, user_id, access_level);
                        ShareObjects.add(wrapper);
                    }
                }
            }
        }
    }

    @TestVisible
    private Id getRelatedRecordId(SObject sobj) {
        String record_id_field_name = getRecordIdFieldApiName(sobj.getSObjectType());
        String record_id_string = String.valueof(sobj.get(record_id_field_name));
        Id result = Id.valueOf(record_id_string);
        return result;
    }

    @TestVisible
    private String getRecordIdFieldApiName(SObjectType api_name_type) {
        String result = 'ParentId';
        if(ExceptionalObjectsWithDiffFieldName.contains(api_name_type)) {
            String api_name_type_string = String.valueOf(api_name_type);
            result = api_name_type_string.replace('Share','')+'Id';
        }
        return result;
    }

    @TestVisible
    private String getAccessLevel(SObject sobj) {
        String access_level_field_name = getAccessLevelFieldApiName(sobj.getSObjectType());
        String access_level = String.valueOf(sobj.get(access_level_field_name));
        return access_level;
    }

    @TestVisible
    private String getAccessLevelFieldApiName(SObjectType api_name_type) {
        String string_share_name = String.ValueOf(api_name_type);
        if(string_share_name.contains('__Share')) {
            return 'AccessLevel';
        }
        String share_suffix = 'Share';
        if(!ExceptionalObjectsWithDiffFieldName.contains(api_name_type)) {
            share_suffix = '__'+share_suffix;
        }
        String api_name_type_string = String.valueOf(api_name_type);
        String result = api_name_type_string.replace(share_suffix,'')+'AccessLevel';
        return result;
    }

    private Boolean isIdAUserTypeId(Id id_to_check){
        SObjectType sobject_type = id_to_check.getSObjectType();
        DescribeSObjectResult describe_result = sobject_type.getDescribe();
        String api_name = describe_result.getName();
        return api_name == 'User';
    }

    @TestVisible
    private class ShareWrapper {
        @TestVisible
        private Id RecordId;
        @TestVisible
        private Id UserId;
        private SharingAccessLevelUtility.AccessLevel Level;

        private ShareWrapper(Id record_id, Id user_id) {
            RecordId = record_id;
            UserId = user_id;
        }

        private ShareWrapper(Id record_id, Id user_id, String access_level) {
            RecordId = record_id;
            UserId = user_id;
            Level = SharingAccessLevelUtility.getInstance().getAccessLevel(access_level);
        }

        public Boolean equals(Object obj) {
            if (obj instanceof ShareWrapper) {
                ShareWrapper casted = (ShareWrapper)obj;
                return (RecordId==casted.RecordId) && (UserId==casted.UserId);
            }
            return false;
        }

        public Integer hashCode() {
            Integer size_record_id = Blob.valueOf(RecordId).size();
            Integer size_user_id = Blob.valueOf(UserId).size();
            return (72 * size_user_id) ^ size_record_id;
        }
    }
}