@isTest
private class GroupUtilityTest {

    @isTest
    static void testIsUserGroupMemberUserIsAMember() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            setup_data.addCurrentUserToGroup('Test_Group');
            Test.startTest();
                Boolean expected_result = GroupUtility.getInstance().setQueryMode(false).isUserGroupMember(setup_data.TestUser.Id, setup_data.TestGroup.DeveloperName);
            Test.stopTest();
            System.assertEquals(true, expected_result, 'User should be a member of group');
        }
    }

    @isTest
    static void testIsUserGroupMemberIdParamUserIsAMember() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            setup_data.addCurrentUserToGroup('Test_Group');
            Test.startTest();
                Boolean expected_result = GroupUtility.getInstance().setQueryMode(false).isUserGroupMember(setup_data.TestUser.Id, setup_data.TestGroup.Id);
            Test.stopTest();
            System.assertEquals(true, expected_result, 'User should be a member of group');
        }
    }

    @isTest
    static void testIsUserGroupMemberUserIsNotAMember() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            Test.startTest();
                Boolean expected_result = GroupUtility.getInstance().setQueryMode(false).isUserGroupMember(setup_data.TestUser.Id, setup_data.TestGroup.DeveloperName);
            Test.stopTest();
            System.assertEquals(false, expected_result, 'User shouldn\'t be a member of group');
        }
    }

    @isTest
    static void testIsUserGroupMemberIdParamUserIsNotAMember() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            Test.startTest();
                Boolean expected_result = GroupUtility.getInstance().setQueryMode(false).isUserGroupMember(setup_data.TestUser.Id, setup_data.TestGroup.Id);
            Test.stopTest();
            System.assertEquals(false, expected_result, 'User shouldn\'t be a member of group');
        }
    }

    @isTest
    static void testBulkIsUserGroupMemberUserIsAMember() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            List<User> list_users = UserTestData.getListBuilder(300).setProfile('System Administrator').save().getRecords();
            setup_data.addUsersToGroup(list_users, setup_data.TestGroup.DeveloperName);
            List<Boolean> expected_results = new  List<Boolean>();
            Test.startTest();
                for(User temp_user : list_users) {
                    Boolean expected_result = GroupUtility.getInstance().setQueryMode(false).isUserGroupMember(temp_user.Id, setup_data.TestGroup.DeveloperName);
                    expected_results.add(expected_result);
                }
            Test.stopTest();
            for(Boolean result : expected_results) {
                System.assertEquals(true, result, 'User should be a member of group');
            }
        }
    }

    @isTest
    static void testBulkIsUserGroupMemberUserIsNotAMember() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            List<User> list_users = UserTestData.getListBuilder(300).setProfile('System Administrator').save().getRecords();
            List<Boolean> expected_results = new  List<Boolean>();
            Test.startTest();
                for(User temp_user : list_users) {
                    Boolean expected_result = GroupUtility.getInstance().setQueryMode(false).isUserGroupMember(temp_user.Id, setup_data.TestGroup.DeveloperName);
                    expected_results.add(expected_result);
                }
            Test.stopTest();
            for(Boolean result : expected_results) {
                System.assertEquals(false, result, 'User shouldn\'t be a member of group');
            }
        }
    }

    @isTest
    static void testBulkGetAllUsersIdOfGroupIdsListGroupIsMemberOfGroup() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            setup_data.addCurrentUserToGroup('Test_Group');
            Group group2 = setup_data.createTestGroup('Test_Group2');
            List<User> list_users = UserTestData.getListBuilder(300).setProfile('System Administrator').save().getRecords();
            setup_data.addUsersToGroup(list_users, 'Test_Group2');
            setup_data.addGroupToGroup(setup_data.TestGroup.Id, group2.Id);
            List<Id> groups_id = new List<Id>{
                setup_data.TestGroup.Id,
                group2.Id
            };
            Set<Id> expected_ids = new Set<Id>();
            expected_ids.add(setup_data.TestUser.Id);
            for(User usr:list_users) {
                expected_ids.add(usr.Id);
            }
            Test.startTest();
                Set<Id> all_users_ids_in_groups = GroupUtility.getInstance().setQueryMode(false).getAllUsersIdOfGroupIdsList(groups_id);
            Test.stopTest();
            for(Id extracted_id : expected_ids) {
                System.assertEquals(true, all_users_ids_in_groups.contains(extracted_id), 'User should be a member of Test_Group');
            }
        }
    }

    @isTest
    static void testGetIdByGroupDeveloperNameGroupExists() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            Test.startTest();
                Id actual_group_id = GroupUtility.getInstance().setQueryMode(false).getIdByGroupDeveloperName('Test_Group');
            Test.stopTest();
            System.assertEquals(setup_data.TestGroup.Id, actual_group_id, 'Incorrect Id of Group');
        }
    }

    @isTest
    static void testIsRegularGroupIsGroup() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            setup_data.TestGroup = setup_data.createTestGroup('Test_Group');
            Test.startTest();
                Boolean actual_result = GroupUtility.getInstance().setQueryMode(false).isRegularGroup(setup_data.TestGroup.Id);
            Test.stopTest();
            System.assertEquals(true, actual_result, 'This is Regular Group');
        }
    }

    @isTest
    static void testIsRegularGroupIsNotGroup() {
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser){
            Group some_group = new Group();
            some_group.Name = 'Some name';
            some_group.DeveloperName = 'Some_name';
            some_group.Type = 'Queue';
            insert some_group;
            Test.startTest();
                Boolean actual_result = GroupUtility.getInstance().setQueryMode(false).isRegularGroup(some_group.Id);
            Test.stopTest();
            System.assertEquals(false, actual_result, 'This is not a Regular Group');
        }
    }

    public class SetupTestData {
        public User TestUser {get;set;}
        public Group TestGroup {get;set;}

        public SetupTestData () {
            TestUser = UserTestData.getUserForTest().setProfile('System Administrator').save().getRecord();
        }

        public Group createTestGroup(String name) {
            Group some_group = new Group();
            some_group.Name = name;
            some_group.DeveloperName = name;
            some_group.Type = 'Regular';
            insert some_group;
            return some_group;
        }

        public void addCurrentUserToGroup(String dev_name) {
            Group selected_group = [SELECT id FROM Group WHERE DeveloperName =:dev_name LIMIT 1];
            GroupMember linker = new GroupMember();
            linker.GroupId =  selected_group.Id;
            linker.UserOrGroupId = UserInfo.getUserId();
            insert linker;
        }

        public void addUsersToGroup(List<User> users, String dev_name) {
            Group selected_group = [SELECT id FROM Group WHERE DeveloperName =:dev_name LIMIT 1];
            List<GroupMember> group_memmbers_to_insert = new List<GroupMember> ();
            for(User temp_user: users) {
                GroupMember linker = new GroupMember();
                linker.GroupId =  selected_group.Id;
                linker.UserOrGroupId = temp_user.Id;
                group_memmbers_to_insert.add(linker);
            }
            insert group_memmbers_to_insert;
        }

        public void addGroupToGroup(Id group_to, Id group_id) {
            GroupMember linker = new GroupMember();
            linker.GroupId = group_to;
            linker.UserOrGroupId = group_id;
            insert linker;
        }
    }
}