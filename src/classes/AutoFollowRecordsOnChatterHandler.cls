public with sharing class AutoFollowRecordsOnChatterHandler {
    @InvocableMethod
    public static void followUp(List<Id> sobject_ids) {
        AutoFollowRecordsOnChatter.getInstance().subscribeUsersToRecords(sobject_ids);
    }
}