function filhos = selecaoRoleta(populacao, popSize, totalDist, n_cities)
        filhos = zeros(popSize,n_cities);
        limites = zeros(1,popSize);
        totalParcial = 0;
        total = 0;
        indexFilhos = 1;
        
         %Inseri o valor fitness na roleta, e atribui seu limite.
         %O valor do fitness é invertido pois a melhor aptidão é o
         %cromossomo que traz o menor gasto

        for i = 1: popSize
            fitness = totalDist(i,2);
            totalParcial = totalParcial + fitness;
        end
        for i = 1: popSize 
            fitness = totalDist(i,2);
            total = total + (totalParcial/fitness);
            limites(1,i) = total;
        end
        
        %Metodo da roleta
        for x = 1: popSize
            pais = zeros(2,n_cities);
            i = 1;
            while i <= 2
                random = rand();
                sorteio = 0;
                sorteio = random * total;
                for j = 1: popSize;
                    if sorteio < limites(1,j);
                        %%%%%%%%%%%%%%%%%%%%%%
                        %if i > 1;
                            %Não pode haver cruzamento de dois pais iguais, esse teste evita isso.
                            %igual = isequal(pais(1,:), populacao(j,:));
                            %if igual == 1;
                                %i = i-1;
                                %break;
                            %end
                        %end
                        %%%%%%%%%%%%%%%%%%%%%%%%%
                        pais(i,:) = populacao(j,:);
                        i = i+1;
                        break;
                    end
                end
            end
            
            %Definição dos pontos de corte para cruzamento
            %O ponto de corte 1 deve ser maior que 1 e menor que a metade do tamanho do individuo - 1
            %O ponto de corte 2 deve ser maior que o ponto de corte 1 e menor do que o tamanho do cromossomo -1
            random = randperm(n_cities);
            pontoCorte1 = 0;
            pontoCorte2 = 0;
            i = 1;
            while pontoCorte1 == 1 || pontoCorte1 > ((n_cities/2) - 1) || pontoCorte2 <= pontoCorte1 || pontoCorte2 == n_cities
                pontoCorte1 = random(1,i);
                pontoCorte2 = pontoCorte1;
                if pontoCorte1 > (n_cities/2) - 1
                    pontoCorte1 = random(1,i+1);
                    
                else
                    pontoCorte2 = random(1, i+1);
                end
                i=i+1;
            end
            crossPoints = [pontoCorte1 pontoCorte2];

            
             %O método crossoverPMX retorna um vetor de Cromossomos com tamanho 2, 
             %este será inserido em vetor auxiliar e depois em um outro vetor
             %com tamanho da população.
            aux = crossoverPMX(pais, crossPoints,n_cities);
            cont= 1;
            if indexFilhos == 1
                while indexFilhos < x+2 && x < popSize-1
                    filhos(indexFilhos,:) = aux(cont,:);
                    cont = cont + 1;
                    indexFilhos = indexFilhos + 1;
                end
            else
                while indexFilhos < x+3 && x < popSize-1
                    filhos(indexFilhos,:) = aux(cont,:);
                    cont = cont + 1;
                    indexFilhos = indexFilhos + 1;
                end
            end
            
            
            x = x + 1 ;
        end
        
end