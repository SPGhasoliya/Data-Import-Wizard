public with sharing class DataImportController {
    @AuraEnabled
    public static List<String> loadCSVData(String documentId){
        try {

            //Validate input 
            if(String.isEmpty(documentId)){
                throw new AuraHandledException('Document Id cannot be null or empty');
            }

            //Query to get ContentVersion based on ContentDocumentId
            ContentVersion contentVersionObj = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId = :documentId LIMIT 1];

            //convert to string
            String data = contentVersionObj.VersionData.toString();
            System.debug('CSV Data:' + data);
            
            //split CSV data into lines
            List<String> csvFileLines = data.split('\n');
            System.debug('CSV lines :' + csvFileLines);

            return csvFileLines;
        } catch (Exception e) {
            System.debug('Error Line Number' + e.getLineNumber());
            System.debug('Error Cause' + e.getCause());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObjectDescribe> getCreatableObjects(){
            List<SObjectDescribe> creatableObjects = new List<SObjectDescribe>();

            for(Schema.SObjectType objectType : Schema.getGlobalDescribe().values()){
                Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
                if(describeResult.isCreateable() && !describeResult.isCustomSetting()){
                    creatableObjects.add(new SObjectDescribe(describeResult.getLabel(), describeResult.getName()));
                }
            }
            return creatableObjects;
        }

    @AuraEnabled(cacheable=true)
    public static List<SObjectFieldDescribe> getFieldsForObject(String objectName){
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            List<SObjectFieldDescribe> fieldsList = new List<SObjectFieldDescribe>();
            for(Schema.SObjectField field : objectDescribe.fields.getMap().values()){
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if(fieldDescribe.isCreateable()){
                    fieldsList.add(new SObjectFieldDescribe(fieldDescribe.getLabel(), fieldDescribe.getName()));
                }
            }
            return fieldsList;
        }

    // @AuraEnabled
    // public static void insertRecords(List<Map<String, Object>> records, String objectName) {

    //     // Validate object name
    //     if (String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)) {
    //         throw new AuraHandledException('Invalid object name');
    //     }

    //     Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectName);
    //     Schema.DescribeSObjectResult objDescribe = sObjType.getDescribe();
    //     Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

    //     List<SObject> sObjectList = new List<SObject>();

    //     for (Map<String, Object> record : records) {
    //         SObject sObjectRecord = sObjType.newSObject();

    //         for (String field : record.keySet()) {

    //             // Validate field
    //             if (!fieldMap.containsKey(field)) {
    //                 continue;
    //             }

    //             Schema.DescribeFieldResult dfr = fieldMap.get(field).getDescribe();

    //             // Enforce FLS
    //             if (dfr.isCreateable()) {
    //                 sObjectRecord.put(field, record.get(field));
    //             }
    //         }
    //         sObjectList.add(sObjectRecord);
    //     }

    //     // Insert records with partial success
    //     Database.SaveResult[] results = Database.insert(sObjectList, false);

    //     // Handle errors
    //     for (Database.SaveResult sr : results) {
    //         if (!sr.isSuccess()) {
    //             throw new AuraHandledException(sr.getErrors()[0].getMessage());
    //         }
    //     }
    // }

    @AuraEnabled
    public static void insertRecords(List<Map<String, Object>> records, String objectName){

        if(String.isBlank(objectName) || !Schema.getGlobalDescribe().containsKey(objectName)){
            throw new AuraHandledException('Invalid object name');
        }
        List<SObject> sObjectList = new List<SObject>();
        for(Map<String, Object> record : records){
            SObject sObjectRecord = (SObject)Schema.getGlobalDescribe().get(objectName).newSObject();
            for(String field : record.keySet()){
                sObjectRecord.put(field, record.get(field));
            }
            sObjectList.add(sObjectRecord);
        }
            insert sObjectList;
    }

    public class SObjectDescribe{
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        public SObjectDescribe(String label, String apiName){
            this.label = label;
            this.apiName = apiName;
        }
    }

    public class SObjectFieldDescribe{
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        public SObjectFieldDescribe(String label, String apiName){
            this.label = label;
            this.apiName = apiName;
        }
    }
}