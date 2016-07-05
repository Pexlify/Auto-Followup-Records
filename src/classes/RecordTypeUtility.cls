public  class RecordTypeUtility {
    private static RecordTypeUtility Instance;
    private Map<String,String> MapRecordTypes;
    private Map<String,String> MapRecordTypesReverse;

    private RecordTypeUtility() {
        populateMapRecordTypes();
    }

    public static RecordTypeUtility getInstance() {
        if(Instance == null) {
            Instance =  new RecordTypeUtility();
        }
        return Instance;
    }

    private void populateMapRecordTypes() {
        if (MapRecordTypes==null){
            List<RecordType> rt_list=[SELECT Id,Name,DeveloperName,SObjectType FROM RecordType];
            MapRecordTypes = new Map<String,String>();
            for (RecordType rt : rt_list){
                String key = rt.SObjectType + '.' + rt.DeveloperName;
                Id recordtype_id = rt.Id;
                MapRecordTypes.put(key, recordtype_id);
            }
        }
        MapRecordTypesReverse = reverseTwoStringMap(MapRecordTypes);
    }

    public String getKeyById(Id RecordTypeId){
        if (MapRecordTypesReverse.get(RecordTypeId) != null)
           return MapRecordTypesReverse.get(RecordTypeId);
        return null;
    }

    private Map<String,String> reverseTwoStringMap(Map<String,String> map_reverse){
        Map<String,String> result = new Map<String,String>();
        for(String key : map_reverse.keySet()) {
            result.put(map_reverse.get(key), key);
        }
        return result;
    }
}