function [pScheduling] = Scheduler (Planning, mSize)

    global Oij;
    
    % Organizar planejamento para as operacoes
    pScheduling = cell(1, mSize);
    for mach=1:mSize;
      % Operacoes Oij (indices em X) atribuidas para a Maquina Mj em Xi
      pScheduling{mach} = find( Planning == mach );
    end;  
        
    m = mSize;
    k = pScheduling;
    
    encode_ini = cell(1,m);
    preced = cell(m,gather(max(Oij)));
    for i=1:m  
        v = k{i};
        for j=1:length(v)
            aux = v(j) <= cumsum(Oij);
            job = find(aux==1,1,'first');
            if job > 1
              operacao = v(j) - max(cumsum(Oij(1:job-1)));
            else
              operacao = v(j);
            end
            preced{i,operacao} = [preced{i,operacao} v(j)];
        end
    end
    for i=1:m  
        for j=1:max(Oij)
            h = preced{i,j};
            encode_ini{i} = [encode_ini{i} h(randperm(length(h)))];
        end
    end
    
    pScheduling = encode_ini;
    
    

end
