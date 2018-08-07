%% Problema escolhido: Politicos corruptos II 
% (https://rachacuca.com.br/logica/problemas/politicos-corruptos-ii/)
% Estrutura principal do problema
% politico(Numero, Gravata, Nome, Setor, Valor Estado, Paraiso)

% *** OBS.: Para executar o algoritmo, basta chamar a regra 'solucao.'
% no terminal Prolog, após carregar o arquivo em memória ([trabalho1].) ***

% Procedimento principal, que invoca os procedimentos
% de resolução e exibição da solução do problema
solucao :-  
	%% Mensurar tempo de execução do algoritmo (Inicio)
	writeln('\nAguarde, processando fatos e regras do problema...'),
	
	% Chamada da regra de resolução do problema dos Políticos Corruptos II
    problema( [P1, P2, P3, P4, P5] ),
	
	% Exibição dos resultados inferidos para a resolução do problema,
	% consistindo de um conjunto de listas (cada lista Ax representando 
	% um político, conforme descrito na linha 4).
    exibeResultado( [P1, P2, P3, P4, P5] ),

	writeln('\n\nObs.: cada linha acima representa um politico.'),
	
	% Finaliza a busca pela solução, uma vez que as hipoteses
	% foram validadas na regra 'problema'.
	fail.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROBLEMA: Regra para a solução do problema, onde deve inferir os
% valores que resolvem o problema estudado através do conjunto de 
% regras disponíveis para cada 'parâmetro' (Gravata, Nome, etc.).
% Portanto, a intuição lógica por trás do desenvolvimento desta 
% regra se resume a:
% 'O PROBLEMA vai ser resolvido SE todas as regras e condições forem 
% consideradas (dentro do escopo de valores disponíveis).
% Na resolução, cada atributo é composto de 5 variáveis diferentes,
% as quais dizem respeito a cada político individualmente.
problema([
    (Gravata1, Nome1, Setor1, Valor1, Estado1, Paraiso1),
    (Gravata2, Nome2, Setor2, Valor2, Estado2, Paraiso2),
    (Gravata3, Nome3, Setor3, Valor3, Estado3, Paraiso3),
    (Gravata4, Nome4, Setor4, Valor4, Estado4, Paraiso4),
    (Gravata5, Nome5, Setor5, Valor5, Estado5, Paraiso5)
    ]) :-

	%%% ATRIBUTO: GRAVATA
	gravata(Gravata1), 
	gravata(Gravata2), 
	gravata(Gravata3), 
	gravata(Gravata4), 
	gravata(Gravata5),

	%% FATOS ESTABELECIDOS A PRIORI...
	% 7) Na terceira posição está o político da gravata Amarela.
	(Gravata3 == amarela),

	% Força a definicao de valores unicos para o atributo, eliminando fatos conhecidos a priori...
	valoresUnicos([Gravata1, Gravata2, Gravata3, Gravata4, Gravata5]),
	%%%%%%%%%%

	%%% ATRIBUTO: NOME
	nome(Nome1), 
	nome(Nome2), 
	nome(Nome3), 
	nome(Nome4), 
	nome(Nome5),
	valoresUnicos([Nome1, Nome2, Nome3, Nome4, Nome5]),
	%%%%%%%%%%

	%%% ATRIBUTO: SETOR
	setor(Setor1), 
	setor(Setor2), 
	setor(Setor3), 
	setor(Setor4), 
	setor(Setor5),

	%% FATOS ESTABELECIDOS A PRIORI...
	% 14) O político que roubou do setor de Transporte está na quarta posição.
	(Setor4 == transporte),

	valoresUnicos([Setor1, Setor2, Setor3, Setor4, Setor5]),

	%% REGRAS DE INFERÊNCIA...
	% 10) O político da gravata Azul está em algum lugar entre quem roubou da Saúde e o Fernando, nessa ordem.
	% (eliminando Gravata3 == amarela)
	(
		((Setor1 == saude, Nome5 == fernando), (Gravata4 == azul; Gravata2 == azul));
		(Setor1 == saude, Nome4 == fernando, Gravata2 == azul);
		(Setor1 == saude, Nome3 == fernando, Gravata2 == azul);
		(Setor2 == saude, Nome5 == fernando, Gravata4 == azul);
		(Setor3 == saude, Nome5 == fernando, Gravata4 == azul)
	),
	% 20) Luiz roubou do setor energético.
	(
		(Setor1 == energia, Nome1 == luiz);
		(Setor2 == energia, Nome2 == luiz);
		(Setor3 == energia, Nome3 == luiz);
		%(Setor4 == energia, Nome4 == luiz); %  --> Já se sabe sobre Setor4 a priori, elimina a regra
		(Setor5 == energia, Nome5 == luiz)
	),
	%%%%%%%%%%

	%%%%%%%%%%%%%%%%%%%%%%%% VALOR
	valor(Valor1), 
	valor(Valor2), 
	valor(Valor3), 
	valor(Valor4), 
	valor(Valor5),

	%% FATOS ESTABELECIDOS A PRIORI...
	% 18) Na segunda posição está o político que roubou R$ 200 M.
	(Valor2 == 200),   

	valoresUnicos([Valor1, Valor2, Valor3, Valor4, Valor5]),

	%% REGRAS DE INFERÊNCIA...
	% 1) O político da gravata Azul está em algum lugar à esquerda de quem roubou a maior quantia.
	(
		(Valor5 == 500, (Gravata4 == azul ; Gravata2 == azul ; Gravata1 == azul));
		(Valor4 == 500, (Gravata2 == azul ; Gravata1 == azul));
		(Valor3 == 500, (Gravata2 == azul ; Gravata1 == azul))
		%(Valor2 == 500, Gravata1 == azul)
	),
	% 4) Em uma das pontas está o político que roubou R$ 100 M.
	(Valor1 == 100; Valor5 == 100),
	% 6) Foram roubados R$ 100 M da educação.
	(
		(Valor1 == 100, Setor1 == educacao);
		(Valor3 == 100, Setor3 == educacao);
		(Valor4 == 100, Setor4 == educacao);
		(Valor5 == 100, Setor5 == educacao)
	),
	%%%%%%%%%%

	%%% ATRIBUTO: ESTADO
	estado(Estado1), 
	estado(Estado2), 
	estado(Estado3),
	estado(Estado4), 
	estado(Estado5),

	%% FATOS ESTABELECIDOS A PRIORI...
	% 9) O político do Mato Grosso tem conta em Mônaco.
	(Estado3 == mato_grosso),

	valoresUnicos([Estado1, Estado2, Estado3, Estado4, Estado5]),

	%% REGRAS DE INFERÊNCIA...
	% 2) Alberto está ao lado do político de Tocantins.
	(
		(Nome5 == alberto, Estado4 == tocantins);
		(Nome4 == alberto, (Estado2 == tocantins; Estado5 == tocantins));
		(Nome3 == alberto, (Estado2 == tocantins; Estado4 == tocantins));
		(Nome2 == alberto, (Estado1 == tocantins; Estado3 == tocantins));
		(Nome1 == alberto, Estado2 == tocantins)
	),
	% 13) O político da gravata Branca está exatamente à esquerda do político fluminense.
	(
		(Gravata4 == branca, Estado5 == rio_de_janeiro);
		(Gravata2 == branca, Estado3 == rio_de_janeiro);
		(Gravata1 == branca, Estado2 == rio_de_janeiro)
	),
	 % 17) O político da gravata Azul está em algum lugar entre os políticos de Santa Catarina e Rio de Janeiro, nessa ordem.
	(
		((Estado1 == santa_catarina, Estado5 == rio_de_janeiro), (Gravata4 == azul; Gravata2 == azul));
		(Estado1 == santa_catarina, Estado4 == rio_de_janeiro, Gravata2 == azul);
		%(Estado1 == santa_catarina, Estado3 == rio_de_janeiro, Gravata2 == azul);
		(Estado2 == santa_catarina, Estado5 == rio_de_janeiro, Gravata4 == azul)
		%(Estado3 == santa_catarina, Estado5 == rio_de_janeiro, Gravata4 == azul)
	),

	% 5) O político do estado nordestino está exatamente à esquerda de quem roubou R$ 100 M.
	(
		(Estado1 == alagoas, Valor2 == 100);
		(Estado2 == alagoas, Valor2 == 100);
		(Estado4 == alagoas, Valor5 == 100)
	),
	%%%%%%%%%%
	 
	%%% ATRIBUTO: PARAÍSO
	paraiso(Paraiso1), 
	paraiso(Paraiso2), 
	paraiso(Paraiso3), 
	paraiso(Paraiso4), 
	paraiso(Paraiso5),

	%% FATOS ESTABELECIDOS A PRIORI...
	% 16) Na primeira posição está o político com conta nas Bahamas.
	(Paraiso1 == bahamas),

	% 21) Na terceira posição está o político com conta em Mônaco.
	(Paraiso3 == monaco),

	valoresUnicos([Paraiso1, Paraiso2, Paraiso3, Paraiso4, Paraiso5]),

	% REGRAS DE INFERÊNCIA...
	% 3) O político que robou R$ 300 M está exatamente à direita de quem tem conta em Mônaco.
	(
		% (Valor2 == 300, Paraiso1 == monaco);
		(Valor3 == 300, Paraiso2 == monaco);
		(Valor4 == 300, Paraiso3 == monaco);
		(Valor4 == 300, Paraiso4 == monaco)
	),
	% 8) Fernando está exatamente à esquerda do político que tem conta na Bolívia.
	(
		(Nome4 == fernando, Paraiso5 == bolivia);
		(Nome3 == fernando, Paraiso4 == bolivia);
		(Nome2 == fernando, Paraiso3 == bolivia);
		(Nome1 == fernando, Paraiso2 == bolivia)
	),
	% 11) Luiz está ao lado de quem tem conta em Luxemburgo.
	(
		(Nome5 == luiz, Paraiso4 == luxemburgo);
		(Nome4 == luiz, (Paraiso2 == luxemburgo; Paraiso5 == luxemburgo));
		(Nome3 == luiz, (Paraiso2 == luxemburgo; Paraiso4 == luxemburgo));
		(Nome2 == luiz, (Paraiso1 == luxemburgo; Paraiso3 == luxemburgo));
		(Nome1 == luiz, Paraiso2 == luxemburgo)
	),
	% 12) Renato está exatamente à direita de quem tem conta em Luxemburgo.
	(
		(Nome5 == renato, Paraiso4 == luxemburgo);
		(Nome4 == renato, Paraiso3 == luxemburgo);
		(Nome3 == renato, Paraiso2 == luxemburgo);
		(Nome2 == renato, Paraiso1 == luxemburgo)
	),
	% 15) O político da gravata Verde tem conta nas Bahamas.
	(
		(Gravata1 == verde , Paraiso1 == bahamas);
		(Gravata2 == verde , Paraiso2 == bahamas);
		(Gravata4 == verde , Paraiso4 == bahamas);
		(Gravata5 == verde , Paraiso5 == bahamas)
	),
	% 19) O político que tem conta em Luxemburgo está exatamente à esquerda de quem roubou R$ 100 M.
	(
		(Paraiso2 == luxemburgo, Valor3 == 100);
		(Paraiso4 == luxemburgo, Valor5 == 100)
	),
	%%%%%%%%%%
	nl,
	write('RESULTADO ENCONTRADO:').
        
%%%% BASE DE DADOS DO PROBLEMA (FATOS)

% Gravatas (cores)
gravata(amarela).
gravata(azul).
gravata(branca).
gravata(verde).
gravata(vermelha).

% Nomes dos políticos
nome(alberto).
nome(fernando).
nome(luiz).
nome(renato).
nome(ricardo).

% Setores do governo
setor(educacao).
setor(energia).
setor(saude).
setor(seguranca).
setor(transporte).

% Valor (em Mi. - R$) envolvido
valor(100).
valor(200).
valor(300).
valor(400).
valor(500).

% Estado
estado(alagoas).
estado(mato_grosso).
estado(rio_de_janeiro).
estado(santa_catarina).
estado(tocantins).

% Paraíso fiscal
paraiso(bahamas).
paraiso(bolivia).
paraiso(ilhas_bermudas).
paraiso(luxemburgo).
paraiso(monaco).

%%%%%%%%%%

%%% PROCEDIMENTOS AUXILIARES DO PROGRAMA...

%% Procedimento para evitar duplicidade de valores
% para os argumentos, de modo a garantir que cada
% político venha a ter um valor único (dado o 
% conjunto possível na base de dados do programa)
% para cada argumento em questão.
valoresUnicos([]).
valoresUnicos([X|L]):- not(member(X, L)),
					  valoresUnicos(L).
	
%% Procedimento para exibir o resultado da solucao,
% imprimindo os atributos dde cada Político (Px). 
exibeResultado([]).
exibeResultado([Px|Lista]):- 
	write('\n......................................\n'),
	% Dados do político x (Cabeça da lista)
	write(Px), write(';'),
	% Chamada recursiva
	exibeResultado(Lista).
	
%%%%%%%%%%	   