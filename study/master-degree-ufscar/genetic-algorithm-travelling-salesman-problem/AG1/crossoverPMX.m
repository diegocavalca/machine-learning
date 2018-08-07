function newPop=crossoverPMX(parents,crossPoints,n_cities)

     %Realizando o crossover
     for i=1:2
         newPop(i,:)=parents(i,:);
         newPop(i,crossPoints(1):crossPoints(2))= parents(mod(i,2)+1,crossPoints(1):crossPoints(2));
     end

     %Corrigindo as duplicidades
     for i=1:2
         for j=1:n_cities
             if j<crossPoints(1) || j>crossPoints(2)
                 while max(newPop(i,j)==newPop(i,crossPoints(1):crossPoints(2)))~=0
                     [~,TMPloc]=max(newPop(i,j)== newPop(i,crossPoints(1):crossPoints(2)));
                     newPop(i,j)=parents(i,crossPoints(1)+TMPloc-1);
                 end
             end
         end
     end