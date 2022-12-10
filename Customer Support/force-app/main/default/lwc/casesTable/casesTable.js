import { api, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class OpenCasesTable extends NavigationMixin(LightningElement) {
    @api caseList = [];

    handleCaseOpen(event) {
        let caseId = event.target.dataset.caseId;
        
        this[ NavigationMixin.GenerateUrl ]( {
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                actionName: 'view',
                objectApiName: 'Case',
            },
        }).then(url => { window.open(url) });
    }

    generateCaseListPdf() {
        window.print();
    }
}