add_ultimo(X, [], [X]).
add_ultimo(X, [X1|Y], [X1|Z]) :- add_ultimo(X, Y, Z).