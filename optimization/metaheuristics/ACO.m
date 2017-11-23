clear;

%%%%% Step 1
n = 4; # num de formigas
x = (0:0.5:3);

% Quantidade inicial de feromonio Tal
Tal = ones(1,length(x));
% roots
ro = 0.5;
% Iteracoes
i = 10;

for numIter = 1:n; % Limite de iteracoes alinhado ao numero de formigas

  %disp(sprintf('Iter.: %d',numIter));

  %%%%% Step 2
  for j = 1:length(x);
    prob(j) = Tal(j)/sum(Tal);  
  end;

  %%%%% Step 3
  % Roleta
  x1 = zeros(1,length(x)+1);
  for j = 1:length(x);
    x1(1,j+1) = (prob(j)/sum(prob)) + x1(j); % Ref - https://en.wikipedia.org/wiki/Fitness_proportionate_selection
  end;

  % Gera numeros aleatorios para cada formigas
  r = rand(1,n);
  if numIter == 1
    r = [0.3122 0.8701 0.4729 0.6190];
  else
    r = [0.3688 0.8577 0.0706 0.5791];
  end;
  caminho = zeros(1,n);
  for j = 1:n;
    for l = 2:length(x1);
      if( r(1,j)>=x1(1,l-1) && r(1,j)<=x1(1,l) )
        caminho(j) = l-1;
        break;
      end;    
    end;  
  end;

  % Pegar os valores do caminho selecionado e atribui para cada formiga
  %x1j = zeros(1,n);
  % Calcular funcao objetivo
  fo = x(caminho);
  for j = 1:length(fo);
    fobj(j) = fo(j)^2 - 2*fo(j) - 11;
  end;

  % Selecionando o melhor e o pior
  fpior = max(fobj);
  xpior = fo(find(fobj==max(fobj)));
  fmelhor = min(fobj);
  xmelhor = fo(find(fobj==min(fobj)))

  %%%%% Step 4
  evap = 0.5; % evaporacao
  escala = 2; 
  depFeromonio = length(xmelhor)*((escala*fmelhor)/fpior); % Depositar feromonio no melhor caminho
  % Atualizar feromonio para cada caminho (aumentar ou diminuir)...
  for j = 1:length(Tal);
    
    %Tal(1,j) = (1 - evap)*Tal(1,j) + depFeromonio;
    if isempty(find(caminho(xmelhor)==j))==0
      Tal(1,j) = Tal(1,j) + depFeromonio;
    else
      Tal(1,j) = (1 - evap)*Tal(1,j);
    end;
      
  end;
  %break;
end;

% Resultado (CORRIGIR PLOT)...
disp(sprintf('Melhor custo: %d',fmelhor));
figure();
x = [fmelhor:1:10];
y = [0:1:3];
plot(-, x.^2 -2*x - 11);