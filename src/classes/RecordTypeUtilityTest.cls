@isTest
private class RecordTypeUtilityTest {

    @isTest
    static void testGetKeyById(){
        SetupTestData setup_data = new SetupTestData();
        System.runAs(setup_data.TestUser) {
            Id recordTypeId = [SELECT id, DeveloperName FROM RecordType WHERE (DeveloperName='Progress') AND isActive = true AND SobjectType='Metric'].Id;
            Test.startTest();
                String returnedRecordTypeKey = RecordTypeUtility.getInstance().getKeyById(recordTypeId);
            Test.stopTest();
            System.assertEquals('Metric.Progress',returnedRecordTypeKey, 'Incorrect Record Type key is returned');
        }
    }

    public class SetupTestData {
        public User TestUser {get;set;}

        public SetupTestData() {
           TestUser = UserTestData.getUserForTest().setProfile('System Administrator').save().getRecord();
        }
    }
}