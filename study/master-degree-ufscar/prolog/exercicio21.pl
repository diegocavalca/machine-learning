separa_sz([],[],[]).

separa_sz([X|L], [X|P], N) :- X > 0,
							  separa_sz(L, P, N).

separa_sz([X|L], P, [X|N]) :- X < 0,
							  separa_sz(L, P, N).

separa_sz([X|L], P, N) :- X =:= 0,
						  separa_sz(L, P, N).