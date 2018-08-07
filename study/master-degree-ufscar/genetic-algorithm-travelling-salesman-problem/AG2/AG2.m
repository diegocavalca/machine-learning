%% Iteracoes de teste - gerando dados do relatorio
%for t = 1:10;
%% Fim dos testes pro relatorio

    clear     
    
    % ATENCAO - Antes de executar este arquivo, eh necessario ter executado o arquivo PrepareData.m
    
    % DADOS - Dataset (EIL51.tsp) e matriz de distancias do dataset
    load 'eil51.tsp'
    load 'dist.mat'
    
    % Dimensoes do dataset
    [d,c]=size(dist); 
    
    % PARAMETROS, variaveis e configuracoes gerais
    popSize = 400; % Tamanho da populacao
    numGen = 10000; % Limite de iteracoes das operacoes genetica
    globalMin = Inf; % Melhor (menor) caminho encontrado
    minGen = 0; % Geracao da melhor solucao encontrada
    distHistory = zeros(1,numGen); 
    tmpPop = zeros(4,d); % Populacao temporara (mutacao)
    newPop = zeros(popSize,d); % Populacao dinamica (iterativa)
    totalDist = zeros(popSize,2); % Calculo de distancias

    % INICIO - Gerar populacao inicial
    population = zeros(popSize, d);
    population(1,:) = (1:d);
    for i = 2:popSize;
        population(i,:) = randperm(d,d);
    end
    %save initialpopulation initialpopulation

    % Area de resultados...
    figureBestRoute = figure();

    for iter = 1:numGen

        % FITNESS - Calcular aptidao de cada individuo (caminho) da populacao
        individual = 0;
        for i=1:popSize;
            % Capturar cada individuo da populacao
            individual = population(i,:);

            % Percorrer colunas (pontos) do individuo a fim de totalizar o custo do
            % trajeto
            total = 0;
            for j=2:size(individual,2);
                total = total + dist(individual(1,j),individual(1,j-1));
            end;

            % Calcular o custo de voltar ao ponto 1
            total = total + dist(individual(1,d),individual(1,1));
            % Guardando a aptid�o do indiv�duo
            totalDist(i,:) = [i, total];
        end
        %fitness = sortrows(fitness,2);
        %save fitness fitness

        % Melhor rota calculada na populacao
        [minDist,index] = min(totalDist);
        minDist = minDist(2);
        index = index(2);
        distHistory(iter) = minDist;
        if minDist < globalMin        
            minGen = iter;
            globalMin = minDist;
            optRoute = population(index,:); % Melhor rota da populacao...

            % Plotar a melhor rota atual
            rte = optRoute([1:d 1]);
            plot(rte',rte','r.-'); % Caminho
            plot(eil51(rte,2),eil51(rte,3),'r.-'); % Pontos (cidades)        
            title( {sprintf('Results - Dist. = %1.4f, Gener. = %d',minDist,iter), sprintf('Params - PopSize = %d, NumGen. = %d',popSize,numGen) } );
            drawnow;
        end

        % SELECAO - Metodo de torneio
        % Analisar populacao em busca da melhor rota - sequenciar a busca
        % em grupos de 4 individuos    
        randomOrder = randperm(popSize);
        for p = 4:4:popSize

            % Rota minima (melhor) das 4...
            rtes = population(randomOrder(p-3:p),:);
            dists = totalDist(randomOrder(p-3:p),:);
            [ignore,idx] = min(dists);        
            bestRoute = rtes(idx(2),:);

            % CRUZAMENTO - Conforme discutido no artigo, nao foi utilizada a operacao de Cruzamento 
            % como proposto na forma classica,uma vez que para o problema em questao, conforme 
            % (SERATNA,2010), o algoritmo se mostra mais sensivel a operacoes de mutacao. 
            % Neste sentido, criou-se uma operacao hibrida (CRUZAMENTOxMUTACAO), onde o comportamento 
            % do algoritmo consiste em varrer a populacao inicial, dividindo-a iterativamente em 
            % subconjuntos de 4 individuos. Destes 4, eh separado o melhor (menor distancia) e
            % se aplica operacoes de mutacao nos 3 piores, assumindo estes como
            % novos individuos da populacao.

            % MUTACAO - Alterar a melhor rota para obter 3 novas rotas do subgrupo de 4 individuos
            % atraves de 3 metodos (Flip, Swap e Slide)
            routeInsertionPoints = sort(ceil(d*rand(1,2))); % Pontos de divisao do individuo
            I = routeInsertionPoints(1);
            J = routeInsertionPoints(2);
            for k = 1:4 

                tmpPop(k,:) = bestRoute;
                switch k
                    case 2 % Flip - ordem inversa entre as partes I e J ...
                        tmpPop(k,I:J) = tmpPop(k,J:-1:I);
                    case 3 % Swap - inverte blocos do cromossomo...
                        tmpPop(k,[I J]) = tmpPop(k,[J I]);
                    case 4 % Slide - troca blocos 
                        tmpPop(k,I:J) = tmpPop(k,[I+1:J I]);
                    otherwise % Mantem original (1)
                end

            end
            newPop(p-3:p,:) = tmpPop;
            
        end
        population = newPop;

        disp(strcat('Gen: ',num2str(iter),' - Min. Dist: ',num2str(globalMin)));
    end

    % Plotando o historico
    figureHistory = figure();
    plot(distHistory,'b','LineWidth',2);
    title('History of Generations');
    xlabel('Generation');
    ylabel('Distance');

    %% !!!!! Iteracoes de teste - gerando dados do relatorio !!!!!

    %    % Salvar figuras...
    %    mkdir(sprintf('tests/AG2/Pop%d-Gen%d/',popSize,numGen));
    %    DateString = datestr(datetime('now'));
    %    date = str2num(datestr(now,'ddmm'));
    %    hour = str2num(datestr(now,'HHMM'));
    %    datestr = datestr(now,'ddmm-HHMMSS');
    %    saveas(figureBestRoute,sprintf('tests/AG2/Pop%d-Gen%d/bestRoute-%s.jpg',popSize,numGen,datestr)); % BestRoute
    %    saveas(figureHistory,sprintf('tests/AG2/Pop%d-Gen%d/distHistory-%s.jpg',popSize,numGen,datestr)); % History
    %    
    %    % Salvar dados do teste...
    %    dataSummary = [date hour 2 popSize numGen minGen globalMin];
    %    dlmwrite('tests/Summary.csv', dataSummary, '-append', 'delimiter', ';');
    %
    %    % Variaveis
    %    save(sprintf('tests/AG2/Pop%d-Gen%d/optRoute-%s.mat',popSize,numGen,datestr), 'optRoute');
    %    save(sprintf('tests/AG2/Pop%d-Gen%d/distHistory-%s.mat',popSize,numGen,datestr), 'distHistory');
        
%end;
    %% !!!!! Fim dos testes pro relatorio !!!!!