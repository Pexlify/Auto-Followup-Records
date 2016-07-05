@isTest
private class SharingAccessCheckerTest {
    @isTest
    static void testGetAccessLevelFieldApiNameExceptionalObjectCorrectGet() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            SObjectType stype = LeadShare.SObjectType;
            Test.startTest();
                String retrieved_value = SharingAccessChecker.getInstance().getAccessLevelFieldApiName(stype);
            Test.stopTest();
            System.assertEquals('LeadAccessLevel', retrieved_value, 'Incorrect name of Access field was generated');
        }
    }

    @isTest
    static void testGetRecordIdFieldApiNameExceptionalObjectCorrectGet() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            SObjectType stype = LeadShare.SObjectType;
            Test.startTest();
                String retrieved_value = SharingAccessChecker.getInstance().getRecordIdFieldApiName(stype);
            Test.stopTest();
            System.assertEquals('LeadId', retrieved_value, 'Incorrect name of record field was generated');
        }
    }

    @isTest
    static void testGetRelatedRecordIdCorrectParentId() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestAccount();
            test_data.createtestOpportunity();
            test_data.createReadAccessToTestOpportunity(test_data.AdminUser.Id);
            Test.startTest();
                String retrieved_value = SharingAccessChecker.getInstance().getRelatedRecordId(test_data.TestOpportunityShare);
            Test.stopTest();
            System.assertEquals(test_data.TestOpportunity.Id, retrieved_value, 'Incorrect id of ParentID field (just id of a related record)');
        }
    }

    @isTest
    static void testPopulateShareObjectsMapStandardObjectCorrectPopulation() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestAccount();
            test_data.createtestOpportunity();
            test_data.createReadAccessToTestOpportunity(test_data.AdminUser.Id);
            List<OpportunityShare> share_objects = new List<OpportunityShare>();
            share_objects.add(test_data.TestOpportunityShare);
            Test.startTest();
                SharingAccessChecker.getInstance().populateShareObjectsMap(share_objects);
            Test.stopTest();
            System.assertEquals(1, SharingAccessChecker.getInstance().ShareObjects.size(), 'Incorrect size of share objects list');
            for(SharingAccessChecker.ShareWrapper wrapper:SharingAccessChecker.getInstance().ShareObjects) {
                System.assertEquals(test_data.TestOpportunity.Id, wrapper.RecordId, 'Incorrect recordId in share object');
                System.assertEquals(test_data.AdminUser.Id, wrapper.UserId, 'Incorrect user has access to record');
            }
        }
    }

    @isTest
    static void testPopulateShareObjectsMapViaGroupCorrectPopulation() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            Group some_group = null;
            System.runAs(test_data.AdminUser) {
                some_group = test_data.createTestGroup('Test_Group');
                test_data.createTestAccount();
                test_data.createTestOpportunity();
                test_data.addUserToGroup(test_data.AdminUser.Id, 'Test_Group');
                List<GroupMember> lst = [SELECT Id, Group.Name, UserOrGroupId FROM GroupMember WHERE GroupId = :some_group.Id];
                System.debug('lst:'+lst);
                test_data.createReadAccessToTestOpportunity(some_group.Id);
            }
            List<OpportunityShare> share_objects = new List<OpportunityShare>();
            share_objects.add(test_data.TestOpportunityShare);
            Test.startTest();
                SharingAccessChecker.getInstance().populateShareObjectsMap(share_objects);
            Test.stopTest();
            System.assertEquals(1, SharingAccessChecker.getInstance().ShareObjects.size(), 'Incorrect size of share objects list');
            for(SharingAccessChecker.ShareWrapper wrapper:SharingAccessChecker.getInstance().ShareObjects) {
                System.assertEquals(test_data.TestOpportunity.Id, wrapper.RecordId, 'Incorrect recordId in share object');
                System.assertEquals(test_data.AdminUser.Id, wrapper.UserId, 'Incorrect user has access to record');
            }
        }
    }

    @isTest
    static void testDefineShareObjectTypeStandardObjectCorrectDefinition() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            SObjectType stype = Lead.SObjectType;
            Test.startTest();
                SObjectType share_object = SharingAccessChecker.getInstance().defineShareObjectType(stype);
            Test.stopTest();
            System.assertEquals(LeadShare.SObjectType, share_object, 'Share object was generated incorrectly');
        }
    }

    @isTest
    static void testSelectSharingObjectsHasAccessCorrectSelecting() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestAccount();
            test_data.createTestOpportunity();
            test_data.createReadAccessToTestOpportunity(test_data.AdminUser.Id);
            List<Id> records_id = new List<Id> {
                test_data.TestOpportunity.Id
            };
            Test.startTest();
                List<OpportunityShare> share_objects = SharingAccessChecker.getInstance().selectSharingObjects(records_id);
            Test.stopTest();
            Boolean does_user_have_access = false;
            for (OpportunityShare share:share_objects) {
                if(share.OpportunityId == test_data.TestOpportunity.Id && share.UserOrGroupId == test_data.AdminUser.Id) {
                    does_user_have_access = true;
                }
            }
            System.assertEquals(true, does_user_have_access, 'User should have access to record');
        }
    }

    @isTest
    static void testSelectSharingObjectsHasNoAccessCorrectSelecting() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestAccount();
            test_data.createTestOpportunity();
            List<Id> records_id = new List<Id> {
                test_data.TestOpportunity.Id
            };
            Test.startTest();
                List<OpportunityShare> share_objects = SharingAccessChecker.getInstance().selectSharingObjects(records_id);
            Test.stopTest();
            Boolean does_user_have_access = false;
            for (OpportunityShare share:share_objects) {
                if(share.OpportunityId == test_data.TestOpportunity.Id && share.UserOrGroupId == test_data.AdminUser.Id) {
                    does_user_have_access = true;
                }
            }
            System.assertEquals(false, does_user_have_access, 'User shouldn\'t have access to record');
        }
    }

    @isTest
    static void testIsRecordHasAtLeastPublicReadOWDYesItHas() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestAccount();
            Test.startTest();
                Boolean actual_value = SharingAccessChecker.getInstance().isRecordHasAtLeastPublicReadOWD(test_data.TestAccount.Id);
            Test.stopTest();
            System.assertEquals(true, actual_value, 'Account has at least read OWD');
        }
    }

    @isTest
    static void testDoesUserHasAccessToRecordWithAccess() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestAccount();
            test_data.createTestOpportunity();
            test_data.createReadAccessToTestOpportunity(test_data.AdminUser.Id);
            List<Id> records_id = new List<Id> {
                test_data.TestOpportunity.Id
            };
            Test.startTest();
                SharingAccessChecker.getInstance().selectAllAccessesToRecords(records_id);
                Boolean actual_value = SharingAccessChecker.getInstance().doesUserHasAccessToRecord(test_data.TestOpportunity.Id, test_data.AdminUser.Id);
            Test.stopTest();
            System.assertEquals(true, actual_value, 'User should have access to record');
        }
    }

    public class SetupTestData {
        public User TestUser {get; set;}
        public User AdminUser {get;set;}
        public Opportunity TestOpportunity {get; set;}
        public OpportunityShare TestOpportunityShare {get; set;}
        public Account TestAccount {get; set;}

        public SetupTestData() {
            TestUser = UserTestData.getUserForTest().setProfile('System Administrator').setUsername('Somename@mail.com').save().getRecord();
            AdminUser = UserTestData.getUserForTest().setProfile('System Administrator').setUsername('Somename1@mail.com').save().getRecord();
        }

        public void createTestAccount() {
            TestAccount = new Account();
            TestAccount.Name = 'Test Name';
            insert TestAccount;
        }

        public void createTestOpportunity() {
            TestOpportunity = new Opportunity();
            TestOpportunity.Name = 'Some Name';
            TestOpportunity.Stagename = 'Prospecting';
            TestOpportunity.CloseDate = Date.today();
            TestOpportunity.AccountId = TestAccount.Id;
            TestOpportunity.OwnerId = TestUser.Id;
            insert TestOpportunity;
        }

        public void createReadAccessToTestOpportunity(Id user_group_id) {
            TestOpportunityShare = new OpportunityShare();
            TestOpportunityShare.OpportunityId = TestOpportunity.Id;
            TestOpportunityShare.UserOrGroupId = user_group_id;
            TestOpportunityShare.OpportunityAccessLevel = 'Edit';
            insert TestOpportunityShare;
        }

        public Group createTestGroup(String name) {
            Group some_group = new Group();
            some_group.Name = name;
            some_group.DeveloperName = name;
            some_group.Type = 'Regular';
            insert some_group;
            return some_group;
        }

        public void addUserToGroup(Id user_id, String dev_name) {
            Group selected_group = [SELECT id FROM Group WHERE DeveloperName =:dev_name LIMIT 1];
            GroupMember linker = new GroupMember();
            linker.GroupId =  selected_group.Id;
            linker.UserOrGroupId = user_id;
            insert linker;
        }
    }
}