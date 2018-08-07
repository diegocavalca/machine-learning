somalista([], 0).
somalista([Elemento|Lista], Total) :- somalista(Lista, Subtotal), 
										Total is Elemento+Subtotal.