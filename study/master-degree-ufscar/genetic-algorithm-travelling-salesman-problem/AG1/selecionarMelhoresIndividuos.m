function popMenorVal = selecionarMelhoresIndividuos(populationPais, populationFilhos, totalDist, totalDist2)
    [l,c] = size(populationPais);
    popMenorVal = zeros(l,c);
    %mintDist2t = zeros(1,2);
    %mintDistT = zeros(1,2);
    for i = 1: l
        [minDistT,index] = min(totalDist);
        minDist = minDistT(2);
        index = index(2);
        [minDist2t,index2t] = min(totalDist2);
        minDist2 = minDist2t(2);
        index2 = index2t(2);
        if minDist < minDist2
            popMenorVal(i,:) = populationPais(index,:);
            totalDist(index,:) = inf;
        else
            popMenorVal(i,:) = populationFilhos(index2,:);
            totalDist2(index2,:) = inf;
        end
    end
end