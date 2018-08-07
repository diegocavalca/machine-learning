function [makespan, gantt, gantt_op] = Fitness (M, Times, Oij, m, n)

    % PARAMS:
    % M     = Sequenciamento/Programacao
    % Times = Matriz de tempos
    % Oij   = Matriz de prioridades
    % m     = numero de maquinas (recursos)
    % n     = numeros de jobs

  % Totalizando Operacoes para todos os Jobs
  opsJobs = cumsum(Oij);
  % Quantidade de operacoes de todos os jobs
  maxOps = max(opsJobs);
  
  % Cria um vetor para as os tempos das maquinas e tempos dos jobs, a cada
  % nova atualizacao de tempo eh tomado como base para acrescimo o tempo que
  % for maior, ou o da maquina ou o do job
  
  % Tempo de cada maquina (makespan individual)
  timeByMachine = zeros(1, m);
  
  % Tempos dos jobs...
  jobs = length(Oij);
  timeByJob = cell(1, jobs);
  for i=1:jobs;
    timeByJob{i} = zeros(1, cumsum(Oij(i)));
  end;
  
  % Controles de operacoes (O) e maquinas (M) para alocacao da producao
  stageO = ones(1, n);
  stageM = ones(1, m);
  
  % Demais variaveis auxiliares...
  iterator = 0;
  gantt = zeros(m, maxOps); % Programacao da producao...
  gantt_op = cell(m, maxOps); % Label da programacao...
    
  % Enquanto:
  % NAO analisar todas operacoes (de todos os jobs)
  % E
  % NAO HOUVER deadlock (iterator = 8, ou seja, passou por todas as maquinas mas 
  % nenhuma fez um job)
  while (sum(stageO) < (maxOps+n) && iterator < m);

    iterator = 0;

    % Avaliar maquinas...
    for mach=1:m;

      % Operacoes atribuidas para a maquina 'mach' (Roteamento)
      ops = M{mach};

      % Verificar se a maquina recebe mais operacoes
      if stageM(mach) <= length(ops);

        % Indice da operacao da maquina
        %opIdx = ops(c);           
        opIdx = ops(stageM(mach));

        % Tempo da operacao na maquina...
        time = Times(opIdx, mach);

        % Selecionar job
        job = find(opsJobs >= opIdx, 1, 'first'); 

        % Selecionar operacao - de acordo com os jobs e seus indices
        % (disponivel em opsJobs, caso job > 1)
        if( job > 1)
          op = opIdx - opsJobs(job-1); 
        else
          op = opIdx;        
        end;

        % Verificar se Oij eh factivel para Mi...
        if op==stageO(job);

          % Alocacao para operacao na maquina...
          idxAlloc = find( gantt(mach, :), 1, 'last');
          if isempty( idxAlloc ) 
            idxAlloc = 1;
          else
            idxAlloc = idxAlloc + 1;
          end;
          
          % Tempo do processamento da op. na maq. (maior entre job e maquina - ajuste da programacao)
          timeSchedule = max([timeByMachine(mach) max(timeByJob{job})]);
          
          % Atualiza tempo na programacao...
          gantt(mach, idxAlloc) = timeSchedule;
          
          % Atualiza tempo de processamento: 
          % 1. Na maquina em questao...
          % 2. No acumulado do job, de acordo com a operacao...
          timeByMachine(mach) =  timeSchedule + time;
          timeByJob{job}(op:cumsum(Oij(job))) = timeByMachine(mach);

          % Dados do grafico da programacao (Gantt)
          gantt(mach, idxAlloc+1) = timeByMachine(mach);
          gantt_op{mach, stageM(mach)} = ['O' num2str(job) ',' num2str(op)]; 

          % Atualiza indices de controle...
          stageO(job) = stageO(job) + 1;
          stageM(mach) = stageM(mach)+1;
            
        else
          iterator = iterator + 1;
        end;

      else
        iterator = iterator + 1;
      end;
    
    end;

  end;

  % Se houve DEADLOCK retorna 0 senao o makespan
  if sum(stageO) < (maxOps+n);
      makespan = 0;
  else
      makespan = max(timeByMachine);
  end;
  
%%  schedule = zeros(length(M), 2*length(X));
%%  disp(schedule);
  
%%  % Avaliar operacoes...
%%  opIdx = 1;
%%  for job=1:length(Oij);
%%      for op=1:Oij(job);
%%        
%%        % Maquina atribuida p/ operacao...
%%        machine = X(opIdx);
%%        
%%        % Tempo...
%%        time = Times(opIdx, machine);
%%        fprintf('Op(%d,%d) - M(%d): %d \n', round(job), round(op), round(machine), round(time));
%%        
%%        schedule(machine, opIdx+1) =  schedule(machine, opIdx) + time;
%%        
%%        opIdx = opIdx + 1;
%%        
%%      end;            
%%  end;
%%  
%%  disp(schedule);

%%  for op=1:length(X);
%%    
%%    % Maquina para a operacao...    
%%    machine = X(op);
%%    % Custo para a operacao na maquina...
%%    time = Times(op, machine);
%%    disp(time);
%%    
%%  end;
  
  
  %valor = 0;
  
end
