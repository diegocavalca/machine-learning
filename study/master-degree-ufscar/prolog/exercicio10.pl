%%% Item (A)
%% Base de dados de conhecimento (fatos)
livro(nome('C completo e total'),
    autor('Schildt'),
	pal_chave([linguagemc, programacao, computacao])).
livro(nome('Como fazer amigos e influenciar pessoas'),
    autor('Carnegie'),
	pal_chave([filosofia, sociedade, reflexao, comportamento])).
livro(nome('Uma breve historia do tempo'),
    autor('Hawking'),
	pal_chave([fisica, universo, tempo, filosofia])).

%% Busca autor pelo nome do livro
autor_livro(X, A) :- livro(nome(X), autor(A), _).

%% Busca livro pelo nome do autor
livro_autor(A, X) :- livro(nome(X), autor(A), _).

%% Busca palavras-chave pelo nome do livro
keywords_livro(X, PC) :- livro(nome(X), _, pal_chave(PC)).

%% Busca autor e livro dada uma palavra-chave
% Verificar se X pertence a L
pertence(X, [X|_]).
pertence(X, [_|L]) :- pertence(X, L).
% Buscar ...
livroautor_keyword(X, Livro, Autor) :- livro(nome(Livro), autor(Autor), 
										pal_chave(PC)),
									   pertence(X, PC).

%%% Item (B)
busca_livro_palchave(Keywords, Livro, Autor):- 
								livro(nome(Livro), autor(Autor), 
									pal_chave(PalavrasChave)),
								combina(Keywords, PalavrasChave).

combina([X|_], L) :- pertence(X, L), !.
combina([_|L1], L) :- combina(L1, L).