shift([],[]).

shift([X|L1], L2) :- shiftEnd(X, L1, L2).


shiftEnd(X, [], [X]).
shiftEnd(X, [Y|L1], [Y|L2]) :- shiftEnd(X, L1, L2).