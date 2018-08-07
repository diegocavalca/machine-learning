function [particle,cost] = LocalSearch(particle, w, distances)


% ============================ Code Description ========================= %
%             2-opt algorithm for tour improvement procedure              %
% ======================================================================= %
%
% The 2-opt search is one of various local search that is simple and famous 
% to improve the solution executing on neighborhood search.  In addition, it  
% can be found the locally optimal solution (see Croes, 1958).  However, this
% version of 2-opt heuristic is originally coded by Nuhoglu (2007).
%
%
% Reference:
%
% Croes, G.A. (1958). A method for solving traveling salesman problems. 
%        Operations Research, 6: 791-812.
% Nuhoglu, M. (2007). Shortest particle heuristics (nearest neighborhood, 2 opt, 
%        farthest and arbitrary insertion) for travelling salesman problem.  
%        Available Source: http://snipplr.com/view/4064/shortest-particle-heuristics-
%        nearest-neighborhood-2-opt-farthest-and-arbitrary-insertion-for-travelling-
%        salesman-problem/
%
% --------------------------------------------------------------------
%
% Modified by: Wantchapong Kongkaew
%              Department of Industrial Engineering, Faculty of Engineering,
%              Kasetsart University, Thailand.
% Date: January 20, 2012 
% 
% ======================================================================= %

    global n 
    n = length(particle);
    m = ceil( n * w ); % Fator de limitação de trocas (arestas)
    
    for i=1:n
        for j=1:m;
            if change_in_distance(particle,i,j,distances) < 0 
                particle = swap_edge(particle,i,j);
            end
        end
    end
    cost = Fitness(particle,distances);


% Additional subfunctions for solving via 2-Opt algorithm (Croes, 1958)
function result = change_in_distance(particle,i,j,distances)
before=distances(particle(r(i)),particle(r(i+1)))+distances(particle(r(i+1+j)),particle(r(i+2+j)));
after=distances(particle(r(i)),particle(r(i+1+j)))+distances(particle(r(i+1)),particle(r(i+2+j)));
result=after-before;

function particle = swap_edge(particle,i,j)
old_path=particle;
 % exchange edge cities
particle(r(i+1))=old_path(r(i+1+j));
particle(r(i+1+j))=old_path(r(i+1));
 % change direction of intermediate particle 
for k=1:j-1
    particle(r(i+1+k))=old_path(r(i+1+j-k));
end

  % if index is greater than the particle length, turn index one round off
function result = r(index)
global n
if index > n
    result = index - n;
else
    result = index;
end