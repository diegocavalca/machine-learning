dobro([],[]).
dobro([X|L1],[Y|L2]) :- Y is X*X, dobro(L1,L2).