function population = mutacaoInversao(population)
    tam = size(population);
    pos1 = 1;
    pos2 = 1;
        for i = 1: tam(2)
            probabilidade = rand();
            if(probabilidade <= 0.03)
                %O ponto 1 deve ser maior que 1 e menor que a metade do tamanho do cromossomo - 1
                vetAleatorio = randperm(tam(2));
                posVet = 1;
                pos1 = vetAleatorio(1,i);
                pos2 = pos1 - 1;
                while pos1 < (tam(2)/2) - 1 && pos1 > 1  
                    pos1 = vetAleatorio(1, posVet);
                    posVet = posVet + 1;
                end
                
                 %O ponto 2 deve ser maior que o ponto 1 em pelo menos 2 elementos e menor do que o tamanho do cromossomo -1
                posVet = 1;
                while pos2 >= pos1 - 1 && pos2 < tam(2) - 1
                    pos1 = vetAleatorio(1, posVet);
                    posVet = posVet + 1;
                end
                           
                auxInd = zeros(1,pos2 - pos1);
                aux = pos1;
                auxTam = size(auxInd);
                
                %Inseri os elementos entre os pontos em um vetor auxiliar.
                for j = 1: auxTam(2);
                    auxInd(1,j)= population(i,aux);
                    aux =+ 1;
                end
                
                %Insere os elementos invertidos do vetor auxiliar para o vetor de gene do cromossomo
                aux = (pos2-pos1) - 1;
                for j = pos1:pos2
                    population(i,j) = auxInd(1,aux);
                    aux =- 1;
                end
            end
        end
end