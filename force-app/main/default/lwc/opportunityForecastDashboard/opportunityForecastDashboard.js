import { LightningElement, track } from 'lwc';
import getOpportunitiesByQuarter from '@salesforce/apex/SalesForecastTrackerController.getOpportunitiesByQuarter';
 
export default class SalesForecastTracker extends LightningElement {
    @track selectedQuarter = 'Q1';
    @track stageRows = [];
    @track summary = {};
    rawOpportunities = [];
 
    columns = [
        { label: 'Stage Group', fieldName: 'stage', type: 'text' },
        { label: 'Opportunity Count', fieldName: 'count', type: 'number' },
        { label: 'Expected Revenue', fieldName: 'revenue', type: 'currency' }
    ];
 
    get quarterOptions() {
        return [
            { label: 'Q1', value: 'Q1' },
            { label: 'Q2', value: 'Q2' },
            { label: 'Q3', value: 'Q3' },
            { label: 'Q4', value: 'Q4' },
            { label: 'This Year', value: 'This Year' }
        ];
    }
 
    connectedCallback() {
        this.loadData();
    }
 
    handleQuarterChange(event) {
        this.selectedQuarter = event.detail.value;
        this.loadData();
    }
 
    loadData() {
        getOpportunitiesByQuarter({ quarter: this.selectedQuarter })
            .then(data => {
                this.rawOpportunities = data;
                this.processData();
            })
            .catch(error => {
                console.error('Error fetching opportunities', error);
            });
    }
 
    processData() {
        // Define grouping
        const stageGroups = {
            'Prospecting': 'Pipeline',
            'Qualification': 'Pipeline',
            'Needs Analysis': 'Best Case',
            'Value Proposition': 'Best Case',
            'Id. Decision Makers': 'Commit',
            'Negotiation/Review': 'Commit',
            'Closed Won': 'Closed Won'
        };
 
        // Initialize stage data
        const groupedData = {
            'Pipeline': { count: 0, revenue: 0 },
            'Best Case': { count: 0, revenue: 0 },
            'Commit': { count: 0, revenue: 0 },
            'Closed Won': { count: 0, revenue: 0 }
        };
 
        let totalForecast = 0;
        let closedWonRevenue = 0;
 
        this.rawOpportunities.forEach(opp => {
            const groupName = stageGroups[opp.StageName] || 'Pipeline';
            groupedData[groupName].count += 1;
            groupedData[groupName].revenue += opp.ExpectedRevenue || 0;
 
            totalForecast += opp.ExpectedRevenue || 0;
            if (groupName === 'Closed Won') {
                closedWonRevenue += opp.ExpectedRevenue || 0;
            }
        });
 
        // Convert to table rows
        this.stageRows = Object.keys(groupedData).map(stage => ({
            stage,
            count: groupedData[stage].count,
            revenue: groupedData[stage].revenue
        }));
 
        // Summary
        const accuracy = totalForecast > 0 ? (closedWonRevenue / totalForecast) * 100 : 0;
        this.summary = {
            totalForecast,
            closedWonRevenue,
            accuracy: accuracy.toFixed(2)
        };
    }
}