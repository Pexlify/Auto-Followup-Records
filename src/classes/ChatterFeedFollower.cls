public without sharing class ChatterFeedFollower {
    private static ChatterFeedFollower Instance;
    private Map<Id,Set<Id>> ListRecordIdsBySubscribedUsersIdsMap = new Map<Id,Set<Id>>();
    @TestVisible
    private List<EntitySubscription> SubscriptionsToInsert = new List<EntitySubscription>();

    private ChatterFeedFollower() {

    }
    public static ChatterFeedFollower getInstance() {
        if(Instance == null) {
            Instance = new ChatterFeedFollower();
        }
        return Instance;
    }

    public void selectAlreadyExistedSubscriptions(List<Id> record_id_list, List<Id> user_id_list){
        List<EntitySubscription> subscriptions = [SELECT ParentId, SubscriberId FROM EntitySubscription WHERE ParentId IN:record_id_list AND SubscriberId IN:user_id_list LIMIT 999];
        for(EntitySubscription subscription:subscriptions) {
            Set<Id> record_ids = new Set<Id>();
            if(!ListRecordIdsBySubscribedUsersIdsMap.containsKey(subscription.SubscriberId)) {
                record_ids.add(subscription.ParentId);
            } else {
                record_ids = ListRecordIdsBySubscribedUsersIdsMap.get(subscription.SubscriberId);
                record_ids.add(subscription.ParentId);
            }
            ListRecordIdsBySubscribedUsersIdsMap.put(subscription.SubscriberId, record_ids);
        }
    }

    public void subscribeToRecord(Id record_id, Id user_id){
        if(!isUserAlreadySubscribed(record_id, user_id)) {
            createNewSubscription(record_id, user_id);
        }
    }

    @TestVisible
    private Boolean isUserAlreadySubscribed(Id record_id, Id user_id) {
        if(!ListRecordIdsBySubscribedUsersIdsMap.containsKey(user_id)) {
            return false;
        } else {
            Set<Id> record_ids = ListRecordIdsBySubscribedUsersIdsMap.get(user_id);
            return (record_ids.contains(record_id)) ? true: false;
        }
    }

    @TestVisible
    private void createNewSubscription(Id record_id, Id user_id) {
        EntitySubscription new_subscription = new EntitySubscription ();
        new_subscription.ParentId = record_id;
        new_subscription.SubscriberId = user_id;
        SubscriptionsToInsert.add(new_subscription);
    }

    public void insertNewlyCreatedSubscriptions() {
        if(!SubscriptionsToInsert.isEmpty()) {
            insert SubscriptionsToInsert;
            SubscriptionsToInsert.clear();
        }
    }
}