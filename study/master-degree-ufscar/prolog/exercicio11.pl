n_par([]).
n_par([_,_|L]) :- n_par(L).

n_impar([X]) :- atom(X).
n_impar([_,_|L]) :- n_impar(L).