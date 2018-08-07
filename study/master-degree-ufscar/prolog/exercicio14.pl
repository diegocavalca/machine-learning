pertence14(X, [X|_]) :- !.
pertence14(X, [_|L]) :- pertence14(X, L).

subset(_, []) :- !.
subset(L, [X|Xs]) :- pertence14(X, L), 
					 subset(L, Xs).