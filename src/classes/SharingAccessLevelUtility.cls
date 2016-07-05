public with sharing class SharingAccessLevelUtility {
    public enum AccessLevel {
        NONE,
        READ,
        EDIT,
        ALL
    }

    private final Map<AccessLevel, String> AccessLevelNameMap = new Map<AccessLevel, String>{
            AccessLevel.NONE => 'None',
            AccessLevel.READ => 'Read',
            AccessLevel.EDIT => 'Edit',
            AccessLevel.ALL => 'All'
    };

    private static SharingAccessLevelUtility Instance;

    private SharingAccessLevelUtility() {
    }

    public static SharingAccessLevelUtility getInstance() {
        if(Instance == null) {
            Instance = new SharingAccessLevelUtility();
        }
        return Instance;
    }

    public String getAccessLevelName(AccessLevel access_level) {
        return AccessLevelNameMap.get(access_level);
    }

    public AccessLevel getAccessLevel(String access_level_name) {
        Map<String, AccessLevel> reverted_map = new Map<String, AccessLevel>();
        for(AccessLevel key:AccessLevelNameMap.keySet()) {
            reverted_map.put(AccessLevelNameMap.get(key), key);
        }

        return reverted_map.get(access_level_name);
    }
}