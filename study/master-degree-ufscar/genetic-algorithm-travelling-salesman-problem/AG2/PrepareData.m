clear

% Preparar os dados
load 'eil51.tsp';
dadosoriginais = eil51;
[l,c]=size(dadosoriginais);
d = zeros(l,l);
dist = zeros(l,l);
for i=1:l;
    for j=1:l;
        d(i,j) = ((dadosoriginais(i,2)-dadosoriginais(j,2))^2+(dadosoriginais(i,3)-dadosoriginais(j,3))^2);
        dist(i,j) = sqrt(d(i,j));
    end
end
save dist dist
