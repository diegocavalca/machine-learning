function totalDist = fitness(population, popSize, dist)
    [d,c]=size(dist); % Dimensoes do dataset
     for i=1:popSize;
        % Capturar cada indivíduo da população
        individual = population(i,:);

        % Percorrer colunas (pontos) do individuo a fim de totalizar o custo do
        % trajeto
        total = 0;
      
        for j=2:size(individual,2);
            total = total + dist(individual(1,j),individual(1,j-1));
            %disp(total);
        end;

        % Calcular o custo de voltar ao ponto 1
        total = total + dist(individual(1,d),individual(1,1));
        % Guardando a aptidão do indivíduo
        totalDist(i,:) = [i, total];
        
     end
end