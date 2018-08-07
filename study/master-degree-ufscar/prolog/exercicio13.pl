% Base de dados de conhecimento (Fatos)
t(0, zero).
t(1, um).
t(2, dois).
t(3, tres).
t(4,quatro).
t(5,cinco).
t(6,seis).
t(7,sete).
t(8,oito).
t(9,nove).

% Caso base: se lista de entrada = []
traduz([],[]).

% Caso recursivo: Caso seja possivel traduzir X em N, de modo que
% existam uma lista de elementos a serem traduzidos
traduz([X|Xs], [N|Ns]) :- t(X, N), traduz(Xs, Ns).