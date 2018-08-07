function PSO(Tij, Oij, Mij, n, m, jobs, nIter, swarmSize, wMax, wMin, c1, c2, discardMachines, t0, tEnd, B, nIterTemp);
    % PARAMETROS DO METODO 'PSO':
    % 
    
    tic;

    % Nuvem (populacao) e solucao inicial
    X = zeros(swarmSize, n);
    M = cell(swarmSize, m);
    P = X;

    % Variaveis objetivo
    % Local
    pBestX = zeros(swarmSize, n);
    pBestM = M;
    pBestCost = Inf(1, swarmSize);
    % Global
    gBestX = zeros(1, n);
    gBestM = cell(1,m);
    gBestCost = Inf;

    % Variaveis adicionais
    Sol = zeros(1, n);         % Controle de estagnacao
    histBest = zeros(1, nIter); % Historico de iteracoes
    v = ones(swarmSize, n);     % Velocidade da equacao 1a (PSO) 

    % ROTEAMENTO - Gerar populacao do enxame (roteamentos)
    fprintf('Gerando populacao inicial... \n');
    for i=1:n;
        % Maquinas factiveis na ordem de melhor >> pior, 
        [machines, priorities] = MachinesFeasible(i, swarmSize, Tij(i, :), Mij, discardMachines);
        X(:, i) = machines;
        P(:, i) = priorities;
    end;

    % AVALIACAO INICIAL dos individuos
    fprintf('Avaliacao da populacao inicial');
    for i=1:swarmSize;

        % Simulated Annealing (Avaliacao da particula otimizada pelo SA)
        [M(i,:), makespan, X(i, :), ~] = SA(X(i, :), @Scheduler, @Fitness, @Neighbor);

        % FITNESS
        pBestCost(i) = makespan;
        pBestX(i, :) = X(i, :);
        pBestM(i, :) = M(i, :);

        % Solucoes ja encontradas
        P(i, :) = ParticlePosition(X(i, :), Mij);

        fprintf('.');

    end;

    % Melhor global (inicial)
    [gBestCost, idx] = min(pBestCost);
    gBestX = pBestX(idx, :);
    gBestM = pBestM(idx, :);
    fprintf(' \nMelhor inicial: %.0f... \n', gBestCost);

    % PASSO 3 - Execução do PSO iterativamente
    fprintf('Aplicando PSO... \n');
    for iter=1:nIter;

        % Insere particulas no registro de solucoes
        Sol = [Sol; P];

        % Movimento da nuvem (Exploracao Global, XIA;WU)...
        w = wMax - ( (wMax - wMin)/nIter ) * iter;

        % COeficientes aleatorios (1a)
        r1 = rand(swarmSize, 1);
        r2 = rand(swarmSize, 1);
      
        % Elementos particulares da equacao 1a
        x = P;
        pBest = ParticlePosition(pBestX, Mij);
        gBest = ParticlePosition(gBestX, Mij);

        % Velocidade (Equacao 1a)
        v = w*v + c1 * bsxfun(@times, r1, pBest - x) + c2 * bsxfun(@times, r2, (bsxfun(@minus, gBest, x)));

        % Posicao (Equacao 1b)
        x = round(x + v);

        % Validar vMin e vMax
        for i=1:n;

          % Maquinas factives (3 melhores)
          fMach = find(Tij(i, :));% Maquinas factives para operacao Oij (tempo > 0)
          machinesOp = Mij(i, ismember(Mij(i, :), fMach));% Maquinas factiveis na ordem de melhor >> pior
          machinesOp = machinesOp(1:length(machinesOp)-discardMachines);
          [~, priorities] = ismember(machinesOp, Mij(i, :));

          vMin = priorities(1);
          vMax = priorities(end);

          x_aux = x(:, i);
          x_aux(x_aux < vMin) = vMin;
          x_aux(x_aux > vMax) = vMax;
          x(:, i) = x_aux;    

            % Operacoes que n possuem maquinas factiveis...
            wrongOps = find(~ismember(x(:,i),Mij(i,:)));
            for w=1:length(wrongOps)
                % Atribuindo uma maquina (rand) factivel para a operacao em questao
                idx = randi([1 vMax],1,1); % PODE MELHORAR COM ROLETA
                x(wrongOps(w), i) = machinesOp(idx);
                %wrongOps(w) = machinesOp(randi([1 totalMach],1,1));
            end;

        end;

        % CONROLE ANTIESTAGNACAO - Verificar se ja faz parte do conjunto solucao
        idxRep = find(ismember(x, Sol, 'rows'));
        while ~isempty(idxRep); % Enquanto as solucoes geradas estiverem no conjunto Sol

            countRep = length(idxRep); % total de solucoes repetidas

            % Para cada solucao repetida, atribuir novo valor de nivel para um
            % operacao escolhida aleatoriamente
            for c=1:countRep;
                % Selecionar aleatoriamento uma operacao da nuvem
                randOp = randi([1 n],1,1);

                % Atribuir novas Maquinas factiveis para a operacao i, na ordem de melhor >> pior, 
                [machines, priorities] = MachinesFeasible(randOp, 1, Tij(randOp, :), Mij, discardMachines);
                x(idxRep(c), randOp) = priorities;
            end;

            % Validar repeticao novamente
            idxRep = find(ismember(x, Sol, 'rows'));

        end;

        % Gerando (convertendo) particulas de operacao
        P = x;
        X = ParticleOperation(x,Mij);  

        % Avaliar particulas
        for i=1:swarmSize;

            % Simulated Annealing (Avaliacao da particula)
            [M(i,:), makespan, X(i, :), ~] = SA(X(i, :), @Scheduler, @Fitness, @Neighbor);

            % FITNESS    
            if(makespan < pBestCost(i));
                % Melhor local
                pBestCost(i) = makespan;
                pBestX(i, :) = X(i, :);
                pBestM(i, :) = M(i, :);
            end;

        end;

        % Melhor global (iteracao)
        [gBestCost, idx] = min(pBestCost);
        gBestX = pBestX(idx, :);
        gBestM = pBestM(idx, :);

        histBest(iter) = gBestCost;

        fprintf('Completed: %d/%d (gBest: %d)...\n', iter, nIter, gBestCost);

    end;

    % Resultados (graficos)...
    fprintf('Plotando grafico..');
    figureHistory = figure();
    plot(histBest); 
    [makespan, schedule, scheduleOpsLabels] = Fitness(gBestM, Tij, Oij, m, n);
    figureBest = figure();
    Gantt(schedule, scheduleOpsLabels, makespan, m);
    fprintf('. Ok!\n');

    toc;
end

