@isTest
private class ChatterFeedFollowerTest {
    @isTest
    static void testCreateNewSubscriptionCorrectCreation() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity();
            Test.startTest();
                ChatterFeedFollower.getInstance().createNewSubscription(test_data.TestOpportunity.Id, test_data.TestUser.Id);
            Test.stopTest();
            System.assertEquals(1, ChatterFeedFollower.getInstance().SubscriptionsToInsert.size(), '1 subscription is created');
            EntitySubscription created_subscription = ChatterFeedFollower.getInstance().SubscriptionsToInsert.get(0);
            System.assertEquals(test_data.TestOpportunity.Id, created_subscription.ParentId, 'Incorrect ParentId');
            System.assertEquals(test_data.TestUser.Id, created_subscription.SubscriberId, 'Incorrect SubscriberId');
        }
    }

    @isTest
    static void testIsUserAlreadySubscribedNoHeIsNot() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity();
            ChatterFeedFollower.getInstance().selectAlreadyExistedSubscriptions(new List<Id>{test_data.TestOpportunity.Id}, new List<Id>{test_data.TestUser.Id});
            Test.startTest();
                Boolean actual_result = ChatterFeedFollower.getInstance().isUserAlreadySubscribed(test_data.TestOpportunity.Id, test_data.TestUser.Id);
            Test.stopTest();
            System.assertEquals(false, actual_result, 'User shouldn\'t be subscribed to Opportunity');
        }
    }

    @isTest
    static void testIsUserAlreadySubscribedYesHeIs() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity();
            EntitySubscription new_subscription = new EntitySubscription ();
            new_subscription.ParentId = test_data.TestOpportunity.Id;
            new_subscription.SubscriberId = test_data.TestUser.Id;
            insert new_subscription;
            ChatterFeedFollower.getInstance().selectAlreadyExistedSubscriptions(new List<Id>{test_data.TestOpportunity.Id}, new List<Id>{test_data.TestUser.Id});
            Test.startTest();
                Boolean actual_result = ChatterFeedFollower.getInstance().isUserAlreadySubscribed(test_data.TestOpportunity.Id, test_data.TestUser.Id);
            Test.stopTest();
            System.assertEquals(true, actual_result, 'User should be subscribed to Opportunity');
        }
    }

    @isTest
    static void testIsUserAlreadySubscribedSubscribedToAnotherRecord() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity();
            Account acct = new Account();
            acct.Name = 'just want to say HI from past, future next developer';
            insert acct;
            EntitySubscription new_subscription = new EntitySubscription ();
            new_subscription.ParentId = acct.Id;
            new_subscription.SubscriberId = test_data.TestUser.Id;
            insert new_subscription;
            ChatterFeedFollower.getInstance().selectAlreadyExistedSubscriptions(new List<Id>{test_data.TestOpportunity.Id}, new List<Id>{test_data.TestUser.Id});
            Test.startTest();
                Boolean actual_result = ChatterFeedFollower.getInstance().isUserAlreadySubscribed(test_data.TestOpportunity.Id, test_data.TestUser.Id);
            Test.stopTest();
            System.assertEquals(false, actual_result, 'User shouldn\'t be subscribed to Opportunity');
        }
    }

    @isTest
    static void testInsertNewlyCreatedSubscriptionsCorrectInsertion() {
        SetupTestData test_data = new SetupTestData();
        System.runAs(test_data.TestUser) {
            test_data.createTestOpportunity();
            ChatterFeedFollower.getInstance().selectAlreadyExistedSubscriptions(new List<Id>{test_data.TestOpportunity.Id}, new List<Id>{test_data.TestUser.Id});
            ChatterFeedFollower.getInstance().subscribeToRecord(test_data.TestOpportunity.Id, test_data.TestUser.Id);
            Test.startTest();
                ChatterFeedFollower.getInstance().insertNewlyCreatedSubscriptions();
            Test.stopTest();
            List<EntitySubscription> new_inserted_subscription = [SELECT Id, ParentId, SubscriberId FROM EntitySubscription LIMIT 999];
            System.assertEquals(1, new_inserted_subscription.size(), 'Only one subscription should exist');
            EntitySubscription created_subscription = new_inserted_subscription.get(0);
            System.assertEquals(test_data.TestOpportunity.Id, created_subscription.ParentId, 'Incorrect ParentId');
            System.assertEquals(test_data.TestUser.Id, created_subscription.SubscriberId, 'Incorrect SubscriberId');
        }
    }

    public class SetupTestData {
        public User TestUser {get; set;}
        public Opportunity TestOpportunity {get;set;}

        public SetupTestData() {
            TestUser = UserTestData.getUserForTest().setProfile('System Administrator').save().getRecord();
        }

        public void createTestOpportunity() {
            Account acct = new Account();
            acct.Name = 'Test Name';
            insert acct;
            TestOpportunity = new Opportunity();
            TestOpportunity.Name = 'Some name';
            TestOpportunity.AccountId = acct.Id;
            TestOpportunity.Stagename = 'Prospecting';
            TestOpportunity.CloseDate = Date.today();
            TestOpportunity.OwnerId = TestUser.Id;
            TestOpportunity.Amount = 10;
            insert TestOpportunity;
        }
    }
}