/*@name: FALCON_cmp_CupsMassiveModify.js
    @date: 05/03/2020
    @author: Gonzalo Torres
    @description: 00709
    *History: 
    <Date>                      <Author>                    <Change Description>
    05-feb-2020					Gonzalo Torres				00709 - Table implementation
    10-feb-2020                 Gonzalo Torres              00709 - Validations
    12-feb-2020                 Gonzalo Torres              00709 - Filters implementation
    
    */

({
    
	doInit: function(component, event, helper)
    {
        
        var idOpp = component.get('v.recordId');
        component.set("v.showDataTable", true);
        if( !idOpp )
        {
            component.set("v.opp.", "");
        	component.set("v.oppId", "");
        }
        else
        {  
          component.set("v.opp.", idOpp);
          component.set("v.oppId", idOpp); 
        }
        helper.fillTableCups(component);
        helper.picklistOptions(component);
    },
    
    aplicar : function(component, event, helper) {
        var cupsName = component.get('v.cupsName');
        var cifnif = component.get('v.cifnif');
        var tarifa = document.getElementById('tarifaFilter').value;
        var tipoMovimiento = document.getElementById('tipoMovFilter').value;
        var idOpp = component.get('v.recordId');
        
        var action = component.get('c.aplicarFiltros');

        action.setParams({
            'cupsName':cupsName,
            'cifnif':cifnif,
            'tarifa' :tarifa,
            'tipoMovimiento':tipoMovimiento,
            'idOpp' :idOpp
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var finalResponse = response.getReturnValue();
                for (var i = 0; i < finalResponse.length; i++) {
                    var row = finalResponse[i];
                    if (row.FALCON_fld_Account__c) row.AccounDocumentNumber = row.FALCON_fld_Account__r.FALCON_fld_DocumentNumber__c;
                    console.log('AccounDocumentNumber: ' + row.AccounDocumentNumber);
                }
                component.set('v.body', finalResponse);
                component.set('v.cupsName', null);
                component.set('v.cifnif', null);
                component.set('v.tarifa', null);
                component.set('v.tipoMovimiento', null);
            }else{
                console.log(finalResponse);
            }
        });
        $A.enqueueAction(action);
		
    },
    
    guardar : function(component, event, helper) {

        var cups = component.get('v.body');
        var action = component.get('c.updateData');

        for (var i = 0; i < cups.length; i++) {
            cups[i].FALCON_fld_ContractPowerP1__c =  parseFloat( cups[i].FALCON_fld_ContractPowerP1__c);
            cups[i].FALCON_fld_ContractPowerP2__c =  parseFloat( cups[i].FALCON_fld_ContractPowerP2__c);
            cups[i].FALCON_fld_ContractPowerP3__c =  parseFloat( cups[i].FALCON_fld_ContractPowerP3__c);
            cups[i].FALCON_fld_ContractPowerP4__c =  parseFloat( cups[i].FALCON_fld_ContractPowerP4__c);
            cups[i].FALCON_fld_ContractPowerP5__c =  parseFloat( cups[i].FALCON_fld_ContractPowerP5__c);
            cups[i].FALCON_fld_ContractPowerP6__c =  parseFloat( cups[i].FALCON_fld_ContractPowerP6__c);
        }

        action.setParams({
            'cups' : cups
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS') {
                var finalResponse = response.getReturnValue();
                component.set('v.body', finalResponse.selectedCups);
                console.log('ERRORES :' + finalResponse.errorMessage);
                if(finalResponse.errorMessage == undefined){
                    helper.showSuccessToast('Se ha actualizado correctamente');
                }else{
                    helper.showErrorToast(finalResponse.errorMessage);
                }
            }else{
                helper.showErrorToast('No se ha podido actualizar. Revise sus cambios');
            }
        });
        $A.enqueueAction(action);
        helper.fillTableCups(component);
    },

    modificadoTarifa : function(component, event, helper) {

        var index = event.currentTarget.name;
        //Para marcar como modificado el registro
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        
        //Para modificar la tarifa
        var cupsList = component.get("v.body");
        var tarifa = event.currentTarget.value != null ? event.currentTarget.value : 'N/A';
        var cup = cupsList[index];
        
        cup.checked = checks[index];
        
        var msg = '';

        console.log('TARIFA ONCHANGE: ' + tarifa);
 
        if( tarifa.includes('2.')){
            msg = 'La potencia P1 no puede ser mayor que 10';
            cup.msg = msg;
        }else if( tarifa.includes('3.0')){
            msg = 'Las tarifas 3.0 deben tener al menos una potencia por encima de 15 kW';
            cup.msg = msg;
        }else if( tarifa.includes('3.1') ){
            msg = 'Las tarifas 3.1 no pueden una potencia por encima de 450 kW';
            cup.msg = msg;
        }else if( tarifa.includes('6.') ){
                msg = 'Las potencias deben ir decrementandose. Es decir la potencia P1 debe ser mayor que P2 y así sucesivamente'
            if(tarifa.includes('6.1'))
                msg += ' .Las tarifas 6.1 deben tener una potencia por encima de 450 kW';
            cup.msg = msg;
        }

        cup.FALCON_fld_Toll__c = tarifa;
        
        component.set("v.body", cupsList);                
        
    },

    modificadoCheckPot1 : function(component, event, helper) {
        var index = event.getSource().get('v.name');
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        component.set("v.body", cupsList);
    },

    modificadoCheckPot2 : function(component, event, helper) {
        var index = event.getSource().get('v.name');
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        component.set("v.body", cupsList);
    },

    modificadoCheckPot3 : function(component, event, helper) {
        var index = event.getSource().get('v.name');
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        component.set("v.body", cupsList);
    },

    modificadoCheckPot4 : function(component, event, helper) {
        var index = event.getSource().get('v.name');
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        component.set("v.body", cupsList);
    },

    modificadoCheckPot5 : function(component, event, helper) {
        var index = event.getSource().get('v.name');
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        component.set("v.body", cupsList);
    },

    modificadoCheckPot6 : function(component, event, helper) {
        var index = event.getSource().get('v.name');
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        component.set("v.body", cupsList);
    },

    modificadoTM : function(component, event, helper) {
        var index = event.currentTarget.name;
        var checks = component.get("v.modificadoB");
        if(checks[index] == false){
            checks[index] = true;
        }
        component.set("v.modificadoB", checks);
        console.log("Array modificados: " + component.get('v.modificadoB'));
        var cupsList = component.get("v.body");
        var cup = cupsList[index];
        cup.checked = checks[index];

        var tipoM = event.currentTarget.value != null ? event.currentTarget.value : '--None--';

        cup.Tipo_de_Movimiento__c = tipoM;

        component.set("v.body", cupsList);
    }

})
