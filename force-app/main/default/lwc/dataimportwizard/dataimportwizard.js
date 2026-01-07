import { LightningElement } from 'lwc';
import loadCSVData from '@salesforce/apex/DataImportController.loadCSVData';
import getCreatableObjects from '@salesforce/apex/DataImportController.getCreatableObjects';
import getFieldsForObject from '@salesforce/apex/DataImportController.getFieldsForObject'
import insertRecords from '@salesforce/apex/DataImportController.insertRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Dataimportwizard extends LightningElement {

    acceptedFormats = ['.csv'];
    salesforceObjects = [];
    fieldList = [];
    columnHeader = [];
    fileData = [];
    fieldMapping = {};
    selectedObjectName = '';

    handleUploadFinished(event){
        if(event.detail.files.length > 0){
        console.log(0);
        console.log(1, event.detail.files[0]);
        let file = event.detail.files[0];
        const contentDocumentId = file.documentId;

        this.readfile(contentDocumentId);
            
        }else{
            const event = new ShowToastEvent({
            title: 'No file Found',
            message:
                'Seems like no file found',
        });
        this.dispatchEvent(event);
        }
    }

    async readfile(contentDocumentId){
        try{
            const csvData = await loadCSVData({documentId : contentDocumentId});
            console.log(2, csvData);

            const correctData = this.correctCSV(csvData);
            this.columnHeader = this.getCSVHeader(correctData);
            console.log(1, 'Column Header', this.columnHeader);
            this.fileData = this.extractFileData(correctData);

            this.fetchObject();
        } catch {
                const event = new ShowToastEvent({
                    title: 'Error Occured',
                    message:
                        'While Reading the file',
            });
                this.dispatchEvent(event);
        }
    }

    correctCSV(csvData){
        console.log('In Correct CSV fn');
        const correctedData = [];
        for(let i=0; i<csvData.length; i++){
            correctedData.push(csvData[i].replaceAll('\r', ''));
        }

        console.log('Çorrected Data', correctedData);
        return correctedData;
    }

    getCSVHeader(correctData){
        return correctData[0].split(',').map(headerValue => {
            return {
                label : headerValue,
                value : headerValue
            };
        });
    }

    extractFileData(correctData){
        let fielData =[];
        for(let i=1; i< correctData.length; i++){
            let row = {};
            let k = 0;
            let correctDataRowValue = correctData[i].split(',');
            this.columnHeader.forEach(header => {
                row[header.label]=correctDataRowValue[k];
                k++;
            })
            fielData.push(row);
        }
        console.log('File Data', fielData);
        return fielData;
    }

    async fetchObject(){
        let objectNameLabel = await getCreatableObjects();
        let objectOptions= [];
        
        objectNameLabel.forEach(objectInfo=> {
            objectOptions.push({label: objectInfo.label, value: objectInfo.apiName})
        })
        // console.log('Object Name', objectNameLabel);
        this.salesforceObjects = objectOptions;
    }

    handleObjectSelection(event){
        this.selectedObjectName = event.detail.value;
        this.fetchFieldsForSelectedObject();
    }

    async fetchFieldsForSelectedObject(){
        this.fieldList = await getFieldsForObject({objectName: this.selectedObjectName});
        console.log('Fields Fetched', this.fieldList);
    }

    handleColumnSelection(event){
        let column = event.detail.value;
        console.log('target', event?.target?.dataset?.apiname);
        this.fieldMapping[column] = event?.target?.dataset?.apiname;
        
    }

    importData(){
        let recordList = [];
        for(let i=0; i < this.fileData.length; i++){
            let record = {};
            let column = Object.keys(this.fileData[i]);
            for(let j=0; j < column.length; j++){
                let apiName = this.fieldMapping[column[j]];
                if(apiName){
                record[apiName] = this.fileData[i][column[j]];
                }
            }
            recordList.push(record);
        }
        this.insertRecordsOfCSV(recordList);
    }

    async insertRecordsOfCSV(recordList){
        try{
        await insertRecords({records: recordList, objectName: this.selectedObjectName});
        console.log('Records inserted successfully');
        }catch(err){
            console.log('insert failed');
        }
    }
}