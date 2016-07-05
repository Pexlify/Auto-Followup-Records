@isTest
private class AutoFollowRecordsOnChatterTest {

    @isTest
    static void testDoesCriteriaIsMetOperatorMetString() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.updateLastNameUser('Alex');
            test_data.createTestOpportunity('Alex-1');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            Test.startTest();
                Boolean actual_result = AutoFollowRecordsOnChatter.getInstance().doesCriteriaIsMetString(test_data.TestSetting, test_data.TestUser, test_data.TestOpportunity);
            Test.stopTest();
            System.assertEquals(true, actual_result, 'Criteria is met');
        }
    }

    @isTest
    static void testDoesCriteriaIsMetOperatorNullValueString() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity('Alex-1');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            Test.startTest();
                Boolean actual_result = AutoFollowRecordsOnChatter.getInstance().doesCriteriaIsMetString(test_data.TestSetting, test_data.TestUser, test_data.TestOpportunity);
            Test.stopTest();
            System.assertEquals(false, actual_result, 'Criteria isn\'t met');
        }
    }

    @isTest
    static void testDoesCriteriaIsMetOperatorIsntMetString() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.updateLastNameUser('SomeName');
            test_data.createTestOpportunity('Alex');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            Test.startTest();
                Boolean actual_result = AutoFollowRecordsOnChatter.getInstance().doesCriteriaIsMetString(test_data.TestSetting, test_data.TestUser, test_data.TestOpportunity);
            Test.stopTest();
            System.assertEquals(false, actual_result, 'Criteria isn\'t met');
        }
    }

    @isTest
    static void testDoesCriteriaIsMetOperatorMet() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            AutoFollowRecordsOnChatter.getInstance().SobjectTypeString = 'Opportunity';
            test_data.updateLastNameUser('Alex');
            test_data.createTestOpportunity('Alex-1');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            Test.startTest();
                Boolean actual_result = AutoFollowRecordsOnChatter.getInstance().doesCriteriaIsMet(test_data.TestSetting, test_data.TestUser, test_data.TestOpportunity, Opportunity.SObjectType);
            Test.stopTest();
            System.assertEquals(true, actual_result, 'Criteria is met');
        }
    }

    @isTest
    static void testDoesCriteriaIsMetOperatorIsntMet() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            AutoFollowRecordsOnChatter.getInstance().SobjectTypeString = 'Opportunity';
            test_data.updateLastNameUser('Alex');
            test_data.createTestOpportunity('AAAlex');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            Test.startTest();
                Boolean actual_result = AutoFollowRecordsOnChatter.getInstance().doesCriteriaIsMet(test_data.TestSetting, test_data.TestUser, test_data.TestOpportunity, Opportunity.SObjectType);
            Test.stopTest();
            System.assertEquals(false, actual_result, 'Criteria isn\'t met');
        }
    }

    @isTest
    static void testGetWhoToWhatWantsToSubsribeBasedOnSettingCorrectPopulating() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            AutoFollowRecordsOnChatter.getInstance().SobjectTypeString = 'Opportunity';
            test_data.updateLastNameUser('Alex');
            test_data.createTestOpportunity('Alex-1');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            List<User> list_users = new List<User> {
                test_data.TestUser
            };
            List<sObject> list_sobjects = new List<sObject> {
                test_data.TestOpportunity
            };
            Test.startTest();
                Map<Id, Set<Id>> actual_map = AutoFollowRecordsOnChatter.getInstance().getWhoToWhatWantsToSubsribeBasedOnSetting(test_data.TestSetting, list_users, list_sobjects);
            Test.stopTest();
            System.assertEquals(1, actual_map.keySet().size(), 'Only for one user desired records should be defined');
            System.assertEquals(true, actual_map.keySet().contains(test_data.TestUser.Id), 'Incorrect User Id');
            System.assertEquals(1, actual_map.get(test_data.TestUser.Id).size(), 'Only one desired record');
            System.assertEquals(true, actual_map.get(test_data.TestUser.Id).contains(test_data.TestOpportunity.Id), 'Incorrect desired Sobject');
        }
    }

    @isTest
    static void testGetWhoToWhatWantsToSubsribeBasedOnSettingCorrectPopulatingCriterisIsntMet() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            AutoFollowRecordsOnChatter.getInstance().SobjectTypeString = 'Opportunity';
            test_data.updateLastNameUser('Alex');
            test_data.createTestOpportunity('Kolya');
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            List<User> list_users = new List<User> {
                test_data.TestUser
            };
            List<sObject> list_sobjects = new List<sObject> {
                test_data.TestOpportunity
            };
            Test.startTest();
                Map<Id, Set<Id>> actual_map = AutoFollowRecordsOnChatter.getInstance().getWhoToWhatWantsToSubsribeBasedOnSetting(test_data.TestSetting, list_users, list_sobjects);
            Test.stopTest();
            System.assertEquals(0, actual_map.keySet().size(), 'No users desired records should be defined');
            System.assertEquals(false, actual_map.keySet().contains(test_data.TestUser.Id), 'User should be absent');
        }
    }

    @isTest
    static void testGenerateAllUsersQueryCorrectQueryIsCreated() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            Test.startTest();
                String actual_query = AutoFollowRecordsOnChatter.getInstance().generateAllUsersQuery(test_data.TestSetting);
            Test.stopTest();
            String expected_query = 'SELECT Id, LastName FROM User WHERE LastName != null AND isActive = true';
            System.assertEquals(expected_query, actual_query, 'Incorrect query is generated');
        }
    }

    @isTest
    static void testCorrectSelection() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            AutoFollowRecordsOnChatter.getInstance().SobjectTypeString = 'Opportunity';
            test_data.createTestOpportunity('Alex-1');
            List<String> fields = new List<String> {
                'Amount',
                'StageName'
            };
            List<Id> object_ids = new List<Id> {
                test_data.TestOpportunity.Id
            };
            Test.startTest();
                List<Opportunity> actual_sobjects = AutoFollowRecordsOnChatter.getInstance().selectContextObjects(object_ids, fields);
            Test.stopTest();
            for(Opportunity temp_opp :actual_sobjects) {
                try {
                    Object field1 = temp_opp.Amount;
                    Object field2 = temp_opp.StageName;
                } catch (Exception ex) {
                    System.assert(false, 'Fields Amount and StageName should be quiried');
                }
            }
        }
    }

    @isTest
    static void testExtractNeededObjectsFieldsFromSettingsCorrectExtraction() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.TestSetting = test_data.selectCusomMetadata('Opportunity_Follow_Up');
            List<Auto_Follow_Up__mdt> list_settings = new List<Auto_Follow_Up__mdt> {
                test_data.TestSetting
            };
            Test.startTest();
                List<String> actual_fields = AutoFollowRecordsOnChatter.getInstance().extractNeededObjectsFieldsFromSettings(list_settings);
            Test.stopTest();
            System.assertEquals(1, actual_fields.size(), 'Only one field should be in list');
            System.assertEquals('Name', actual_fields.get(0), 'Incorrect field is extracted from Settings');
        }
    }

    @isTest
    static void testDefineSobjectTypeStringValueCorrectDefinition() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity('Some name');
            List<Id> object_ids = new List<Id> {
                test_data.TestOpportunity.Id
            };
            Test.startTest();
                AutoFollowRecordsOnChatter.getInstance().defineSobjectTypeStringValue(object_ids);
            Test.stopTest();
            System.assertEquals('Opportunity', AutoFollowRecordsOnChatter.getInstance().SobjectTypeString, 'Incorrect name of object was defined');
        }
    }

    @isTest
    static void testGetCustomMetadataSettingsCorrectSelection() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity('Alex-1');
            List<Id> object_ids = new List<Id> {
                test_data.TestOpportunity.Id
            };
            Test.startTest();
                List<Auto_Follow_Up__mdt> actual_settings = AutoFollowRecordsOnChatter.getInstance().getCustomMetadataSettings(object_ids);
            Test.stopTest();
            System.assertEquals(1, actual_settings.size(), 'Incorrect number of settings related to Opportunity');
            for(Auto_Follow_Up__mdt setting: actual_settings) {
                System.assertEquals(true, setting.Criteria_Field__c =='LastName' , 'Incorrect user criteria field');
                System.assertEquals(true, setting.Is_User_Field__c , 'Incorrect user criteria field');
                System.assertEquals('starts with', setting.Operator__c , 'Incorrect Operator field');
                System.assertEquals('Opportunity', setting.SObject__c , 'Incorrect sObject field');
                System.assertEquals('Name', setting.SObject_Field__c , 'Incorrect field on Opportunity');
            }
        }
    }

    public class SetupTestData {
        public User TestUser {get; set;}
        public Auto_Follow_Up__mdt TestSetting {get;set;}
        public Opportunity TestOpportunity {get; set;}

        public SetupTestData() {
            TestUser = UserTestData.getUserForTest().setProfile('System Administrator').save().getRecord();
            TestUser.FirstName = null;
            update TestUser;
        }

        public Auto_Follow_Up__mdt selectCusomMetadata(String api_name) {
            return [SELECT Criteria_Field__c, Is_User_Field__c, Operator__c, SObject__c, SObject_Field__c, Record_Type__c
                        FROM Auto_Follow_Up__mdt WHERE DeveloperName =:api_name LIMIT 1];
        }


        public void updateLastNameUser(String value) {
            TestUser.LastName = value;
            update TestUser;
        }

        public void createTestOpportunity(String name) {
            Account acct = new Account();
            acct.Name = 'Test Name';
            insert acct;
            TestOpportunity = new Opportunity();
            TestOpportunity.Name = name;
            TestOpportunity.Stagename = 'Prospecting';
            TestOpportunity.CloseDate = Date.today();
            TestOpportunity.AccountId = acct.Id;
            TestOpportunity.OwnerId = TestUser.Id;
            TestOpportunity.Amount = 10;
            insert TestOpportunity;
        }

        public List<Opportunity> createListOfOpportunity(Integer num, String name) {
            List<Opportunity> result = new List<Opportunity>();
            Account acct = new Account();
            acct.Name = 'Test Name Bulk';
            insert acct;
            for(Integer i=0; i< num; i++) {
                Opportunity temp_opp = new Opportunity();
                temp_opp.Name = name+i;
                temp_opp.Stagename = 'Prospecting';
                temp_opp.CloseDate = Date.today();
                temp_opp.AccountId = acct.Id;
                temp_opp.OwnerId = TestUser.Id;
                temp_opp.Amount = 10;
                result.add(temp_opp);
            }
            insert result;
            return result;
        }
    }
}