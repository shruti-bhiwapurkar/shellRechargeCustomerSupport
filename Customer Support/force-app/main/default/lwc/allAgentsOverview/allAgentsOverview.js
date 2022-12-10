import { LightningElement, track, wire } from 'lwc';
import getAllAgentsSummary from '@salesforce/apex/OmniSupervisorController.getAllAgentsSummary';

export default class AllAgentsOverview extends LightningElement {

    @track allAgentsOverviewList = [];
  
    timeSpan = 5000;
    evt;

    connectedCallback() {
        this.getAllAgentsOverview();
        this.getUpdatedStatus();
    }

    disconnectedCallback() {
        clearInterval(this.evt);
    }

    getAllAgentsOverview() {
        getAllAgentsSummary().then(result => {
            this.allAgentsOverviewList = result;

            for(let counter = 0; counter < this.allAgentsOverviewList.length; counter++) {
                if(this.allAgentsOverviewList[counter].status == 'Active') {
                    this.allAgentsOverviewList[counter]['isActive'] = true;
                } else {
                    this.allAgentsOverviewList[counter]['isActive'] = false;
                }
            }
        })
        .catch(error => {
            this.error = error;
        });
    }

    getUpdatedStatus() {
        this.evt = setInterval(() => {
            this.getAllAgentsOverview();
          }, this.timeSpan);
    }
    
    handleAgentSelect(event) {
        let agentId = event.target.dataset.agentrow;
        let agentDetials;
        
        for(let counter = 0; counter < this.allAgentsOverviewList.length; counter++) {
            if(agentId == this.allAgentsOverviewList[counter].agentId) {
                agentDetials = this.allAgentsOverviewList[counter];
                break;
            }
        }
        const selectEvent = new CustomEvent('agentselect', {
            detail: agentDetials
        });
        // Fire the custom event
        this.dispatchEvent(selectEvent);
    }

}