@IsTest
private class PedidoSuporteTriggerHandlerTest {
    private static PedidoSuporte__c criarPedido(String status, String prioridade) {
        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Name = 'Pedido Teste ' + String.valueOf(Datetime.now().getTime()),
            Status__c = status,
            Prioridade__c = prioridade
        );
        insert pedido;
        return pedido;
    }

    private static void criarInteracaoDeAgente(Id pedidoId) {
        insert new Interacao__c(
            PedidoSuporte__c = pedidoId,
            Tipo__c = 'Agente',
            Data__c = System.now()
        );
    }

    @IsTest
    static void deveBloquearResolucaoAltaSemInteracaoDeAgente() {
        PedidoSuporte__c pedido = criarPedido('Novo', 'Alta');
        pedido.Status__c = 'Resolvido';

        Test.startTest();
        try {
            update pedido;
            System.assert(false, 'A atualizacao deveria ter sido bloqueada.');
        } catch (DmlException ex) {
            System.assert(
                ex.getDmlMessage(0).contains('Pedidos de alta prioridade devem possuir pelo menos uma interação de agente antes de serem resolvidos.'),
                'Mensagem de erro inesperada: ' + ex.getDmlMessage(0)
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void devePermitirResolucaoAltaComInteracaoDeAgente() {
        PedidoSuporte__c pedido = criarPedido('Novo', 'Alta');
        criarInteracaoDeAgente(pedido.Id);

        pedido.Status__c = 'Resolvido';

        Test.startTest();
        update pedido;
        Test.stopTest();

        PedidoSuporte__c pedidoAtualizado = [
            SELECT Id, Status__c
            FROM PedidoSuporte__c
            WHERE Id = :pedido.Id
        ];
        System.assertEquals('Resolvido', pedidoAtualizado.Status__c);
    }

    @IsTest
    static void deveBloquearMudancaDeResolvidoParaCancelado() {
        PedidoSuporte__c pedido = criarPedido('Resolvido', 'Baixa');
        pedido.Status__c = 'Cancelado';

        Test.startTest();
        try {
            update pedido;
            System.assert(false, 'A atualizacao deveria ter sido bloqueada.');
        } catch (DmlException ex) {
            System.assert(
                ex.getDmlMessage(0).contains('Não é permitido cancelar um pedido que já esteja resolvido.'),
                'Mensagem de erro inesperada: ' + ex.getDmlMessage(0)
            );
        }
        Test.stopTest();
    }
}
