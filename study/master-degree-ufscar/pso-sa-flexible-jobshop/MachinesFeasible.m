function [ machines, priorities ] = MachinesFeasible( op, totalMachines, Tij, Mij, numDiscards )

    % Maquinas factives para operacao Oij (tempo > 0)
    fMach = find(Tij);
    
    % OLD MODE
    %machinesOp = fMach(randi(numel(fMach), swarmSize, 1));
    
    % Maquinas factiveis na ordem de melhor >> pior
    machinesOp = Mij(op, ismember(Mij(op, :), fMach));
    
    % Estocastico = eliminar ultima maquina (mais lenta pra Oij) e atribuir
    % maquina de maneira que todas tenham mesma probabilidade
    machinesOp = machinesOp(1:length(machinesOp)-numDiscards);
    
    %%% priorities = zeros(size(machinesOp));
    %%% % Indices de prioridade das maquinas factives
    %%% [~, priorities] = ismember(machines, Mij(op, :));

    probs = ones(1, length(machinesOp))*1/length(machinesOp);
    
    % Maquinas factiveis resultantes
    machines = randsample(machinesOp, totalMachines, true, probs);
    % Indices de prioridade das maquinas factives
    [~, priorities] = ismember(machines, Mij(op, :));
end

