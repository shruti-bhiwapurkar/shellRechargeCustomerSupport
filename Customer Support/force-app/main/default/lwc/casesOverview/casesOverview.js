import { LightningElement, wire } from 'lwc';
import getCaseOwners from '@salesforce/apex/OmniSupervisorController.getCaseOwners';
import searchCasesBasedOnFilter from '@salesforce/apex/OmniSupervisorController.searchCasesBasedOnFilter';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import CASE_PRIORITY from '@salesforce/schema/Case.Priority';
import CASE_REASON from '@salesforce/schema/Case.Reason';
import CASE_TYPE from '@salesforce/schema/Case.Type';

export default class CasesOverview extends LightningElement {

    selectedCaseOwnerId;
    selectedStatus;
    selectedPriority;
    selectedReason;
    selectedType;
    createdDate;
    closedDate;
    caseOwnerValues;
    statusPicklistValues;
    priorityPicklistValues;
    reasonPicklistValues;
    typePicklistValues;
    createdDateValues;
    closedDateValues;
    error;
    isLoading = false;
    casesList;
    showCaseResults = false;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    @wire(getPicklistValuesByRecordType, { recordTypeId:  "$caseObjectInfo.data.defaultRecordTypeId", objectApiName: CASE_OBJECT })
    picklistHandler({ data, error }) {
        if(data) {
            this.statusPicklistValues = this.picklistGenerator(data, CASE_STATUS.fieldApiName);
            this.priorityPicklistValues = this.picklistGenerator(data, CASE_PRIORITY.fieldApiName);
            this.reasonPicklistValues = this.picklistGenerator(data, CASE_REASON.fieldApiName);
            this.typePicklistValues = this.picklistGenerator(data, CASE_TYPE.fieldApiName);
        } else if(error) {
            console.log(error);
            this.error = error;
        }
    }  

    connectedCallback() {
        this.populateDateFilters();

        getCaseOwners().then(result => {
            this.caseOwnerValues = result;
        })
        .catch(error => {
            this.error = error;
        });

        //get all cases
        this.handleSearch()
    }

    populateDateFilters() {
        let picklistOptions = [];
        picklistOptions.push({label: 'Choose Value', value: undefined});
        picklistOptions.push({label: 'Today', value: 'TODAY'});
        picklistOptions.push({label: 'Yesterday', value: 'YESTERDAY'});
        picklistOptions.push({label: 'This Week', value: 'THIS_WEEK'});
        picklistOptions.push({label: 'Last Week', value: 'LAST_WEEK'});
        picklistOptions.push({label: 'This Month', value: 'LAST_MONTH'});
        picklistOptions.push({label: 'Last Month', value: 'THIS_MONTH'});

        this.createdDateValues = picklistOptions;
        this.closedDateValues = picklistOptions;
    }

    picklistGenerator(data, fieldName) {
        let picklistOptions = [];
        picklistOptions.push({label: 'Choose Value', value: undefined});

        let pickListValues = data.picklistFieldValues[fieldName].values;
        for (let item of pickListValues) {
            picklistOptions.push({label: item.label, value: item.value});
        }

        return picklistOptions;
    }

    handlePicklistValueChange(event) {
        const {name, value} = event.target;
        if(name === 'status') {
            this.selectedStatus = value;
        }
        if(name === 'priority') {
            this.selectedPriority = value;
        }
        if(name === 'reason') {
            this.selectedReason = value;
        }
        if(name === 'type') {
            this.selectedType = value;
        }
        if(name === 'owner') {
            this.selectedCaseOwnerId = value;
        }
        if(name === 'createdDate') {
            this.createdDate = value;
        }
        if(name === 'closedDate') {
            this.closedDate = value;
        }
    }

    handleSearch() {
        let filter;
        if(this.selectedStatus != null && this.selectedStatus != undefined) {
            filter = ' Status = \'' + this.selectedStatus + '\'';
        }
        if(this.selectedPriority != null && this.selectedPriority != undefined) {
            let tempFilter = ' Priority = \'' + this.selectedPriority + '\'';
            filter = (filter == null) ? tempFilter : filter + ' AND ' + tempFilter;
        }
        if(this.selectedReason != null && this.selectedReason != undefined) {
            let tempFilter = ' Reason = \'' + this.selectedReason + '\'';
            filter = (filter == null) ? tempFilter : filter + ' AND ' + tempFilter;
        }
        if(this.selectedType != null && this.selectedType != undefined) {
            let tempFilter = ' Type = \'' + this.selectedType + '\'';
            filter = (filter == null) ? tempFilter : filter + ' AND ' + tempFilter;
        }
        if(this.selectedCaseOwnerId != null && this.selectedCaseOwnerId != undefined) {
            let tempFilter = ' OwnerId = \'' + this.selectedCaseOwnerId + '\'';
            filter = (filter == null) ? tempFilter : filter + ' AND ' + tempFilter;
        }
        if(this.closedDate != null && this.closedDate != undefined) {
            let tempFilter = ' CreatedDate = ' + this.closedDate;
            filter = (filter == null) ? tempFilter : filter + ' AND ' + tempFilter;
        }
        if(this.createdDate != null && this.createdDate != undefined) {
            let tempFilter = ' ClosedDate = ' + this.createdDate;
            filter = (filter == null) ? tempFilter : filter + ' AND ' + tempFilter;
        }

        this.isLoading = true;
        searchCasesBasedOnFilter({ filter: filter }).then(result => {
            this.casesList = result;
            this.showCaseResults = true;
            this.isLoading = false;
        })
        .catch(error => {
            this.error = error;
        });
    }
}