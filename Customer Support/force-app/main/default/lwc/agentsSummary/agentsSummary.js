import { LightningElement } from 'lwc';

export default class AgentsSummary extends LightningElement {

    selectedAgent;

    onAgentSelect(event) {
        let selectedAgent = event.detail;
        this.selectedAgent = selectedAgent;

        let tabsetElement = this.template.querySelector('lightning-tabset');
        tabsetElement.activeTabValue = 'Per Agent Summary';
    }
}