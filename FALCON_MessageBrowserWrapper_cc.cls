public with sharing class FALCON_MessageBrowserWrapper_cc {

    @AuraEnabled
    public static MessageBrowserForm getInfoToForm(string fname, string lname) {

        /*Campos de Switching:
        ID, Código Switching, Estado, Nº Referencia Solicitud Comercializadora, Código Solicitud, CUPS Solicitud, Código de proceso, Código Tipo de Mensaje, 
        Empresa Emisora del Paso, Empresa receptora del paso, Fecha Respuesta, Fecha Creacion*/
        
        MessageBrowserForm dataWrapper = new MessageBrowserForm();

        dataWrapper.lstStatusCode = FALCON_util_CommonMethods.getPickListValues('FALCON_obj_Switching__c', 'FALCON_fld_Status__c');
        dataWrapper.lstData = [SELECT Id, Name,	FALCON_fld_Status__c, FALCON_fld_SWHeader__c, FALCON_fld_reqcode__c, FALCON_fld_cups__c,
                                FALCON_fld_processcode__c, FALCON_fld_messagetype__c, FALCON_fld_dispatchingcompany__c, FALCON_fld_destinycompany__c, 
                                FALCON_fld_responsedate__c, CreatedDate, FROM FALCON_obj_Switching__c LIMIT 100];
        
        return dataWrapper;
    }

    @AuraEnabled
    public static Message_Download__c newDownloadRequest(List<String> messageIds) {
        if (messageIds == null || messageIds.isEmpty()) {
            throw new DownloadRequestException('No se creará la descarga, la lista de mensajes está vacía.');
        }
        Message_Download__c dr = new Message_Download__c();
        insert dr;
        dr = addMessagesForDownload(messageIds, dr.Id);
        dr.Status__c = 'In process';
        update dr;
        return dr;
    }
    
    private static Message_Download__c addMessagesForDownload(List<String> messageIds, String downloadRequestId) {
        List<Message_Download_Junction__c> junctions = new List<Message_Download_Junction__c>();
        for (String mId : messageIds) {
            junctions.add(new Message_Download_Junction__c(
                              Switching__c = mId,
                              Message_Download__c = downloadRequestId
                          ));
        }
        List<Database.SaveResult> insertResult = Database.insert(junctions, true);
        return [select Id, Status__c, Message_count__c from Message_Download__c where Id = :downloadRequestId];
    }

    public class MessageBrowserForm{
        @AuraEnabled
        public List<Message_Download__c> lstData;
        @AuraEnabled
        public List<FALCON_util_CommonMethods.PickValues> lstStatusCode;
    }
    
    public class DownloadRequestException extends Exception {}
}
