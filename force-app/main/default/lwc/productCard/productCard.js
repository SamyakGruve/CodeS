import { LightningElement, api, wire } from 'lwc';
import getAvailableProducts from '@salesforce/apex/ProductController.getAvailableProducts';
import addProductToOpportunity from '@salesforce/apex/ProductController.addProductToOpportunity';

export default class ProductCard extends LightningElement {
    @api recordId; // This is the Opportunity ID passed from the page
    products;
    error;

    @wire(getAvailableProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data;
            this.error = undefined;
        } else if (error) {
            this.error = 'Error fetching products.';
            console.error(error);
        }
    }

    async handleAddToOpportunity(event) {
        const productId = event.target.dataset.id;

        try {
            await addProductToOpportunity({ opportunityId: this.recordId, productId });
            alert('Product added to Opportunity!');
        } catch (err) {
            this.error = 'Failed to add product.'+ err;
            alert(err.msg)
            console.error(err);
        }
    }
}