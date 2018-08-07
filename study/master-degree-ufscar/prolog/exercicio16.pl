max16(X, Y, X) :- X >= Y.
max16(X, Y, Y) :- X < Y.

maxLista([X],X).
maxLista([X|Xs], Maximo) :- maxLista(Xs, MaxXs),
							max16(X, MaxXs, Maximo).
