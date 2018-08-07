% Caso base: 
% Deletar algo de lista vazia, retorna []
deleteAll(_, [], []).

% Caso recursivo 1: 
% Se X está na cabeça de uma lista, retorna uma lista sem X  
deleteAll(X, [X|L1], L2) :- deleteAll(X, L1, L2).

% Caso recursivo 2: 
% Se X não está na cabeça de uma lista, varrer cauda 
deleteAll(X, [Y|L1], [Y|L2]) :- X \== Y, deleteAll(X, L1, L2).