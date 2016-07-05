@isTest
private class SharingAccessLevelUtilityTest {
    @isTest
    static void testGetAccessLevelCorrectNameExtraction() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            String access_level = 'Edit';
            Test.startTest();
                SharingAccessLevelUtility.AccessLevel actual_level = SharingAccessLevelUtility.getInstance().getAccessLevel(access_level);
            Test.stopTest();
            System.assertEquals(SharingAccessLevelUtility.AccessLevel.EDIT, actual_level, 'Incorrect access level');
        }
    }

    @isTest
    static void testGetAccessLevelNameCorrectNameExtraction() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            SharingAccessLevelUtility.AccessLevel access_level = SharingAccessLevelUtility.AccessLevel.EDIT;
            Test.startTest();
                String actual_level = SharingAccessLevelUtility.getInstance().getAccessLevelName(access_level);
            Test.stopTest();
            System.assertEquals('Edit', actual_level, 'Incorrect access level');
        }
    }

    public class SetupTestData {
        public User TestUser {get; set;}

        public SetupTestData() {
            TestUser = UserTestData.getUserForTest().setProfile('System Administrator').save().getRecord();
        }
    }
}