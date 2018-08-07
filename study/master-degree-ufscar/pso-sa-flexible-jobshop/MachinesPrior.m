function Mij = MachinesPrior(Tij)
    Mij = Tij;
    Mij( Mij==0 ) = Inf;
    [~, Mij] = sort(Mij, 2);
end