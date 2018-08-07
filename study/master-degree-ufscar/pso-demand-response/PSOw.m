tic;
clc;
close all;
clear all;

% PSO ponderado pelo fator de inercia adaptativo (reducao linear)

%%%%%%%%%% DADOS DE VILA %%%%%%%%%%
% Tarifa branca
global tarifa;
tarifa = repmat(0.35, 1, 25);
tarifa(18:20) = 0.5;
% Horario de taxa elevada
global pico;
pico = find(tarifa == max(tarifa));

% Dispositivos contemplados 
fprintf('Carregando dados dos dispositivos...\n');
dispositivos = dispositivos('dispositivos.csv'); % Carregando dados
%dispositivos = dispositivos(1:40,:);

% VARIAVEIS
fprintf('Definindo variaveis do sistema...\n');
%(PROBLEMA)
H = 24;
totalDisps = size(dispositivos,1);
tamIndividuo = totalDisps * 24;  % Tamanho individuo (agendamento)

%(PSO)
tamNuvem = 50;                          % Quantidade de individuos da nuvem
nIter = 1000;                           % Num. de execucoes PSO
c1 = 2.05;                                % cX = fatores da equacao 1a
c2 = c1;
wMax = 0.9;                            % wMin/wMax = coeficiente de exploracao
wMin = 0.4;

v = zeros(tamNuvem, tamIndividuo);      % Velocidade, equacao 1a
% Controle de Posicao da particula
xMax = bsxfun(@times, ones(tamNuvem, tamIndividuo), ...
    reshape(bsxfun(@times, ones(totalDisps, 24), dispositivos.PotMaxima)',1,[])/1000);
xMin = bsxfun(@times, ones(tamNuvem, tamIndividuo), ...
    reshape(bsxfun(@times, ones(totalDisps, 24), dispositivos.PotMinima)',1,[])/1000);
% Controle de Velocidade (x% da diferenca entre Max e Min), 
% Fonte: https://www.researchgate.net/post/How_do_I_set_maximum_and_minimum_velocity_value_in_a_PSO_algorithm
vMax = .2 * (xMax - xMin);
vMin = -vMax;

nuvem = zeros(tamNuvem, tamIndividuo); % (PSO) Nuvem de individuos (SPAVIERI 2016)
gBest = zeros(1, tamIndividuo);        % Melhor agendamento Global
gBestData = cell(1, 9);                % Detalhes sobre gBest (cDiario, perfil, consPotencia, consValor)
gBestData{1, 1} = Inf;
pBest = zeros(tamNuvem, tamIndividuo); % Melhor agendamento Individual
pBestData = cell(tamNuvem, 4);         % Detalhes sobre pBest (cDiario, perfil, consPotencia, consValor)
[pBestData{1:tamNuvem, 1}] = deal(Inf);

histBest = zeros(1, nIter);            % Historico de convergencia

% Gerando nuvem (vetor de planejamento / dispositivo)
fprintf('Inicializando nuvem de individuos: ');
for i = 1:tamNuvem;
    % Transformando vetor em matriz (mapear planejamento)
    planejamento = zeros(totalDisps,24);%reshape(nuvem(i,:),[24,totalDisps])';
    
    % Produzir vetor de consumo para cada dispositivo
    for d = 1:totalDisps;        
        planejamento(d, :) = planoConsumoDispositivo(dispositivos(d, :), 'estocastico', 24);
    end;
    
    % Atribuindo vetor de planejamento dos dispositivos na nuvem
    nuvem(i, :) = reshape(planejamento',1,[]);
    fprintf('|');
end;

fprintf('\nIniciando algoritmo de otimizacao...\n');
% Otimizando PSO
for iter=1:nIter;
    
    % Avaliar o fitness do individuo (nuvem)
    %planejamento = nuvem(n, :);
    for n = 1:tamNuvem;
        [ fitness, consPotLiquido, consPotBruto, consValor, ...
            vrTotal, consMaximo, consMedio, consPico, PAR ] ...
         = custo(nuvem(n, :), dispositivos, tarifa);
        
        %[cDiario, consPotencia, consPotBruto, ... 
        %    consValor, vrTotal, PAR] = custo(nuvem(n, :), dispositivos, tarifa);
        % Validando pBest (INDIVIDUAL)
        if( fitness < pBestData{i, 1});
            pBest(i, :) = nuvem(n, :);
            %%% Dados do pBest Agendamento
            pBestData{i, 1} = fitness;     
            %pBestData{i, 2} = perfil;
            %pBestData{i, 3} = consPotencia;
            %pBestData{i, 4} = consValor;
        end;
        % Validando gBest (GLOBAL)
        if( fitness < gBestData{1});
            gBest = nuvem(n, :);
            % Dados do gBest Agendamento
            gBestData = { fitness, consPotLiquido, consPotBruto, consValor, ...
                         vrTotal, consMaximo, consMedio, consPico, PAR };
        end;
    end;
    
    % Obs.: nuvem = x, Equacoes 1a e 1b;
    x = nuvem;
    
    % Movimento da nuvem (Exploracao Global, XIA;WU)...
    w = wMax - ( (wMax - wMin)/nIter ) * iter;

    % Atualizacao da velocidade - Eq 1a
    v = w*v + ...
        c1 * bsxfun(@times, rand(tamNuvem, tamIndividuo), pBest - x) + ... 
        c2 * bsxfun(@times, rand(tamNuvem, tamIndividuo), (bsxfun(@minus, gBest, x)));
    % Controlar a velocidade
    foraLimites = bsxfun(@gt, v, vMax);
    v(foraLimites) = vMax(foraLimites);
    foraLimites = bsxfun(@lt, v, vMin);
    v(foraLimites) = vMin(foraLimites);
    
    % Atualizacao da posicao - Eq 1b
    x = x + v;
    % Controle da posicao
    foraLimites = bsxfun(@gt, x, xMax);
    x(foraLimites) = xMax(foraLimites);
    v(foraLimites) = 0;
    foraLimites = bsxfun(@lt, x, xMin);
    x(foraLimites) = xMin(foraLimites);
    v(foraLimites) = 0;
    
    % Atualizando nuvem corrente
    nuvem = x;
    
    % VALIDAR consumo (dentro planejamento consumo estabelecido)
    % e AVALIAR fitness dos individuos (nuvem)
    for n = 1:tamNuvem;
        % Gerar matrix de consumo, com base no individuo
        planejamento = reshape(nuvem(n,:),[24,totalDisps])';
        
        % % 1. VERIFICANDO VALORES NEGATIVOS
        %[v_negativos, ~] = find(planejamento < 0);
        %if(~isempty(v_negativos));
        %    v_negativos = unique(v_negativos);
        %    % Gerando novos vetores de planejamento (consumo) para os disps
        %    % que possuem valores de consumo negativos
        %    for d = 1:length(v_negativos);
        %        idxDisp = v_negativos(d);
        %        planejamento(idxDisp, :) = planoConsumoDispositivo(dispositivos(idxDisp, :), 24);
        %    end;
        %    % Atribuindo vetor de planejamento dos dispositivos na nuvem
        %    nuvem(n, :) = reshape(planejamento',1,[]);
        %end;
        
        % 2. VERIFICANDO FORA DOS LIMITES
        % Totalizando o consumo por dispositivo
        consPlanejado = sum(planejamento,2);
        % Verificar se algum dispositivo esta com consumo errado (fora limite)  
        %[~,fora_limite] = setdiff(round(consPlanejado,3),round(dispositivos.ConsPlanejado,3));
        fora_limite = find(round(consPlanejado,3) ~= round(dispositivos.ConsPlanejado,3));
        if(~isempty(fora_limite));
            % Gerando novos vetores de planejamento (consumo) para os disps
            % que possuem valores fora do limite planejado
            for d = 1:length(fora_limite);
                idxDisp = fora_limite(d);
                planejamento(idxDisp, :) = planoConsumoDispositivo(dispositivos(idxDisp, :), 'estocastico', 24);
            end;

            % Atribuindo vetor de planejamento dos dispositivos na nuvem
            nuvem(n, :) = reshape(planejamento',1,[]);
            v(n, :) = zeros(1, tamIndividuo);
        end; 

     end;
    
    histBest(iter) = gBestData{1};

    fprintf('Completed: %d/%d (gBest: Fit_%.4f, VR_%.4f, CMAX_%.4f, CMED_%.4f, CPICO_%.4f, PAR_%.4f)...\n', ...
                iter, nIter, gBestData{1}, gBestData{5}, gBestData{6}, gBestData{7}, gBestData{8}, gBestData{9});
    %fprintf('Completed: %d/%d (gBest: %.4f)...\n', iter, nIter, gBestData{1});
    
    % Plotar evolucao da nuvem, pBest e gBest
    if gBestData{1} < Inf;
        
        % Convergencia
        subplot(3,3,[1;4;7]);
        plot(histBest);
        xlim([1, nIter]);
        title('Convergencia do Algoritmo');
        xlabel('Iteracao');
        ylabel('Fitness');
        grid on;
        
        % gBest
        subplot(3,3,[2 3 5 6 8 9]);
        planning = reshape(gBest,[H, totalDisps])';
        surf(planning);
        view(2);
        colorbar;
        xlim([1, H]);
        set(gca,'XTick',1:1:H);
        ylim([1, totalDisps]);
        set(gca,'YTick',1:1:totalDisps);
        title('Melhor agendamento global');
        hold on;
        % Delimitar horario de pico
        plot([min(pico) min(pico)],[0 totalDisps], 'Color', 'r'); % Inicio 
        plot([max(pico) max(pico)],[0 totalDisps], 'Color', 'r'); % Fim 
        hold off;
        
        pause(0.0000000001);
    end;
end;

%%%%%%%%%% RESULTADO FINAL E GRAFICOS %%%%%%%%%%
fprintf('Melhor custo global: %.4f!\n',gBestData{1});
fprintf('Sumarizando resultados...\n');

% Agendamento de REFERENCIA
agendamentoRef = dispositivos.Ideal';
%[18,18,17,6,18,8,8,18,10,10,10,6,10,10,6,6,6,10,6,6,20,10,1,18,8,10,8,8,10,8,8,8,8,8,8,8,1,10,10,10];

% Exibir resultados
resultados(gBest, gBestData, agendamentoRef, tarifa, dispositivos, histBest);

timeExec = toc;
%%%%%%%% FIM RESULTADO FINAL E GRAFICOS %%%%%%%%

% Salvar dados do teste
salvarDadosTeste = false;
if (salvarDadosTeste);
    fprintf('Salvando dados do experimento...\n');
    diretorio = 'Tests';
    X = length(dir(diretorio)) - 3;
    arquivo = strcat(num2str(X),'. Dados_fit_',num2str(gBestData{1}),'_vr_',num2str(gBestData{5}),'_PAR_',num2str(gBestData{6}),'.mat');
    save(strcat(diretorio, '/', arquivo));
    % Salvando figuras
    diretorio = [diretorio '/' num2str(X)];
    mkdir(diretorio); % Criar diretorio de imagens para o teste
    figlist=findobj('type','figure');
    for i=1:numel(figlist)
        saveas(figlist(i), fullfile(diretorio, ['Figura_' num2str(i) '.jpg']));
    end
    %disp(timeExec);

    % Coletando dados de teste para o relatorio...
    % ID;METODO;NUM_ITERACOES;TAM_NUVEM;C1;C2;WMIN;WMAX;FITNESS;VR_CONSUMO;PAR;TIME
    dadosTeste = [X 'POPEST-WDESC' nIter tamNuvem c1 c2 wMin wMax gBestData{1} gBestData{5} gBestData{6} timeExec];
    dlmwrite(strcat(diretorio, '/Report.csv'), dadosTeste, '-append', 'delimiter', ';');

end;

fprintf('Fim.\n');