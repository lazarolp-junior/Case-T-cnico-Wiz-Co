@IsTest
private class PedidoSuporteInatividadeQueueableTest {
    private static Account criarContaComEmailQuandoPossivel() {
        Account conta = new Account(Name = 'Cliente Teste');
        Map<String, Schema.SObjectField> camposDaConta = Account.SObjectType.getDescribe().fields.getMap();
        if (camposDaConta.containsKey('Email__c')) {
            conta.put('Email__c', 'cliente.teste@example.com');
        }
        insert conta;
        return conta;
    }

    @IsTest
    static void deveAtualizarStatusQuandoSemInteracaoHaMaisDeTresDias() {
        Account conta = criarContaComEmailQuandoPossivel();
        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Name = 'Pedido Inativo',
            Cliente__c = conta.Id,
            Prioridade__c = 'Baixa',
            Status__c = 'Novo',
            UltimaInteracao__c = System.now().addDays(-4)
        );
        insert pedido;

        Test.startTest();
        System.enqueueJob(new PedidoSuporteInatividadeQueueable());
        Test.stopTest();

        PedidoSuporte__c pedidoAtualizado = [
            SELECT Id, Status__c
            FROM PedidoSuporte__c
            WHERE Id = :pedido.Id
        ];
        System.assertEquals('Aguardando Cliente', pedidoAtualizado.Status__c);
    }

    @IsTest
    static void naoDeveAtualizarStatusQuandoInteracaoForRecente() {
        Account conta = criarContaComEmailQuandoPossivel();
        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Name = 'Pedido Ativo',
            Cliente__c = conta.Id,
            Prioridade__c = 'Baixa',
            Status__c = 'Novo',
            UltimaInteracao__c = System.now().addDays(-1)
        );
        insert pedido;

        Test.startTest();
        PedidoSuporteInatividadeQueueable.processarPedidosSemInteracao();
        Test.stopTest();

        PedidoSuporte__c pedidoSemMudanca = [
            SELECT Id, Status__c
            FROM PedidoSuporte__c
            WHERE Id = :pedido.Id
        ];
        System.assertEquals('Novo', pedidoSemMudanca.Status__c);
    }

    @IsTest
    static void deveEnviarEmailQuandoCampoEmailDaContaExistir() {
        Map<String, Schema.SObjectField> camposDaConta = Account.SObjectType.getDescribe().fields.getMap();
        if (!camposDaConta.containsKey('Email__c')) {
            System.assert(true, 'Org sem Email__c em Account: teste de envio nao se aplica.');
            return;
        }

        Account conta = criarContaComEmailQuandoPossivel();
        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Name = 'Pedido Com Email',
            Cliente__c = conta.Id,
            Prioridade__c = 'Baixa',
            Status__c = 'Novo',
            UltimaInteracao__c = System.now().addDays(-5)
        );
        insert pedido;

        Integer enviosAntes = Limits.getEmailInvocations();
        PedidoSuporteInatividadeQueueable.processarPedidosSemInteracao();
        Integer enviosDepois = Limits.getEmailInvocations();

        System.assertEquals(enviosAntes + 1, enviosDepois);
    }
}
