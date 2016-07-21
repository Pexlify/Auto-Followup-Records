public class GroupUtility {
    private static GroupUtility Instance;
    private Boolean QueryMode;
    private Map<String, Group> OnlyGroupsByDevName;
    private Map<String, Group> AllGroupsByDevName;
    private Map<Id, Group> OnlyGroupsById;

    private GroupUtility() {
    }

    public static GroupUtility getInstance() {
        if(Instance == null) {
            Instance = new GroupUtility();
        }
        return Instance;
    }

    public GroupUtility setQueryMode(Boolean query_mode){
        Instance.QueryMode = query_mode;
        Instance.populateContainers();
        return Instance;
}

    public Boolean isUserGroupMember(Id user_id, String group_dev_name){
        populateContainers();
        Boolean is_user_a_member_of_group = false;
        if(OnlyGroupsByDevName.containsKey(group_dev_name)) {
            Group temp_group = OnlyGroupsByDevName.get(group_dev_name);
            is_user_a_member_of_group = isUserInGroupMembers(user_id, temp_group.GroupMembers);
        }
        return is_user_a_member_of_group;
    }

    public Boolean isUserGroupMember(Id user_id, Id group_Id){
        populateContainers();
        Boolean is_user_a_member_of_group = false;
        populateOnlyGroupsById();
        if(OnlyGroupsById.containsKey(group_Id)) {
            Group temp_group = OnlyGroupsById.get(group_Id);
            is_user_a_member_of_group = isUserInGroupMembers(user_id, temp_group.GroupMembers);
        }
        return is_user_a_member_of_group;
    }

    private void populateContainers() {
        if(OnlyGroupsByDevName == null || QueryMode) {
            OnlyGroupsByDevName = getAllGroupsOnly();
        }
        if(AllGroupsByDevName == null || QueryMode) {
            AllGroupsByDevName = getAllGroupsGroupsAndQueues();
        }
    }

    private void populateOnlyGroupsById() {
        if(OnlyGroupsById == null) {
            OnlyGroupsById = new Map<Id, Group>();
            for(Group grp:OnlyGroupsByDevName.values()) {
                OnlyGroupsById.put(grp.Id, grp);
            }
        }
    }

    private Map<String, Group> getAllGroupsGroupsAndQueues() {
        List<Group> selected_groups = getAllGroupsOrQueues(null);
        return mapGroupsByDeveloperName(selected_groups);
    }

    private Map<String, Group> getAllGroupsOnly() {
        List<Group> selected_groups = getAllGroupsOrQueues(true);
        return mapGroupsByDeveloperName(selected_groups);
    }

    private Map<String, Group> getAllQueuesOnly() {
        List<Group> selected_groups = getAllGroupsOrQueues(false);
        return mapGroupsByDeveloperName(selected_groups);
    }

    private Map<String, Group> mapGroupsByDeveloperName(List<Group> groups) {
        Map<String, Group> result = new Map<String, Group>();
        for(Group temp_group:groups) {
            result.put(temp_group.DeveloperName, temp_group);
        }
        return result;
    }

    private List<Group> getAllGroupsOrQueues(Boolean is_group_only){
        String query = 'SELECT Id, Name, DeveloperName, Type, (SELECT UserOrGroupId FROM GroupMembers) FROM Group';
        if (is_group_only != null) {
            if(is_group_only) {
                query +=' WHERE Type = \'Regular\'';
            } else {
                query +=' WHERE Type = \'Queue\'';
            }
        } else {
             query +=' WHERE Type = \'Queue\' OR Type = \'Regular\'';
        }
        return Database.query(query);
    }

    private Boolean isUserInGroupMembers(Id user_id, List<GroupMember> group_members){
        for(GroupMember group_member : group_members){
            if(isIdAUserTypeId(group_member.UserOrGroupId)){
                if(group_member.UserOrGroupId == user_id){
                    return true;
                }
            }
        }
        return false;
    }

    private Boolean isIdAUserTypeId(Id id_to_check){
        SObjectType sobject_type = id_to_check.getSObjectType();
        DescribeSObjectResult describe_result = sobject_type.getDescribe();
        String api_name = describe_result.getName();
        return api_name == 'User';
    }

    public Set<Id> getAllUsersIdOfGroupIdsList(List<Id> groups_id) {
        Set<Id> result = new Set<Id>();
        populateOnlyGroupsById();
        for(Id group_id :groups_id) {
            result.addAll(getAllUsersIdFromGroupId(group_id));
        }
        return result;
    }

    public Set<Id> getAllUsersIdFromGroupId(Id group_id) {
        Set<Id> result = new Set<Id>();
        populateOnlyGroupsById();
        if(OnlyGroupsById.containsKey(group_id)) {
            List<GroupMember> members = OnlyGroupsById.get(group_id).GroupMembers;
            for(GroupMember member: members) {
                if(isIdAUserTypeId(member.UserOrGroupId)) {
                    result.add(member.UserOrGroupId);
                } else if(OnlyGroupsById.containsKey(member.UserOrGroupId)) {
                    result.addAll(getAllUsersIdFromGroupId(member.UserOrGroupId));
                }
            }
        } else {
            throw new GroupException('Group with '+group_id+' Id doesn\'t exist');
        }
        return result;
    }

    public Id getIdByGroupDeveloperName(String dev_name){
        Id result = null;
        if(AllGroupsByDevName.containsKey(dev_name)) {
            result = AllGroupsByDevName.get(dev_name).Id;
        } else {
            throw new GroupException('Group with '+dev_name+' DeveloperName doesn\'t exist');
        }
        return result;
    }

    public Boolean isRegularGroup(Id group_id){
        populateOnlyGroupsById();
        return OnlyGroupsById.containsKey(group_id);
    }


    public class GroupException extends Exception {}
}