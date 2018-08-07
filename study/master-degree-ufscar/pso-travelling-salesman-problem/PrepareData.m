clear

% Preparar os dados
load 'eil51.tsp';
originaldata = eil51;
[l,c]=size(originaldata);
d = zeros(l,l);
distances = zeros(l,l);
for i=1:l;
    for j=1:l;
        d(i,j) = ((originaldata(i,2)-originaldata(j,2))^2+(originaldata(i,3)-originaldata(j,3))^2);
        distances(i,j) = sqrt(d(i,j));
    end
end
save distances distances
