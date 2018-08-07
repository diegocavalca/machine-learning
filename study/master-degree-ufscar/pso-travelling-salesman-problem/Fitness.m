function total = Fitness( individual, distances )
    total = 0;
    for c=2:size(individual,2);
        total = total + distances(individual(c), individual(c-1));
    end;
    total = total + distances(individual(c), individual(1)); % Volta para o destino...
end

