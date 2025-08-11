/* ---------------------------------------------------------
   SalesForecastTracker.js
   ---------------------------------------------------------
   Description  : LWC that shows forecast by stage group,
                  includes a summary block and a “Total” row.
   Author       : <your-name>
   Created      : <date>
--------------------------------------------------------- */

import { LightningElement, track } from 'lwc';
import getOpportunitiesByQuarter
    from '@salesforce/apex/SalesForecastTrackerController.getOpportunitiesByQuarter';

export default class SalesForecastTracker extends LightningElement {
    /* ----- reactive properties ----- */
    @track selectedQuarter = 'Q1';
    @track stageRows = [];      // rows fed to lightning-datatable
    @track summary   = {};      // totalForecast, closedWonRevenue, accuracy%

    /* ----- non-reactive ----- */
    rawOpportunities = [];      // ungrouped Apex result

    columns = [
        { label: 'Stage Group',       fieldName: 'stage',   type: 'text'     },
        { label: 'Opportunity Count', fieldName: 'count',   type: 'number'  },
        { label: 'Expected Revenue',  fieldName: 'revenue', type: 'currency'}
    ];

    /* ----- quarter <lightning-combobox> options ----- */
    get quarterOptions() {
        return [
            { label: 'Q1',         value: 'Q1' },
            { label: 'Q2',         value: 'Q2' },
            { label: 'Q3',         value: 'Q3' },
            { label: 'Q4',         value: 'Q4' },
            { label: 'This Year',  value: 'This Year' }
        ];
    }

    /* ----- lifecycle ----- */
    connectedCallback() {
        this.loadData();
    }

    /* ----- event handlers ----- */
    handleQuarterChange(event) {
        this.selectedQuarter = event.detail.value;
        this.loadData();
    }

    /* ----- data fetch ----- */
    loadData() {
        getOpportunitiesByQuarter({ quarter: this.selectedQuarter })
            .then(data => {
                // ensure we’re always working with an array
                this.rawOpportunities = Array.isArray(data) ? data : [];
                this.processData();
            })
            .catch(error => {
                // eslint-disable-next-line no-console
                console.error('Error fetching opportunities', error);
                // reset UI on error
                this.stageRows = [];
                this.summary   = {};
            });
    }

    /* ----- core logic ----- */
    processData() {
        /* 1. Map individual stages to high-level groups */
        const stageGroups = {
            Prospecting:        'Pipeline',
            Qualification:      'Pipeline',
            'Needs Analysis':   'Best Case',
            'Value Proposition':'Best Case',
            'Id. Decision Makers':'Commit',
            'Negotiation/Review':'Commit',
            'Closed Won':       'Closed Won'
        };

        /* 2. Prepare containers */
        const groupedData = {
            Pipeline:   { count:0, revenue:0 },
            'Best Case':{ count:0, revenue:0 },
            Commit:     { count:0, revenue:0 },
            'Closed Won':{count:0, revenue:0}
        };

        let totalForecast   = 0;
        let closedWonRevenue= 0;

        /* 3. Aggregate */
        this.rawOpportunities.forEach(opp => {
            const groupName = stageGroups[opp.StageName] || 'Pipeline';
            const expected  = opp.ExpectedRevenue || 0;

            groupedData[groupName].count   += 1;
            groupedData[groupName].revenue += expected;

            totalForecast += expected;
            if (groupName === 'Closed Won') {
                closedWonRevenue += expected;
            }
        });

        /* 4. Build rows for datatable */
        const baseRows = Object.keys(groupedData).map(stage => ({
            stage,
            count:   groupedData[stage].count,
            revenue: groupedData[stage].revenue,
            rowClass: ''                 // placeholder; useful for styling
        }));

        /* 5. Append “Total” row */
        const totalRow = baseRows.reduce(
            (tot, row) => {
                tot.count   += row.count;
                tot.revenue += row.revenue;
                return tot;
            },
            { stage:'Total', count:0, revenue:0, rowClass:'total-row' }
        );

        this.stageRows = [...baseRows, totalRow];

        /* 6. Summary figures */
        const accuracy = totalForecast > 0
            ? (closedWonRevenue / totalForecast) * 100
            : 0;

        this.summary = {
            totalForecast,
            closedWonRevenue,
            accuracy: accuracy.toFixed(2)
        };
    }
}
