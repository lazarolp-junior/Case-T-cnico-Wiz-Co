trigger PedidoSuporteTrigger on PedidoSuporte__c (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        PedidoSuporteTriggerHandler.validarRegrasDeNegocio(Trigger.new, Trigger.oldMap);
    }
}
