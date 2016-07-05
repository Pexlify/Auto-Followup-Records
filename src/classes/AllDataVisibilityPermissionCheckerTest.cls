@isTest
private class AllDataVisibilityPermissionCheckerTest {
    @isTest
    static void testGetAllViewAccessToObjectAccount() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            Test.startTest();
                AllDataVisibilityPermissionChecker.getInstance().getAllViewAccessToObject(Account.SobjectType);
            Test.stopTest();
            System.assertEquals(true, AllDataVisibilityPermissionChecker.getInstance().UserIdWHoHAsViewDataPermissionSet.contains(test_data.TestUser.Id), 'Admin User should have View All Permission');
        }
    }

    @isTest
    static void testDoesUserHasViewDataPermissionYesHeDoes() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            AllDataVisibilityPermissionChecker.getInstance().getAllViewAccessToObject(Account.SobjectType);
            Test.startTest();
                Boolean actual_view_permission = AllDataVisibilityPermissionChecker.getInstance().doesUserHasViewDataPermission(test_data.TestUser.Id);
            Test.stopTest();
            System.assertEquals(true, actual_view_permission, 'Admin User should have View All Permission');
        }
    }

    public class SetupTestData {
        public User TestUser {get;set;}

        public SetupTestData(){
            TestUser = UserTestData.getUserForTest().setProfile('System Administrator').save().getRecord();
        }
    }
}