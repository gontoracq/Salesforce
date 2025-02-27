public class FALCON_generateCongaUtils {
    
    public static Map<String,String> generateCaseConga(String caseId){
        map<String,String> mapresult = new map<String,String>();
        Case soCase = [SELECT Id,FALCON_fld_TitleAux__c,FALCON_fld_CIE__c FROM Case WHERE Id = :caseId];
        String structTemp = getADMTempCases(soCase);
        map<String,String> mapinputConga = new map<String,String>();
        mapinputConga.put('recordId',soCase.Id);
        mapresult = generateCongaComposer(mapinputConga,structTemp);
        return mapresult;
        
    }
    //GTQ START

    @AuraEnabled
    public static Map<String,String> generateOTConga(String workOrderId){

        System.debug('FALCON_generateCongaUtils :: generateOTConga :: START');

        Map<String,String> mapresult = new Map<String,String>();

        FALCON_obj_WorkOrder__c soOT = [SELECT Id,FALCON_fld_Account__r.Name,FALCON_fld_BusinessName__c,
                                        FALCON_fld_Account__r.FALCON_fld_BillingAddress__c, FALCON_fld_Account__r.FALCON_fld_DocumentNumber__c,
                                        FALCON_fld_Account__r.FALCON_fld_MainAddress__c,
                                        FALCON_fld_ContactQuote__r.Name,FALCON_fld_ContactQuote__r.Email,FALCON_fld_ContactQuote__r.Phone,
                                        FALCON_fld_ContactQuote__r.FALCON_fld_DocumentNumber__c,FALCON_fld_equipmentRecords__c
                                        FROM FALCON_obj_WorkOrder__c WHERE Id = :workOrderId];
        String structTemp = getADMTempOTs(soOT);
        map<String,String> mapinputConga = new map<String,String>();
        mapinputConga.put('recordId',soOT.Id);

        mapresult = generateCongaComposerOT(mapinputConga,structTemp);

        System.debug('FALCON_generateCongaUtils :: generateOTConga :: END');

        return mapresult;

    }
    //GTQ END
    
    public static string getADMTempCases(Case soCase){
		
        List<String> outAdmTemp = new List<String>();
        system.debug(soCase.FALCON_fld_TitleAux__c);
        List<Admin_Template_Product__c> lstAdmProduct = [SELECT Id,Admin_Templates__c  FROM Admin_Template_Product__c WHERE Param_trica_Casos__r.Name = :soCase.FALCON_fld_TitleAux__c AND  Admin_Templates__r.FALCON_fld_Template_Type__c = 'Case' LIMIT 1];
            if(lstAdmProduct.size()>0){
                for(Admin_Template_Product__c soAdmProduct : lstAdmProduct){
                    outAdmTemp.add(soAdmProduct.Admin_Templates__c);
                }
            }
        List<String> listConditions = getListConditions(soCase);
        system.debug('listConditions: ' + listConditions);
        system.debug('listConditions: ' + listConditions.size());
        system.debug('lstAdmProduct.get(0).Id: ' + lstAdmProduct.get(0).Id);
        
        List<FALCON_obj_JunctionTemplate__c> listJunctionTemplate = [SELECT id,FALCON_fld_Template__r.FALCON_fld_CongaTemplate__c,FALCON_fld_Condition__c, FALCON_fld_Order__c 
                            FROM FALCON_obj_JunctionTemplate__c
                            WHERE FALCON_fld_AdminTemplate__c = :lstAdmProduct.get(0).Admin_Templates__c AND FALCON_fld_Condition__c in :listConditions order by FALCON_fld_Order__c];
        List<String> lstStringTemp = new List<String>();
        for(FALCON_obj_JunctionTemplate__c soJuncTemp : listJunctionTemplate){
            lstStringTemp.add(soJuncTemp.FALCON_fld_Template__r.FALCON_fld_CongaTemplate__c);
        }      
        
        
        
        String resultADM = String.join(lstStringTemp,',');
        return resultADM;
        
    }

    //GTQ START
    @AuraEnabled
    public static string getADMTempOTs(FALCON_obj_WorkOrder__c soOT){
		
        List<String> outAdmTemp = new List<String>();
        System.debug('FALCON_generateCongaUtils :: getADMTempOT :: START');
        System.debug(soOT);
        List<FALCON_obj_ContractWorkOrder__c> contWOList =  [SELECT FALCON_fld_Asset__r.FALCON_fld_ProductoComercial__c FROM FALCON_obj_ContractWorkOrder__c WHERE FALCON_fld_WorkOrder__c =: soOT.id];
        
        //Code added for aggregated result count number of OT equipments related START
        /*List<String> idWOLIlist = new List<String>();
        List<FALCON_obj_WorkOrderLineItem__c> updateWOLI = new List<FALCON_obj_WorkOrderLineItem__c>();
        for(FALCON_obj_WorkOrderLineItem__c woli : woLiList){
            idWOLIlist.add(woli.id);
        }
        List<AggregateResult> aggList = [SELECT count(id)num, FALCON_fld_WOLI__c FROM FALCON_obj_WOEquipment__c WHERE FALCON_fld_WOLI__c IN: idWOLIlist GROUP BY FALCON_fld_WOLI__c];
        for(AggregateResult agg : aggList){
            FALCON_obj_WorkOrderLineItem__c woli = new FALCON_obj_WorkOrderLineItem__c(); 
            woli.Id=(id)agg.get('FALCON_fld_WOLI__c'); 
            woli.FALCON_fld_nEquipments__c=(integer)agg.get('num'); 
            updateWOLI.add(woli); 
        }
        update updateWOLI;

        for(Integer i = 0; i < updateWOLI.size(); i++){
            woLiList[i].FALCON_fld_nEquipments__c = updateWOLI[i].FALCON_fld_nEquipments__c;
        }*/
        //Code added for aggregated result count number of OT equipments related END

        FALCON_obj_ContractWorkOrder__c contWO = contWOList.get(0);
        List<Admin_Template_Product__c> lstAdmProduct = [SELECT Id,Admin_Templates__c, Related_Product__c  
                                                        FROM Admin_Template_Product__c 
                                                        WHERE Related_Product__r.Name =: contWO.FALCON_fld_Asset__r.FALCON_fld_ProductoComercial__c 
                                                        AND Admin_Templates__r.FALCON_fld_Template_Type__c = 'OT' LIMIT 1];
                                                        
        if(lstAdmProduct.size()>0){
            for(Admin_Template_Product__c soAdmProduct : lstAdmProduct){
                outAdmTemp.add(soAdmProduct.Admin_Templates__c);
            }
        }
        
        List<FALCON_obj_JunctionTemplate__c> listJunctionTemplate = [SELECT id,FALCON_fld_Template__r.FALCON_fld_CongaTemplate__c,FALCON_fld_Condition__c, FALCON_fld_Order__c 
                            FROM FALCON_obj_JunctionTemplate__c
                            WHERE FALCON_fld_AdminTemplate__c = :lstAdmProduct.get(0).Admin_Templates__c];
        List<String> lstStringTemp = new List<String>();
        for(FALCON_obj_JunctionTemplate__c soJuncTemp : listJunctionTemplate){
            lstStringTemp.add(soJuncTemp.FALCON_fld_Template__r.FALCON_fld_CongaTemplate__c);
        }      
        
        
        
        String resultADM = String.join(lstStringTemp,',');

        System.debug('FALCON_generateCongaUtils :: getADMTempOT :: END');

        return resultADM;
        
    }
    //GTQ END
    
    public static map<string,string> generateCongaComposer(map<String,String> mapDataConga,String structureTemp){
        Map<String,String> mapresult = new map<String,String>();
		Map<String,String> mapReturn = fetchUserSessionId();
		String sessionId = mapReturn.get('sessionId');
        String sessionId2 = UserInfo.getSessionId();
        System.debug('SESION --- ' + sessionId.substring(0, 10) + ' ' + sessionId.substring(10) + ' --- ');
        System.debug('SESION --- ' + sessionId2.substring(0, 10) + ' ' + sessionId2.substring(10) + ' --- ');
		String serverUrl = mapReturn.get('serverURL');
		System.debug('### FALCON_PreviewPDFSign_Controller ### generateCongaComposer:: START');
		
		String documentoCongaId='';
		Map<String,String>mapToreturn = new Map<String,String>();
        
        List<APXTConga4__Conga_Merge_Query__c> listaCongaQueries = [SELECT id, APXTConga4__Name__c FROM APXTConga4__Conga_Merge_Query__c];
        
        Map<String, Id> mapCongaQueries = new Map<String, Id>();

        for(APXTConga4__Conga_Merge_Query__c congaQueries : listaCongaQueries){
            mapCongaQueries.put(congaQueries.APXTConga4__Name__c,congaQueries.id);
        }
		
		String urlConga = 'https://eu-composer.congamerge.com/composer8/index.html?sessionId=' + sessionId + '&serverUrl=' + serverUrl + '&Id=' + mapDataConga.get('recordId');
        String filename = 'TarifarioPruebaPatata';
        String CongaQueries = '';
        CongaQueries += '&QueryId=[Cabecera20A]'+ mapCongaQueries.get('GetCabeceraTablaCuotaFija_2.0A');

        
        
        
        String urlParameters = CongaQueries+'&templateid=' + structureTemp + '&DefaultPDF=1&APDF=1&PDFEF=1&OFN='+ filename +'&APIMode=1&AWD=1&DS7=3&SC0=1&SC1=SalesforceFile';
        urlConga +=urlParameters;
        System.debug('### FALCON_PreviewPDFSign_Controller ### generateCongaComposer:: urlConga: ' + urlConga);
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(urlConga);
        req.setMethod('GET');
        req.setTimeout(60000);

        HttpResponse res = http.send(req);

        System.debug('### FALCON_PreviewPDFSign_Controller ### generateCongaComposer :: response: ' + res);
        System.debug('FALCON_PreviewPDFSign_Controller Respuesta Conga: ' + res.getBody());
        System.debug('FALCON_PreviewPDFSign_Controller Status Respuesta Conga ' + res.getStatus());
        System.debug('FALCON_PreviewPDFSign_Controller getStatusCode() ' + res.getStatusCode());

		documentoCongaId = res.getBody(); 
		
		System.debug('FALCON_PreviewPDFSign_Controller:::generateCongaComposer documentoCongaId: '+documentoCongaId);
		if(documentoCongaId!=''){
			//01078(C) - I
			ContentVersion cv = [SELECT Id,VersionData FROM ContentVersion where Id = :documentoCongaId];
			Blob blobpdf = cv.VersionData;
			String b64 = EncodingUtil.base64Encode(blobpdf);
			//ContentDocument documento = [Select Id, LatestPublishedVersionId,  LatestPublishedVersion.VersionData From ContentDocument Where LatestPublishedVersionId =:documentoCongaId];
			/*********** RETURN Document Link */
            //system.debug('documento: ' + documento);
            mapresult.put('result','OK');
            mapresult.put('b64file',b64);
            mapresult.put('docId',documentoCongaId);
            return mapresult;
			
		}else{
            mapresult.put('result','KO');
			return mapresult;
		}	
		//System.debug('FALCON_PreviewPDFSign_Controller:::generateCongaComposer mapToreturn: '+mapToreturn);
		//return mapToreturn;
    }
    
    //GTQ START
    public static map<string,string> generateCongaComposerOT(map<String,String> mapDataConga,String structureTemp){

        System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: START');

        Map<String,String> mapresult = new map<String,String>();
		Map<String,String> mapReturn = fetchUserSessionId();
		String sessionId = mapReturn.get('sessionId');
        String sessionId2 = UserInfo.getSessionId();
        System.debug('SESION --- ' + sessionId.substring(0, 10) + ' ' + sessionId.substring(10) + ' --- ');
        System.debug('SESION --- ' + sessionId2.substring(0, 10) + ' ' + sessionId2.substring(10) + ' --- ');
		String serverUrl = mapReturn.get('serverURL');
		
		String documentoCongaId='';
		Map<String,String>mapToreturn = new Map<String,String>();
        
        List<APXTConga4__Conga_Merge_Query__c> listaCongaQueries = [SELECT id, APXTConga4__Name__c FROM APXTConga4__Conga_Merge_Query__c];
        
        Map<String, Id> mapCongaQueries = new Map<String, Id>();

        for(APXTConga4__Conga_Merge_Query__c congaQueries : listaCongaQueries){
            mapCongaQueries.put(congaQueries.APXTConga4__Name__c,congaQueries.id);
        }
		
		String urlConga = 'https://eu-composer.congamerge.com/composer8/index.html?sessionId=' + sessionId + '&serverUrl=' + serverUrl + '&Id=' + mapDataConga.get('recordId');
        String filename = 'OT';
        String CongaQueries = '';
        CongaQueries += '&QueryId=[OTRelated]'+ mapCongaQueries.get('GetOT') + '&QueryId=[OTEquipments]' + mapCongaQueries.get('GetWOEquipos') + '&QueryId=[OTCWORel]'+ mapCongaQueries.get('GetContractWOByWO');

        String urlParameters = CongaQueries+'&templateid=' + structureTemp + '&DefaultPDF=1&APDF=1&PDFEF=1&OFN='+ filename +'&APIMode=1&AWD=1&DS7=3&SC0=1&SC1=SalesforceFile';
        urlConga +=urlParameters;
        System.debug('### FALCON_generateCongaUtils ### generateCongaComposerOT:: urlConga: ' + urlConga);
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(urlConga);
        req.setMethod('GET');
        req.setTimeout(60000);

        HttpResponse res = http.send(req);

        System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: response: ' + res);
        System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: Respuesta Conga: ' + res.getBody());
        System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: Status Respuesta Conga ' + res.getStatus());
        System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: getStatusCode() ' + res.getStatusCode());

		documentoCongaId = res.getBody(); 
		
		System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: documentoCongaId: '+documentoCongaId);
		if(documentoCongaId!=''){
			//01078(C) - I
			ContentVersion cv = [SELECT Id,VersionData FROM ContentVersion where Id = :documentoCongaId];
			Blob blobpdf = cv.VersionData;
			String b64 = EncodingUtil.base64Encode(blobpdf);
			//ContentDocument documento = [Select Id, LatestPublishedVersionId,  LatestPublishedVersion.VersionData From ContentDocument Where LatestPublishedVersionId =:documentoCongaId];
			/*********** RETURN Document Link */
            //system.debug('documento: ' + documento);
            mapresult.put('result','OK');
            mapresult.put('b64file',b64);
            mapresult.put('docId',documentoCongaId);

            System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: END');

            return mapresult;
			
		}else{
            mapresult.put('result','KO');

            System.debug('FALCON_generateCongaUtils :: generateCongaComposerOT :: ERROR');

			return mapresult;
		}	
		//System.debug('FALCON_PreviewPDFSign_Controller:::generateCongaComposer mapToreturn: '+mapToreturn);
		//return mapToreturn;
	}
    //GTQ END
    
    public static Map<String,String> fetchUserSessionId(){
		Map<String,String> mapReturn = new Map<String,String>();
		String sessionId = '';
		String serverURL = '';
		// Refer to the Page
		PageReference reportPage = Page.FALCON_vf_GenerateApiSession;
		// Get the content of the VF page
		String vfContent = reportPage.getContent().toString();
		System.debug('vfContent '+vfContent);
		// Find the position of Start_Of_Session_Id and End_Of_Session_Id
		Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
		endP = vfContent.indexOf('End_Of_Session_Id');
		// Get the Session Id
		sessionId = vfContent.substring(startP, endP);
		mapReturn.put('sessionId',sessionId);

		// Find the position of Start_Of_ServerURL_Id and End_Of_ServerURL_Id
		Integer startP2 = vfContent.indexOf('Start_Of_ServerURL_Id') + 'Start_Of_ServerURL_Id'.length(),
		endP2 = vfContent.indexOf('End_Of_ServerURL_Id');
		// Get the serverURL
		serverURL = vfContent.substring(startP2, endP2);
		System.debug('serverURL '+serverURL);
		mapReturn.put('serverURL',serverURL);

		return mapReturn;
		}
    
    public static List<String> getListConditions(Case soCase){

        List<String> listReturn = new List<String>();
        Map<String,String> mapCondiciones = new Map<String,String>();
        String cadenaVacia = '';

        //Por defecto, metemos en la lista un valor vacío para aquellas templates que son Obligatorias y no tienen el campo Condicion informado
        listReturn.add(cadenaVacia);

        List<Schema.PicklistEntry> listaValoresCondiciones =  Schema.FALCON_obj_JunctionTemplate__c.fields.FALCON_fld_Condition__c.getDescribe().getPicklistValues();
            for(Schema.PicklistEntry valor : listaValoresCondiciones){
                mapCondiciones.put(valor.getLabel(),valor.getValue());
                //System.debug('valor : ' + valor.getLabel());
            }

        if(soCase.FALCON_fld_CIE__c ){
            listReturn.add(mapCondiciones.get('SEPA Casos'));
        }
        

        return listReturn;
    }

}
