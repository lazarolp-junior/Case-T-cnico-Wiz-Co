public with sharing class PedidoSuporteInatividadeQueueable implements Queueable {
    private static final Integer DIAS_SEM_INTERACAO = 3;

    public void execute(QueueableContext context) {
        processarPedidosSemInteracao();
    }

    public static Id executarAssincrono() {
        return System.enqueueJob(new PedidoSuporteInatividadeQueueable());
    }

    @TestVisible
    static void processarPedidosSemInteracao() {
        Datetime limiteInatividade = System.now().addDays(-DIAS_SEM_INTERACAO);

        List<PedidoSuporte__c> pedidosParaAtualizar = [
            SELECT Id, Name, Cliente__c, UltimaInteracao__c, Status__c
            FROM PedidoSuporte__c
            WHERE UltimaInteracao__c != null
            AND UltimaInteracao__c < :limiteInatividade
            AND Status__c != 'Aguardando Cliente'
        ];

        if (pedidosParaAtualizar.isEmpty()) {
            return;
        }

        Set<Id> idsContasCliente = new Set<Id>();
        for (PedidoSuporte__c pedido : pedidosParaAtualizar) {
            if (pedido.Cliente__c != null) {
                idsContasCliente.add(pedido.Cliente__c);
            }
            pedido.Status__c = 'Aguardando Cliente';
        }

        update pedidosParaAtualizar;

        Map<Id, String> emailPorConta = buscarEmailsDasContas(idsContasCliente);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (PedidoSuporte__c pedido : pedidosParaAtualizar) {
            String emailCliente = emailPorConta.get(pedido.Cliente__c);
            if (String.isBlank(emailCliente)) {
                continue;
            }

            Messaging.SingleEmailMessage mensagem = new Messaging.SingleEmailMessage();
            mensagem.setToAddresses(new List<String>{ emailCliente });
            mensagem.setSubject('Pedido de Suporte com inatividade');
            mensagem.setPlainTextBody(
                'Seu Pedido de Suporte ' + pedido.Name +
                'será fechado em breve por inatividade.\n\n' 
            );
            emails.add(mensagem);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    @TestVisible
    static Map<Id, String> buscarEmailsDasContas(Set<Id> idsContas) {
        Map<Id, String> emailPorConta = new Map<Id, String>();
        if (idsContas == null || idsContas.isEmpty()) {
            return emailPorConta;
        }

        Map<String, Schema.SObjectField> camposDaConta = Account.SObjectType.getDescribe().fields.getMap();
        String nomeCampoEmail = null;
        if (camposDaConta.containsKey('Email__c')) {
            nomeCampoEmail = 'Email__c';
        } else if (camposDaConta.containsKey('PersonEmail')) {
            nomeCampoEmail = 'PersonEmail';
        }

        if (String.isBlank(nomeCampoEmail)) {
            return emailPorConta;
        }

        String soql = 'SELECT Id, ' + nomeCampoEmail + ' FROM Account WHERE Id IN :idsContas';
        for (Account conta : Database.query(soql)) {
            String email = (String) conta.get(nomeCampoEmail);
            if (String.isNotBlank(email)) {
                emailPorConta.put(conta.Id, email);
            }
        }

        return emailPorConta;
    }
}
