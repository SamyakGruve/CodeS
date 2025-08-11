public with sharing class AccountController {
    public static List sendAccounts() {
        return [Select Id, Name FROM Account LIMIT 10];
    }
}