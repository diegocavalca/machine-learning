function [S] = Neighbor(S, m)
    
%     %%%%% SWAP DE TODOS-PARES DE OPERACAO %%%%%
%     % Escolhe uma maquina aleatoria
%     idxMach = randi([1, m], 1);
%     machine = S{idxMach};    
%     % Validacao da maquina - Se possui mais de 2 operações para dar swap
%     while length(machine) < 2
%         idxMach = randi([1, m], 1);
%         machine = S{idxMach};
%     end;    
%     for i=2:length(machine);
%         machine([i-1 i]) = machine([i i-1]);
%     end;
%     S{idxMach} = machine;
%     %%%%% SWAP DE TODOS-PARES DE OPERACAO %%%%%
    
    %%%%% SWAP DE 1-PAR OPERACAO %%%%%
    % Escolhe uma maquina aleatoria
    idxMach = randi([1, m], 1);
    machine = S{idxMach};
    
    % Validacao da maquina - Se possui mais de 2 operações para dar swap
    while length(machine) < 2
        idxMach = randi([1, m], 1);
        machine = S{idxMach};
    end;
    
    % Escolhe uma operacao (indice) para ser a base do swap
    idxSwap = randi([1, length(machine)], 1);
    vlSwap = machine(idxSwap);
    
    % Se a base do swap for:
    % 1. A ultima operacao da maquina, 
    % 2. Demais, troca com a proxima
    if idxSwap == length(machine);
        machine(idxSwap) = machine(idxSwap-1);
        machine(idxSwap-1) = vlSwap;
    else
        machine(idxSwap) = machine(idxSwap+1);
        machine(idxSwap+1) = vlSwap;
    end;
    
    S{idxMach} = machine;
    %%%%% SWAP DE 1-PAR OPERACAO %%%%%

    
end

% function [R, O] = ExtractParticle(M)
%     global n;
%     R = zeros(1, n);
%     O = R;
%     for i=1:size(M,2);
%         for j=1:size(M{i}, 2);
%             R(M{i}(j)) = i;
%             O(M{i}(j)) = j;
%         end;
%     end;
% end
% 
% function cP = CriticalPath(M)
% 
%     for m=1:length(M);
%         totalTime = 0;
%         machine = M{m};
%         for opIdx=1:length(machine);
%             op = machine(opIdx);
%             totalTime = totalTime + Tij(op, m);
%         end;
%         solucoes(m) = totalTime;
%     end;
%     %calculo do CP
%     %primeiro passo é pegar quais sao as operações que atingiram o limite
%     %de maior tempo (makespan), selecionar 1 de forma aleatória, colocar numa
%     %fila de processamento (queue)dando a variável distancia o valor do makespan
%     queue = cell(1);    
%     jobs_maior_tempo = find(cellfun(@max, solucoes_job) == max(solucoes));
%     jobs_maior_tempo = jobs_maior_tempo(randi(length(jobs_maior_tempo)));
%     queue{1} = max(cumsum(Oij(1:jobs_maior_tempo)));
%     
%     distancia = zeros(1,1);
% 	distancia(:) = max(solucoes);
%     
%     %começar a iterar negativamente até a primeira operação definindo assim
%     %os CP's
%     i = 1;
%     %enquanto nao acabar de processar a fila
%     while i <= length(queue{1})
%        
%         %acha qual a máquina que processa a operação corrente que está no critical
%         %path, checa qual seu tempo de processamento e faz distancia -
%         %tempo = nova distancia da proxima operação do CP
%         machine = cellfun(@(x) x==queue{1}(i),k,'Un',0);
%         [~, machine] = find(cellfun(@(x) any(x(:)),machine));
%         tempo_op = tempo_jobs(queue{1}(i),machine);
%         distancia(i) = distancia(i) - tempo_op;
%         
%         
%         %checagem para saber se já foi verificado o critical path para as
%         %operações que terminar no tempo da distancia corrente
%         if find(distancia(i) == distancia(1:i-1))
%             resposta = 0;
%         else
%             resposta = 1;
%         end
%         
%         %aqui novamente pega uma operação aleatória que está na distancia corrente -
%         %tempo de processamento de um operação anterior, essa operação
%         %também estará no CP
%         if i == 1 || resposta && distancia(i) ~= 0
%             [jobs_maior_tempo] = cellfun(@(x) x==distancia(i),solucoes_job,'Un',0);
%             [~, jobs_maior_tempo] = find(cellfun(@(x) any(x(:)),jobs_maior_tempo));        
%             jobs_maior_tempo = jobs_maior_tempo(randi(length(jobs_maior_tempo)));
%         
% 
%             if jobs_maior_tempo == 1
%                 operacao_sequencial = find(solucoes_job{jobs_maior_tempo} == distancia(i));
%             else
%                 operacao_sequencial = max(cumsum(Oij(1:jobs_maior_tempo-1))) + find(solucoes_job{jobs_maior_tempo} == distancia(i));            
%             end  
%             
%             %atualiza a fila e a distancia
%             queue{1} = [queue{1} operacao_sequencial];
%             distancia = [distancia distancia(i)];     
%         end        
%         i = i +1;
%     end
% end