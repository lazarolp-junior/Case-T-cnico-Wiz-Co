@IsTest
private class PedidosSuporteApiTest {
    @IsTest
    static void deveCriarPedidoDeSuporteViaApi() {
        Account contaCliente = new Account(Name = 'Cliente API');
        insert contaCliente;

        RestRequest requisicao = new RestRequest();
        requisicao.requestUri = '/services/apexrest/pedidos-suporte';
        requisicao.httpMethod = 'POST';
        requisicao.requestBody = Blob.valueOf(
            '{"clienteId":"' + contaCliente.Id + '","descricao":"Problema no sistema","prioridade":"Alta"}'
        );

        RestResponse resposta = new RestResponse();
        RestContext.request = requisicao;
        RestContext.response = resposta;

        PedidosSuporteApi.CriarPedidoResponse retorno = PedidosSuporteApi.criarPedido();

        System.assertNotEquals(null, retorno);
        System.assertNotEquals(null, retorno.pedidoId);
        System.assertEquals(201, RestContext.response.statusCode);

        PedidoSuporte__c pedidoCriado = [
            SELECT Id, Cliente__c, Descricao__c, Prioridade__c, Status__c, UltimaInteracao__c
            FROM PedidoSuporte__c
            WHERE Id = :retorno.pedidoId
        ];

        System.assertEquals(contaCliente.Id, pedidoCriado.Cliente__c);
        System.assertEquals('Problema no sistema', pedidoCriado.Descricao__c);
        System.assertEquals('Alta', pedidoCriado.Prioridade__c);
        System.assertEquals('Novo', pedidoCriado.Status__c);
        System.assertNotEquals(null, pedidoCriado.UltimaInteracao__c);
    }

    @IsTest
    static void deveRetornarBadRequestQuandoPayloadInvalido() {
        RestRequest requisicao = new RestRequest();
        requisicao.requestUri = '/services/apexrest/pedidos-suporte';
        requisicao.httpMethod = 'POST';
        requisicao.requestBody = Blob.valueOf('{"descricao":"sem cliente"}');

        RestResponse resposta = new RestResponse();
        RestContext.request = requisicao;
        RestContext.response = resposta;

        PedidosSuporteApi.CriarPedidoResponse retorno = PedidosSuporteApi.criarPedido();

        System.assertEquals(null, retorno);
        System.assertEquals(400, RestContext.response.statusCode);
    }
}
