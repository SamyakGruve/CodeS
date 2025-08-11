public with sharing class SalesForecastTrackerController {
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesByQuarter(String quarter) {
        Date startDate;
        Date endDate;
        Integer currentYear = System.today().year();
 
        if (quarter == 'Q1') {
            startDate = Date.newInstance(currentYear, 1, 1);
            endDate = Date.newInstance(currentYear, 3, 31);
        } else if (quarter == 'Q2') {
            startDate = Date.newInstance(currentYear, 4, 1);
            endDate = Date.newInstance(currentYear, 6, 30);
        } else if (quarter == 'Q3') {
            startDate = Date.newInstance(currentYear, 7, 1);
            endDate = Date.newInstance(currentYear, 9, 30);
        } else if (quarter == 'Q4') {
            startDate = Date.newInstance(currentYear, 10, 1);
            endDate = Date.newInstance(currentYear, 12, 31);
        } else if (quarter == 'This Year') {
            startDate = Date.newInstance(currentYear, 1, 1);
            endDate = Date.newInstance(currentYear, 12, 31);
        }
 
        return [
            SELECT Id, Name, StageName, ExpectedRevenue, CloseDate
            FROM Opportunity
            WHERE CloseDate >= :startDate AND CloseDate <= :endDate
        ];
    }
}