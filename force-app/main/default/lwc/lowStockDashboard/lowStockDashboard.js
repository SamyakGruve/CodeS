import { LightningElement, wire } from 'lwc';
import getLowStockProducts from '@salesforce/apex/LowStockProductController.getLowStockProducts';

export default class LowStockDashboard extends LightningElement {
    @wire(getLowStockProducts) products;
}