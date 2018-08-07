% ## Copyright (C) 2016 Diego Cavalca
% ## 
% ## This program is free software; you can redistribute it and/or modify it
% ## under the terms of the GNU General Public License as published by
% ## the Free Software Foundation; either version 3 of the License, or
% ## (at your option) any later version.
% ## 
% ## This program is distributed in the hope that it will be useful,
% ## but WITHOUT ANY WARRANTY; without even the implied warranty of
% ## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% ## GNU General Public License for more details.
% ## 
% ## You should have received a copy of the GNU General Public License
% ## along with this program.  If not, see <http://www.gnu.org/licenses/>.
% 
% ## -*- texinfo -*- 
% ## @deftypefn {Function File} {@var{retval} =} SwapOperators (@var{input1}, @var{input2})
% ##
% ## @seealso{}
% ## @end deftypefn
% 
% ## Author: Diego Cavalca <diego.cavalca@dc.ufscar.br>
% ## Created: 2016-09-27

function [sInit, sInitCost, sObj, sObjCost] = PathRelinking (sInit, sInitCost, sObj, sObjCost, c, cPr, distances)

    % PARAMETROS
    % sInit - Solucao inicial (particle)
    % sInitCost - Custo da Solucao inicial
    % sObj - Solucao Objetivo (particle)
    % scoreBest - Melhor custo (pBest ou gBest) encontrado ate o momento
    % cPr - indice de avaliacao
    sAux = sInit;
    % Distancia exata entre vetores (elementos diff na posicao 'i')...
    distE = sum( (sAux-sObj)~=0 );
    
    % Passos de avaliacao das solucoes (numero de passos percorridos entre a particula de origem e destino)...    
    fC = (c + rand(1))/2;
    steps = floor( distE * fC); 
    
    evaluations = 0;
    interval = 1/cPr;
    
    % Path Relinking
    for i=1:steps;
        
        % Altera sInit na dimensao 'd'
        d = randi(size(sAux,2));
        vD = sAux(d);
        nV = randi(size(sAux,2));
        while vD == nV;
          nV = randi(size(sAux,2));  
        end;
        nP = find(sAux==nV);
        sAux([nP d]) = [vD nV];

        % Avaliacoes..
        if i >= interval * evaluations;
            % Avalia nova solucao criada
            cost = Fitness(sAux,distances);
            if cost < sObjCost;
                sObjCost = cost;
                sObj = sAux;
                sInit = sAux;
                sInitCost = cost;                
            end;            
            evaluations = evaluations + 1;
        end;
        
     end;

end
