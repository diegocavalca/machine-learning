%casal(+Homem,+Mulher)
casal(eu,w).
casal(f,d).
mae(w,d).
mae(w,s1).
mae(d,s2).
pai(f,eu).

padrasto(X,Y) :- casal(X,Z), mae(Z,Y). 
madrasta(X,Y) :- casal(Z,X), pai(Z,Y).

relacao(X,Y) :- pai(X,Y). 
relacao(X,Y) :- mae(X,Y). 
relacao(X,Y) :- padrasto(X,Y). 
relacao(X,Y) :- madrasta(X,Y).

avo(X,Y) :- relacao(X,Z), relacao(Z,Y).