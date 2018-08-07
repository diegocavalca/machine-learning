pertence(X,[X|_]).
pertence(X,[_n|Z]) :- pertence(X,Z).