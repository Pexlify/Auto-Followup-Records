public class AllDataVisibilityPermissionChecker {
    private static AllDataVisibilityPermissionChecker Instance;
    @testVisible
    private Set<Id> UserIdWHoHAsViewDataPermissionSet;

    private AllDataVisibilityPermissionChecker() {
    }

    public static AllDataVisibilityPermissionChecker getInstance() {
        if(Instance == null) {
            Instance = new AllDataVisibilityPermissionChecker();
        }
        return Instance;
    }

    public void getAllViewAccessToObject(SobjectType stype) {
        String string_stype = String.valueOf(stype);
        List<PermissionSetAssignment> assignments = [SELECT AssigneeId FROM PermissionSetAssignment
                WHERE PermissionSetId
                IN (SELECT ParentId
                FROM ObjectPermissions
                WHERE SObjectType = :string_stype AND PermissionsViewAllRecords = true)];
        UserIdWHoHAsViewDataPermissionSet = getIdFieldValues(assignments, PermissionSetAssignment.AssigneeId);
    }

    public Boolean doesUserHasViewDataPermission(Id user_id){
        return UserIdWHoHAsViewDataPermissionSet.contains(user_id);
    }

    public static Set<Id> getIdFieldValues(SObject[] objects, SObjectField field) {
        return getIdFieldValues(objects, field.getDescribe().getName());
    }

    public static Set<Id> getIdFieldValues(SObject[] objects, String field) {
        Set<Id> result = new Set<Id> ();
        if (objects != null && !objects.isEmpty()) {
            for (SObject o : objects) {
                result.add((Id)o.get(field));
            }
            result.remove(null);
        }
        return result;
    }
}