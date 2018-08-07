function [ p ] = ParticlePosition( R, Mij )

    % Recebe o roteamento (sequencia de maquinas que processam Oij)
    % e retorna o indice de prioridade referente a cada maquina em questao
    % P = particula original (indices prioritarios de maquinas por Oij)
    % Mij = matriz de prioridades de maquinas (colunas) para cada Oij (row)
    n = size(R, 2);
    m = size(R, 1);
    p = zeros(size(R));
    parfor r=1:m;
    %for r=1:m;
        for c=1:n;
            p(r, c) = find( ismember( Mij(c,:), R(r, c) ) );
        end;
    end;
end

