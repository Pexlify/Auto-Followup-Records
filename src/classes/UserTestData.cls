@isTest
public class UserTestData {
    public static Builder getUserForTest(){
        return new Builder();
    }

    public static ListBuilder getListBuilder(Integer amount){
        return new ListBuilder(amount);
    }

    public class Builder{
        private User Record;

        private Builder(){
            Record = new User();
            Record.Username = 'testuser@pexlify.com';
            Record.Email = Record.Username;
            Record.Alias = 'test';
            Record.LastName = 'TestMan';
            Record.IsActive = true;
            Record.EmailEncodingKey = 'UTF-8';
            Record.TimeZoneSidKey = 'Europe/London';
            Record.LanguageLocaleKey = 'en_US';
            Record.LocaleSidKey = 'en_IE_EURO';
        }

        public Builder setIsActive(Boolean is_user_active) {
            Record.IsActive = is_user_active;
            return this;
        }

        public Builder setUsername(String username) {
            Record.Username = username;
            return this;
        }

        public Builder save(){
            insert Record;
            return this;
        }

        public Builder setProfile(String profile_name){
            String profile_id = [SELECT id FROM  Profile WHERE Name =:profile_name LIMIT 1].id;
            Record.ProfileId = profile_id;
            return this;
        }

        public User getRecord(){
            return Record;
        }
    }

    public class ListBuilder{
        private Integer NumberOfRecords;
        private List<User> Users;
        private Id UserRoleId;

        private ListBuilder(Integer number_of_records){
            NumberOfRecords = number_of_records;
            Users = new List<User>();
            for (Integer i = 0; i < NumberOfRecords; ++i) {
                User usr = new User();
                usr.Username = i+'testuser@pexlify.com';
                usr.Email = usr.Username;
                usr.UserRoleId = getUserRoleId();
                usr.Alias = 'test';
                usr.LastName = 'TestMan'+i;
                usr.CommunityNickname = i+'test';
                usr.IsActive = true;
                usr.EmailEncodingKey = 'UTF-8';
                usr.TimeZoneSidKey = 'Europe/London';
                usr.LanguageLocaleKey = 'en_US';
                usr.LocaleSidKey = 'en_IE_EURO';
                Users.add(usr);
            }
        }

        private Id getUserRoleId(){
            if(UserRoleId == null) {
                UserRoleId = [SELECT Id FROM UserRole LIMIT 1].Id;
            }
            return UserRoleId;
        }

        public ListBuilder setProfile(String profile_name){
            String profile_id = [SELECT id FROM Profile WHERE Name =:profile_name LIMIT 1].id;
            for(User usr:Users) {
                usr.ProfileId = profile_id;
            }
            return this;
        }

        public ListBuilder save(){
            insert Users;
            return this;
        }

        public List<User> getRecords(){
            return Users;
        }
    }
}