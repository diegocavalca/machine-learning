clear 

% DADOS - Dataset (EIL51.tsp) e matriz de distancias do dataset
load 'eil51.tsp'
load 'dist.mat'
[d,c]=size(dist); % Dimensoes do dataset

% PARAMETROS, variáveis e configurações gerais
popSize = 10000; % Tamanho da populacao
numIter = 200; % Limite de iteracoes das operações genética
n_cities = c; % Número de cidades
globalMin = Inf; % Melhor (menor) caminho encontrado
distHistory = zeros(1,numIter); 
newPop = zeros(popSize,d);
popFilhos = zeros(popSize,d);
totalDist = zeros(popSize,2); % Calculo de distancias

% INICIO - Gerar populacao inicial
population = zeros(popSize, d);
population(1,:) = (1:d);
for i = 2:popSize;
    population(i,:) = randperm(d,d);
end
%save initialpopulation initialpopulation

% Área de resultados...
%figure('Name','TSP Resolution | Current Best Solution','Numbertitle','off');
%hAx = gca;

for iter = 1:numIter
    clear totalDist;
    % FITNESS - Calcular aptidao de cada individuo (caminho) da populacao
    totalDist = fitness(population, popSize, dist);
       
    %fitness = sortrows(fitness,2);
    %save fitness fitness

    % Melhor rota calculada na populacao
    [minDist,index] = min(totalDist);
    minDist = minDist(2);
    index = index(2);
    distHistory(iter) = minDist;
    if minDist < globalMin
        globalMin = minDist;
        optRoute = population(index,:);
        
        % Plotar a melhor rota atual
        %rte = optRoute([1:d 1]);
       % plot(hAx,rte',rte','r.-');
        % Plotar desempenho por iteracao
       % plot(hAx,eil51(rte,2),eil51(rte,3),'r.-');
       % title(hAx,sprintf('Total Distance = %1.4f, Generation = %d',minDist,iter));
        %drawnow;
    end
    
    %Seleção por roleta e crossover PMX
    popFilhos = selecaoRoleta(population, popSize, totalDist, n_cities); 
    distFilhos = fitness(popFilhos, popSize, dist);
    newPop = selecionarMelhoresIndividuos(population, popFilhos, totalDist, distFilhos);
    population = mutacaoInversao(newPop);
    %totalDist = fitness(population, popSize, dist);
    disp(strcat('Gen: ',num2str(iter),' - Min. Dist: ',num2str(globalMin)));
end
%disp(strcat('Gen: ',num2str(iter),' - Min. Dist: ',num2str(globalMin)));




% Plotar resumo da execução do algoritmo
% figure('Name','TSP Resolution | Results','Numbertitle','off');
% subplot(2,2,1);
% pclr = ~get(0,'DefaultAxesColor');
% plot(xy(:,1),xy(:,2),'.','Color',pclr);
% title('City Locations');
% subplot(2,2,2);
% imagesc(dmat(optRoute,optRoute));
% title('Distance Matrix');
% subplot(2,2,3);
% rte = optRoute([1:n 1]);
% plot(xy(rte,1),xy(rte,2),'r.-');
% title(sprintf('Total Distance = %1.4f',minDist));
% subplot(2,2,4);
% plot(distHistory,'b','LineWidth',2);
% title('Best Solution History');
% set(gca,'XLim',[0 numIter+1],'YLim',[0 1.1*max([1 distHistory])]);

