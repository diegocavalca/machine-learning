deleta(_, [], []).							% Qualquer coisa em L=[] -> []
deleta(X, [X|L1], L2) :- deleta(X, L1, L2).
deleta(X, [Y|L1], [Y|L2]) :- X \== Y, deleta(X, L1, L2).