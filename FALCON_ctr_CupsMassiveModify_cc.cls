
	@name: FALCON_ctr_CupsMassiveModify_cc
	@version: 1.0
	@creation date: 05/03/2020
	@author: Gonzalo Torres
	@description: 
	@History:
      <Date>                     <Author>                     		<Change Description>
    05/03/2020				    Gonzalo Torres					    00709 - Initial version
    10/03/2020                  Gonzalo Torres                      00709 - Validaciones y metodos auxiliares
    13/03/2020                  Gonzalo Torres                      00709 - Primera versión subida

*/	

public with sharing class FALCON_ctr_CupsMassiveModify_cc {
    
	//Recuperamos los CUPS que se han seleccionado en la oportunidad
	@AuraEnabled
    public static SelectedCupsWrapper getCUPS(Id oppId){
		List<FALCON_obj_opportunityCups__c> selectedOppCups = FALCON_util_opportunityCupsWrapper.getRelatedOpportunityCups(oppId);
		List<Id> selectedOppCupsIds = new List<Id>();
		SelectedCupsWrapper responseWrapper = new SelectedCupsWrapper();

		try{
			for(FALCON_obj_opportunityCups__c elem: selectedOppCups){
				selectedOppCupsIds.add(elem.FALCON_fld_CUPS__c);
			}
			List<FALCON_obj_CUPS__c> selectedCups = [select id, name, FALCON_fld_Account__r.FALCON_fld_DocumentNumber__c, tolabel(FALCON_fld_Toll__c), FALCON_fld_ContractPowerP1__c, FALCON_fld_ContractPowerP2__c, 
				FALCON_fld_ContractPowerP3__c, FALCON_fld_ContractPowerP4__c, FALCON_fld_ContractPowerP5__c, FALCON_fld_ContractPowerP6__c,	Tipo_de_Movimiento__c
				 from FALCON_obj_CUPS__c where id in : selectedOppCupsIds];

			responseWrapper.selectedCups = selectedCups;
		}catch(Exception e){
			System.debug('[FALCON_cmp_CupsMassiveModify] - (getCUPS) - exception: ' + e);
            responseWrapper.errorMessage = e.getMessage();
		}

		return responseWrapper;
	}

	@AuraEnabled
    public static List<String> getPicklistOptions(String fieldName, String sObjectName)
    {
        List<String> options = new List<String>();
        Map<String, String> mapaTarifas = FALCON_util_constants.mapTollElecValues;

        // Get describe of all the objects
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        // Get the SObject Type from the specific object name that is passed in
        Schema.SObjectType sobjType = gd.get(sObjectName);
        // Get the describe result of the passed in object
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        // Get the fields of the passed in object
        Map<String,Schema.SObjectField> field_map = r.fields.getMap();
        // get the pick list values of the field that was passed in from the field map of the object passed in
        List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPickListValues();

        if(fieldName == 'FALCON_fld_Toll__c'){
            for (String s : mapaTarifas.keySet()){
                options.add(s);
            }
        }else{
            for (Schema.PicklistEntry f : pick_list_values){
                options.add(f.getLabel());
            }
        }

        system.debug('FALCON_cmp_CupsMassiveModify:: getPicklistOptions: return ' + options);
        return options;
    }

    @AuraEnabled
    public static Decimal comaToDotDouble(Decimal d){

        String commaReplace =  String.valueOf(d);
        String subCon = commaReplace.replace(',','.');
        Decimal valueD = decimal.valueOf(subCon);

        return valueD;
    }

    @AuraEnabled
    public static SelectedCupsWrapper updateData(List<FALCON_obj_CUPS__c> cups){

        Boolean powerValid = true;
        String msgUpdate = '';
        SelectedCupsWrapper scw = new SelectedCupsWrapper();
        scw.selectedCups = cups;

        List<String> validaciones = new List<String>();

        for(FALCON_obj_CUPS__c cup: cups){
            PowerCupsWrapper validacion = validateTollAtrPower(cup);
            system.debug('FALCON_cmp_CupsMassiveModify:: updateData: valid?? ' + validacion.validationErrorMsg);
            if(validacion.validationErrorMsg != 'OK'){
                powerValid = false;
                msgUpdate = validacion.validationErrorMsg;
                validaciones.add(msgUpdate);
                scw.errorMessage = msgUpdate;
            }
        }

        if(powerValid && validaciones.isEmpty()){
            system.debug('FALCON_cmp_CupsMassiveModify:: updateData: HA ENTRADO ');
            update cups;
        }
           
        return scw;
    }

    @AuraEnabled
    public static Boolean checkStringNotEmptyNotNull(String s){
        Boolean res = false;
        if(s != null && s != ''){
            res = true;
        }
        return res;
    }

    @AuraEnabled
    public static List<FALCON_obj_CUPS__c> aplicarFiltros(String cupsName, String cifnif, String tarifa, String tipoMovimiento, Id idOpp){

        SelectedCupsWrapper scw = getCUPS(idOpp);
        List<FALCON_obj_CUPS__c> cupsSelected = scw.selectedCups;
        List<String> cupsSelectedIds = new  List<String>();
        for(FALCON_obj_CUPS__c cup: cupsSelected){
            cupsSelectedIds.add(cup.Id);
        }
        String conditionSelectedCUPS = ' and Id in : cupsSelectedIds';
        String conditionSelectedCUPS2 = ' where Id in : cupsSelectedIds';

        String query = 'select Id, Name, FALCON_fld_Account__r.FALCON_fld_DocumentNumber__c, FALCON_fld_Toll__c, Tipo_de_Movimiento__c, FALCON_fld_ContractPowerP1__c, '
        +'FALCON_fld_ContractPowerP2__c,FALCON_fld_ContractPowerP3__c,FALCON_fld_ContractPowerP4__c, FALCON_fld_ContractPowerP5__c, '
        +'FALCON_fld_ContractPowerP6__c FROM FALCON_obj_CUPS__c';

        String condition = ' where';
        Integer cont = 0;

        if(cupsName != null){
            condition +=' Name =: cupsName';
            if(cifnif != null){
                condition += ' and FALCON_fld_Account__r.FALCON_fld_DocumentNumber__c =: cifnif';
            }
            if(checkStringNotEmptyNotNull(tarifa)){
                condition +=' and tolabel(FALCON_fld_Toll__c) =: tarifa';
            }
            if(checkStringNotEmptyNotNull(tipoMovimiento)){
                condition +=' and tolabel(Tipo_de_Movimiento__c) =: tipoMovimiento';
            }
        }else if(cifnif != null){
            condition +=' FALCON_fld_Account__r.FALCON_fld_DocumentNumber__c =: cifnif';
            if(checkStringNotEmptyNotNull(tarifa)){
                condition +=' and tolabel(FALCON_fld_Toll__c) =: tarifa';
            }
            if(checkStringNotEmptyNotNull(tipoMovimiento)){
                condition +=' and tolabel(Tipo_de_Movimiento__c) =: tipoMovimiento';
            }
        }else if(checkStringNotEmptyNotNull(tarifa)){
            condition +=' tolabel(FALCON_fld_Toll__c) =: tarifa';
            if(checkStringNotEmptyNotNull(tipoMovimiento)){
                condition +=' and tolabel(Tipo_de_Movimiento__c) =: tipoMovimiento';
            }
        }else if(checkStringNotEmptyNotNull(tipoMovimiento)){
            condition +=' tolabel(Tipo_de_Movimiento__c) =: tipoMovimiento';
        }

        if(condition.length() > 6){
            query =query + condition + conditionSelectedCUPS;
        }else{
            query =query + conditionSelectedCUPS2;
        }

        system.debug('FALCON_cmp_CupsMassiveModify:: aplicarFiltros: tarifa ' + tarifa);
         
        system.debug('FALCON_cmp_CupsMassiveModify:: aplicarFiltros: query ' + query);

        List<FALCON_obj_CUPS__c> res = Database.query(query);

        system.debug('FALCON_cmp_CupsMassiveModify:: aplicarFiltros: return ' + res);

        return res;

    }

    @AuraEnabled
    public static string validatePotencias2XToString(String currentRate, Decimal currentP1Value, Decimal currentP2Value, Decimal currentP3Value){

        String mensaje = '';
        //2.X
        if((currentRate.contains('2.')) && currentP1Value > 10 ){
            mensaje += 'La potencia para tarifas 2.X no puede ser mayor a 10 kW. ';
        }
            
        //2.X DHA
        if(currentRate.contains('2.') && currentRate.contains('DHA'))
        {
            if(currentP1Value > 10){
                mensaje += 'La potencia para tarifas 2.X DHA no puede ser mayor a 10 kW. ';
            }

            if(currentP1Value != currentP2Value){
                mensaje += 'Potencia 1 y Potencia 2 deben ser iguales. ';
            } 
        }

        //2.X DHS
        if( (currentRate.contains('2.') && currentRate.contains('DHS')) && (currentP1Value != currentP2Value || currentP1Value != currentP3Value) )
        {
            mensaje += 'Potencia 1, Potencia 2 y Potencia 3 deben ser iguales. ';
        }

        return mensaje;
    }

    @AuraEnabled
    public static string validatePotencias3XToString(String currentRate, Decimal currentP1Value, Decimal currentP2Value, Decimal currentP3Value){

        String mensaje = '';

        //3.X
        if((currentRate.contains('3.')) 
        && currentP1Value <= 15  && currentP2Value <= 15 && currentP3Value <= 15){
            mensaje += 'Las tarifas 3.0 deben tener al menos una potencia por encima de 15 kW. ';
        }
    
        //3.1 A
        if(currentRate == '3.1 A' && (currentP1Value > 450  || currentP2Value > 450 || currentP3Value > 450)){
            mensaje += 'Las tarifas 3.1 no pueden una potencia por encima de 450 kW. ';
        }

        return mensaje;
    }

    @AuraEnabled
    public static string validatePotencias6XToString(String currentRate, Decimal currentP1Value, Decimal currentP2Value, Decimal currentP3Value,
                                                        Decimal currentP4Value, Decimal currentP5Value, Decimal currentP6Value){

        String mensaje = '';

        mensaje += validatePotencias6XToStringRefactor(currentRate, currentP1Value, currentP2Value, currentP3Value, currentP4Value, currentP5Value, currentP6Value);

        //6.X
        if((currentRate.contains('6.'))
            && (currentP1Value <= currentP2Value || currentP2Value <= currentP3Value 
            || currentP3Value <= currentP4Value || currentP4Value <= currentP5Value || 
            currentP5Value <= currentP6Value)
        ){
            mensaje += 'Las potencias 6.X deben ir decrementandose. Es decir la potencia P1 debe ser mayor que P2 y así sucesivamente';
        }

        return mensaje;
        
    }

    @AuraEnabled
    public static string validatePotencias6XToStringRefactor(String currentRate, Decimal currentP1Value, Decimal currentP2Value, Decimal currentP3Value,
                                                                Decimal currentP4Value, Decimal currentP5Value, Decimal currentP6Value){

        String mensaje = '';

        if((currentRate == '6.1 A/B' || currentRate == '017') && 
                (currentP1Value <= 450 || currentP2Value <= 450 ||	currentP3Value <= 450
                || currentP4Value <= 450 || currentP5Value <= 450 ||	currentP6Value <= 450)){
                    mensaje += 'Las tarifas 6.1 deben tener una potencia por encima de 450 kW. ';
        }

        return mensaje;
        
    }

    @AuraEnabled
	public static PowerCupsWrapper validateTollAtrPower(FALCON_obj_CUPS__c cup)
	{
        System.debug('FALCON_ctr_CupsMassiveModify_cc:::validateTollAtrPower IN');

        System.debug('FALCON_ctr_CupsMassiveModify_cc:::validateTollAtrPower CUP: ' + cup);

        PowerCupsWrapper pcw = new PowerCupsWrapper();
        
        pcw.validationErrorMsg = '';

		string currentRate;
        Decimal currentP1Value;
        Decimal currentP2Value;
        Decimal currentP3Value;
        Decimal currentP4Value;
        Decimal currentP5Value;
        Decimal currentP6Value;


		if(cup.FALCON_fld_Toll__c == ' '){
            pcw.validationErrorMsg += 'Debe elegir una tarifa ATR. ';
            
        }else{

			currentRate = cup.FALCON_fld_Toll__c != null ? cup.FALCON_fld_Toll__c : 'N/A';
            currentP1Value = cup.FALCON_fld_ContractPowerP1__c != null ? cup.FALCON_fld_ContractPowerP1__c : -1;
            currentP2Value = cup.FALCON_fld_ContractPowerP2__c != null ? cup.FALCON_fld_ContractPowerP2__c : -1;
            currentP3Value = cup.FALCON_fld_ContractPowerP3__c != null ? cup.FALCON_fld_ContractPowerP3__c : -1;
            currentP4Value = cup.FALCON_fld_ContractPowerP4__c != null ? cup.FALCON_fld_ContractPowerP4__c : -1;
            currentP5Value = cup.FALCON_fld_ContractPowerP5__c != null ? cup.FALCON_fld_ContractPowerP5__c : -1;
			currentP6Value = cup.FALCON_fld_ContractPowerP6__c != null ? cup.FALCON_fld_ContractPowerP6__c : -1;
              
            System.debug('FALCON_ctr_CupsMassiveModify_cc:::validateTollAtrPower CurrentRate: ' + currentRate);
            System.debug('FALCON_ctr_CupsMassiveModify_cc:::validateTollAtrPower CurrentP1Value: ' + currentP1Value);
           //Maximetro???
			
			//2.X
            pcw.validationErrorMsg += validatePotencias2XToString(currentRate, currentP1Value, currentP2Value, currentP3Value);
            
            //3.X
            pcw.validationErrorMsg += validatePotencias3XToString(currentRate, currentP1Value, currentP2Value, currentP3Value);   

			//6.X
			pcw.validationErrorMsg += validatePotencias6XToString(currentRate, currentP1Value, currentP2Value, currentP3Value, currentP4Value, currentP5Value, currentP6Value);
			
            if(pcw.validationErrorMsg.length() == 0)
                pcw.validationErrorMsg = 'OK';
		}
		
		System.debug('FALCON_ctr_CupsMassiveModify_cc:::validateTollAtrPower OUT');

		return pcw;
    }
    
    public class PowerCupsWrapper{

        @AuraEnabled 
        public boolean potencia1FR;
        @AuraEnabled 
        public boolean potencia2FR;
        @AuraEnabled 
        public boolean potencia3FR;
        @AuraEnabled 
        public boolean potencia4FR;
        @AuraEnabled 
        public boolean potencia5FR;
        @AuraEnabled 
        public boolean potencia6FR;
        @AuraEnabled 
        public string validationErrorMsg;
    }
	
	public class SelectedCupsWrapper{
        @AuraEnabled 
        public List<FALCON_obj_CUPS__c> selectedCups;
        @AuraEnabled 
        public String errorMessage;
    }

}
