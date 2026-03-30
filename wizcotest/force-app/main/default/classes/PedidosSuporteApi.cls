@RestResource(urlMapping='/pedidos-suporte/*')
global with sharing class PedidosSuporteApi {
    global class CriarPedidoRequest {
        public Id clienteId;
        public String descricao;
        public String prioridade;
    }

    global class CriarPedidoResponse {
        public Id pedidoId;
    }

    @HttpPost
    global static CriarPedidoResponse criarPedido() {
        RestRequest requisicaoHttp = RestContext.request;
        RestResponse respostaHttp = RestContext.response;

        if (requisicaoHttp == null || requisicaoHttp.requestBody == null) {
            return erroBadRequest(respostaHttp, 'Payload obrigatório.');
        }

        CriarPedidoRequest payload;
        try {
            payload = (CriarPedidoRequest) JSON.deserialize(
                requisicaoHttp.requestBody.toString(),
                CriarPedidoRequest.class
            );
        } catch (Exception ex) {
            return erroBadRequest(respostaHttp, 'Payload inválido.');
        }

        if (payload == null || payload.clienteId == null || String.isBlank(payload.descricao) || String.isBlank(payload.prioridade)) {
            return erroBadRequest(respostaHttp, 'Campos obrigatórios: clienteId, descricao, prioridade.');
        }

        PedidoSuporte__c novoPedido = new PedidoSuporte__c(
            Name = 'Pedido ' + String.valueOf(Datetime.now().getTime()),
            Cliente__c = payload.clienteId,
            Descricao__c = payload.descricao,
            Prioridade__c = payload.prioridade,
            Status__c = 'Novo',
            UltimaInteracao__c = System.now()
        );
        insert novoPedido;

        respostaHttp.statusCode = 201;

        CriarPedidoResponse resposta = new CriarPedidoResponse();
        resposta.pedidoId = novoPedido.Id;
        return resposta;
    }

    private static CriarPedidoResponse erroBadRequest(RestResponse respostaHttp, String mensagem) {
        respostaHttp.statusCode = 400;
        respostaHttp.responseBody = Blob.valueOf(
            JSON.serialize(new Map<String, String>{ 'erro' => mensagem })
        );
        return null;
    }
}
