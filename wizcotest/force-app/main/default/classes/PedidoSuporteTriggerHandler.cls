public with sharing class PedidoSuporteTriggerHandler {
    private static final String PRIORIDADE_ALTA = 'Alta';
    private static final String TIPO_INTERACAO_AGENTE = 'Agente';

    public static void validarRegrasDeNegocio(
        List<PedidoSuporte__c> pedidosNovos,
        Map<Id, PedidoSuporte__c> pedidosAntigosPorId
    ) {
        Set<Id> idsPedidosAltaParaValidarInteracao = new Set<Id>();

        for (PedidoSuporte__c pedidoNovo : pedidosNovos) {
            PedidoSuporte__c pedidoAntigo = pedidosAntigosPorId.get(pedidoNovo.Id);
            if (pedidoAntigo == null || pedidoNovo.Status__c == pedidoAntigo.Status__c) {
                continue;
            }

            if (pedidoAntigo.Status__c == 'Resolvido' && pedidoNovo.Status__c == 'Cancelado') {
                pedidoNovo.addError('Não é permitido cancelar um pedido que já esteja resolvido.');
                continue;
            }

            if (pedidoNovo.Prioridade__c == PRIORIDADE_ALTA && pedidoNovo.Status__c == 'Resolvido') {
                idsPedidosAltaParaValidarInteracao.add(pedidoNovo.Id);
            }
        }

        if (idsPedidosAltaParaValidarInteracao.isEmpty()) {
            return;
        }

        Set<Id> idsPedidosComInteracaoAgente = new Set<Id>();
        for (AggregateResult resultado : [
            SELECT PedidoSuporte__c pedidoId, COUNT(Id) totalInteracoes
            FROM Interacao__c
            WHERE PedidoSuporte__c IN :idsPedidosAltaParaValidarInteracao
            AND Tipo__c = :TIPO_INTERACAO_AGENTE
            GROUP BY PedidoSuporte__c
        ]) {
            idsPedidosComInteracaoAgente.add((Id) resultado.get('pedidoId'));
        }

        for (PedidoSuporte__c pedidoNovo : pedidosNovos) {
            if (
                idsPedidosAltaParaValidarInteracao.contains(pedidoNovo.Id) &&
                !idsPedidosComInteracaoAgente.contains(pedidoNovo.Id)
            ) {
                pedidoNovo.addError('Pedidos de alta prioridade devem possuir pelo menos uma interação de agente antes de serem resolvidos.');
            }
        }
    }
}
