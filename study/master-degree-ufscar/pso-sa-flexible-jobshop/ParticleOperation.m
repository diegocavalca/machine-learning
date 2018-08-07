function [ m ] = ParticleOperation(P, Mij)
    
    % Recebe o roteamento (sequencia de indices prioritarios de maquinas que processam Oij)
    % e retorna as maquinas em questao
    % R = particula original (maquinas por Oij)
    % Mij = matriz de prioridades de maquinas (colunas) para cada Oij (row)
    n = size(P, 2);
    m = zeros(size(P));
    parfor i=1:n;
    %for i=1:n;
        prioritiesOp = P(:,i);
        machinesOp = Mij(i,:);
        m(:,i) = machinesOp(prioritiesOp);
    end;
end

