del(_, [], []).
del(X, [X|L1], L2) :- del(X, L1, L2).
del(X, [Y|L1], [Y|L2]) :- X \==Y, del(X, L1, L2).