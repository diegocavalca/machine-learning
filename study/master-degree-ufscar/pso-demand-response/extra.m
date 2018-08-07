%%%%%%%%%% VALIDAR PLANEJAMENTO GERADO - gBest %%%%%%%%%%
planejamento = reshape(gBest,[24,totalDisps])';

% Pegar horarios planejados
plano_horario = {};
for i = 1:totalDisps;
    plano_horario{i} = find(planejamento(i,:) > 0);
end;

% Confirma se os horarios planejados estao na faixa factivel estipulada
% 1 = errado
% 0 = certo
valida_plano = [];
for i = 1:totalDisps;
    if(ismember(plano_horario{i},dispositivos.Inicio(i):dispositivos.Fim(i)-1));
        valida_plano = [valida_plano; 0];
    else
        valida_plano = [valida_plano; 1];
    end;
end;

% Resultado
errados = find(valida_plano > 0);
plano_errados = zeros(length(errados), 25);
plano_errados(:, 1) = find(valida_plano > 0);
plano_errados(:, 2:25) = planejamento(errados,:);
plotAgendamento(plano_errados(:,2:25), dispositivos(errados,:), 'Agendamento Errados', 5);

%%%%%%%%%% VALIDAR PLANEJAMENTO GERADO - gBest %%%%%%%%%%