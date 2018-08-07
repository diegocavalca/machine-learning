clc; 
clear all;
close all;

% Variaveis do problema...
fprintf('Carregando dados e variaveis do sistema... ');
H = 24;

% Tarifa da energia eletrica adotada
global tarifa;
tarifa = repmat(0.35, 1, 25);
tarifa(18:20) = 0.5;

% Dispositivos contemplados 
dispositivos = dispositivos('dispositivos.csv'); % Carregando dados
fprintf('Ok!\n\n');

% do algoritmo...
tamNuvem = 50;             % Quantidade de individuos da nuvem
nIter = 1000;              % Num. de execucoes PSO
c1 = 2.05;                 % c1 = fator da equacao 1a
c2 = c1;                   % c2 = fator da equacao 1a
w = 0.7298;                % Inercia constante (Ref. 13)
wMax = 0.9;                % wMin = coeficiente de exploracao
wMin = 0.4;                % wMax = coeficiente de exploracao

salvarDadosTeste = true;   % Variavel de controle para arquivamento de testes

% Automacao dos testes por tecnica
maxTestes = input('Quantas vezes gostaria de executar o teste? ');

% Escolher qual variacao de PSO (metodo) executar,tal que:
% 0 = PSO_RPwC (Populacao Aleatoria com W Constante)
% 1 = PSO_RPwD (Populacao Aleatoria com W Decrescente --> QUALI!)
% 2 = PSO_RPwD (Populacao Aleatoria com W Adaptativa)
% 3 = PSO_SPwC (Populacao Estocastica com W Constante --> QUALI!)
% 4 = PSO_SPwA (Populacao Estocastica com W Adaptativa)
opcao = input(strcat('Qual PSO deseja executar?\n ', ...
                    ' 0 = PSO_RPwC (Populacao Aleatoria com W Constante)\n', ...
                    ' 1 = PSO_RPwD (Populacao Aleatoria com W Decrescente)\n', ...
                    ' 2 = PSO_RPwA (Populacao Aleatoria com W Adaptativa)\n', ...
                    ' 3 = PSO_SPwD (Populacao Estocastica com W Decrescente)\n', ...
                    ' 4 = PSO_SPwA (Populacao Estocastica com W Adaptativa)\n', ...                    
                    '=> '));
for teste = 1:maxTestes;

    close all;
    disp(strcat('%%%%%%%%%%%%%%%%%%%%%%% TESTE #',num2str(teste),' %%%%%%%%%%%%%%%%%%%%%%%'));
    switch(opcao)
        case 0
            PSO_RPwC(dispositivos, tarifa, H, tamNuvem, nIter, c1, c2, w, salvarDadosTeste);
        case 1
            PSO_RPwD(dispositivos, tarifa, H, tamNuvem, nIter, c1, c2, wMin, wMax, salvarDadosTeste);
        case 2
            PSO_RPwA(dispositivos, tarifa, H, tamNuvem, nIter, c1, c2, wMin, wMax, salvarDadosTeste);
        case 3
            PSO_SPwD(dispositivos, tarifa, H, tamNuvem, nIter, c1, c2, wMin, wMax, salvarDadosTeste);
        case 4
            PSO_SPwA(dispositivos, tarifa, H, tamNuvem, nIter, c1, c2, wMin, wMax, salvarDadosTeste);
        otherwise
            warning('Por favor, selecione uma opcao valida!');
    end;
    pause(0.01);
    
end;
