% %% Iteracoes de teste - gerando dados do relatorio
% for tst = 1:10;
% %% Fim dos testes pro relatorio
    
    clear;
    clc;

    tic;
    
    % ATENCAO - Antes de executar este arquivo, se faz necessario ter executado o arquivo PrepareData.m
    
    % DADOS - Dataset (EIL51.tsp) e matriz de distancias do dataset
    load 'eil51.tsp';
    load 'distances.mat';
    
    % Dimensoes do dataset
    [rows,columns]=size(distances); 
        
    %% Variaveis do PSO (já definido os melhores possíveis, de acordo com o relatório)...
    swarmSize = 30;
    numIter = 10;
    cPr = 0.2;
    w = 0.9; % Fator de inercia 
    alpha = 0.8; % Fator individual - c1
    beta = alpha; % Fator social - c2
    
    X = zeros(swarmSize, rows); % Posicao (Particulas)
    V = cell(1, swarmSize); % Velocidade (Permutacoes)
    gBestScore = inf;
    pBestScore = inf(swarmSize, 1);     

    %% Inicializacao
    % Nuvem aleatoria - Metodo do Vizinho mais Proximo (Goldbarg e Luna, 2005)...
    for i=1:swarmSize;
        X(i,:) = randperm(rows, rows);

        % Avaliacao...
        cost = Fitness(X(i,:), distances);
        if(pBestScore(i)>cost)
            pBestScore(i)=cost;
            pBest(i,:)=X(i,:);
        end
        if(gBestScore>cost)
            gBestScore=cost;
            gBest=X(i,:);
        end;
    end;

    %% Iteracoes...
    for t=1:numIter;
        
        fprintf('\n Iter %d: - gBest: %.2f \n', t, gBestScore);
                
        % Atualizar particulas (velocidade e posicao)...        
        for i=1:swarmSize;

            fprintf('.');
            % Movimento da nuvem... 
            [X(i,:), xCost] = LocalSearch(X(i,:), w, distances); % M1
            [X(i,:), xCost, gBest, gBestScore] = PathRelinking (X(i,:), xCost, gBest, gBestScore, beta, cPr, distances); %gBest - M3
            [X(i,:), xCost, pBest(i,:), pBestScore(i)] = PathRelinking (X(i,:), xCost, pBest(i,:), pBestScore(i), alpha, cPr, distances); %pBest - M2  
            
            % Avaliacao...
            cost = Fitness(X(i,:), distances);
            if(pBestScore(i)>cost)
                pBestScore(i)=cost;
                pBest(i,:)=X(i,:);
            end
            if(gBestScore>cost)
                gBestScore=cost;
                gBest=X(i,:);
            end;
            
        end;
        
        histBest(t) = gBestScore;
        
    end;
    
    % Resultados...
    figureHistory = figure;
    plot(histBest);
    figureBestRoute = figure;
    rte = gBest([1:rows 1]);
    plot(rte',rte','r.-'); % Caminho
    plot(eil51(rte,2),eil51(rte,3),'r.-'); % Pontos (cidades)   
    
    timeExec = toc;
    
%     %% !!!!! Iteracoes de teste - gerando dados do relatorio !!!!!
% 
%        % Salvar figuras...
%        folderResults = sprintf('Results/Iter_%d-Swarm_%d-Cpr_%.2f-W_%.2f-C_%.2f/', numIter, swarmSize, cPr, w, beta);
%        mkdir(folderResults);
%        DateString = datestr(datetime('now'));
%        date = str2num(datestr(now,'ddmm'));
%        hour = str2num(datestr(now,'HHMM'));
%        datestr = datestr(now,'ddmm-HHMMSS');
%        saveas(figureBestRoute, sprintf('%s/bestRoute-COST_%.2f-%s.jpg', folderResults, gBestScore, datestr)); % BestRoute
%        saveas(figureHistory, sprintf('%s/distHistory-COST_%.2f-%s.jpg', folderResults, gBestScore, datestr)); % History
%        
%        % Salvar dados do teste...
%        dataSummary = [date hour numIter swarmSize w alpha beta cPr gBestScore timeExec];
%        dlmwrite('Results/Summary.csv', dataSummary, '-append', 'delimiter', ';');
%     
%        % Variaveis
%        save(sprintf('%s/gBest-%s.mat', folderResults, datestr), 'gBest');
%        save(sprintf('%s/histBest-%s.mat', folderResults, datestr), 'histBest');
%         
% end;
%     %% !!!!! Fim dos testes pro relatorio !!!!!