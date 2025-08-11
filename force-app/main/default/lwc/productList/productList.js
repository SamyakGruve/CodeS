import { api, wire, LightningElement, track } from 'lwc';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import addProductToOpportunity from '@salesforce/apex/OpportunityLineItemController.addProductToOpportunity'; // see Apex below

export default class ProductCards extends LightningElement {
    @api opportunityId;
    @track products;
    @track error;
    @track loading = false;
    renderedCallback() {
    if (this.recordId) {
        console.log('Record Id from renderedCallback:', this.recordId);
    }
}

    @wire(getProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data.map(prod => ({
                ...prod,
                activeLabel: prod.IsActive ? 'Yes' : 'No'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.products = undefined;
        }
    }

    handleAddToOpportunity(event) {
        const productId = event.target.dataset.id;
 
        if (!this.recordId) {
            this.showToast('Error', 'Opportunity ID is not available.', 'error');
            return;
        }
 
        addProductToOpportunity({ opportunityId: this.recordId, productId: productId })
            .then(() => {
                this.showToast('Success', 'Product added to Opportunity.', 'success');
            })
            .catch((error) => {
                this.showToast('Error adding product', error.body.message, 'error');
            });
    }
    renderedCallback() {
    if (this.recordId) {
        console.log('Record Id from renderedCallback:', this.recordId);
    }
}
 
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}