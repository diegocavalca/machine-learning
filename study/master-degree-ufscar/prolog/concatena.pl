concatena([], L, L).
concatena([X|L1], L2, [X|L3]) :- concatena(L1, L2, L3).