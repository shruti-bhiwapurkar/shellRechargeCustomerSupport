import { api, LightningElement, track } from 'lwc';
import getAgentsList from '@salesforce/apex/OmniSupervisorController.getAgentsList';
import getPerAgentSummary from '@salesforce/apex/OmniSupervisorController.getPerAgentSummary';

export default class PerAgentSummary extends LightningElement {

    @api
    get selectedAgent() {
        return this._selectedAgent;
    }
    set selectedAgent(value) {
        this._selectedAgent = value;
        if(value != undefined && value != null) {
            this.selectedAgentId = this.selectedAgent.agentId;
            this.getSelectedAgentSummary();
        }
    }

    selectedAgentId;
    agentList = [];
    error;
    @track agentSummary;
    isSummaryAvailable = false;
    isLoading = false;

    connectedCallback() {  
        getAgentsList().then(result => {
            this.agentList = result;
        })
        .catch(error => {
            this.error = error;
        });
    }

    onAgentChange(event) {
        this.selectedAgentId = event.detail.value;

        //get summary for selected agent
        this.getSelectedAgentSummary();
    }

    getSelectedAgentSummary() {
        this.isLoading = true;
       
        getPerAgentSummary({ userId: this.selectedAgentId })
            .then(result => {
                this.agentSummary = result;
                this.isSummaryAvailable = true;
                this.isLoading = false;

                if(this.agentSummary.status == 'Active') {
                    this.agentSummary['isActive'] = true;
                } else {
                    this.agentSummary['isActive'] = false;
                }
            })
            .catch(error => {
                this.error = error;
            });
    }
}