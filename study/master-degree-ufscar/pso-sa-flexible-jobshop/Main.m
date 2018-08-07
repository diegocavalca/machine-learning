clc; 
clear all;

% DATASET FJSP
dataset = '8x8'; % ALTERAR DATASET PRA TESTAR EM DIFERENTES CONJUNTOS (4x5, 8x8, 10x10 ou 15x10)

% Importando dados do benchmark
global Tij;
global Oij;

Tij = importdata(sprintf('benchmarks/tempos%s.txt', dataset)); % Tempos das operacoes
Oij = importdata(sprintf('benchmarks/op%s.txt', dataset)); % Operacoes por job

% ORGANIZANDO MAQUINAS - Melhores tempos tem prioridade 1, maior tem
% prioridade M, sendo M > 0, senao a maquina M nao eh factivel para Oij
global Mij;
Mij = MachinesPrior(Tij);

% Variaveis do problema
global n; % Relacao completa de JobxOperacoes
global m; % Numero de Maquinas
[n,m] = size(Tij);

global jobs; % Numero de Jobs
jobs = size(Oij, 2);

% SA - Heuristica Explotacao (Programacao)
global t0;          % Temp. Inicial
global tEnd;        % Temp. final
global B;           % Fator de resfriamento (alpha)
global nIterTemp;   % Iter. por temp.

% Configuracoes personalizadas de acordo DATASET
validConfig = true;
switch dataset
    case {'4x5', '8x8'} 
        % SA
        t0 = 3;
        tEnd = 0.01;
        B = 0.9;  
        
        % PSO - Iteracoes / Populacao (Tam. Enxame)
        if strcmp(dataset,'8x8');
            nIter     = 30;
            swarmSize = 50; 
            nIterTemp = 20; % SA
        else
            nIter     = 15;
            swarmSize = 15; 
            nIterTemp = 10; % SA
        end;
        
    case '10x10'
        % SA - Heuristica Explotacao (Programacao)
        t0 = 5;
        tEnd = 0.01;
        B = 0.9;  
        nIterTemp = 20;
        
        % PSO - Iteracoes / Populacao (Tam. Enxame)
        nIter     = 30;
        swarmSize = 50; 
        
    case '15x10'
        % SA - Heuristica Explotacao (Programacao)
        t0 = 10;
        tEnd = 0.01;
        B = 0.95;  
        nIterTemp = 20;
        
        % PSO - Iteracoes / Populacao (Tam. Enxame)
        nIter     = 15;
        swarmSize = 100; 

    otherwise
        warning('Por favor, selecione um dataset valido!');
        validConfig = false;
end;

% PSO - demais configuracoes
wMax      = 1.2;
wMin      = 0.4;
c1        = 2;
c2        = c1;

% Maquinas descartadas (piores) para geracao de solucao 
% (apenas X melhores niveis)
if m > 5 ;
    if isempty(find(Tij == 0));
       discardMachines = m-3;     % Todas maquinas factiveis
    else
       discardMachines = (m-1)-3; % Pelo menos uma NAO FACT.
    end;  
else
    discardMachines = 0;
end;

% Se configuracoes forem validadas, executa PSO
if validConfig;
    PSO(Tij, Oij, Mij, n, m, jobs, nIter, swarmSize, wMax, wMin, c1, c2, discardMachines, t0, tEnd, B, nIterTemp);
end;
