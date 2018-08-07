function [ planejamento, horarios, consumos ] = planoConsumoDispositivo( dispositivo, modo, H )
    % Geracao de plano de consumo de energia (funcionamento) de cada
    % aparelho, com base em suas restricoes de operacao e consumo
    % INPUT:
    % - dispositivo: vetor com os dados do dispositivo
    % - modo       : modo de definicao dos slots de acionamento 
    %                (aleatorio ou estocastico)
    % - H          : horizonte de planejamento
    planejamento = zeros(1, H);
    
    %planejamento(horarios(1)) = dispositivo.ConsPlanejado;%consumos;
    % Gerar vetor com base na classe do dispositivo:
    % 1 = Consumo elastico
    % 2 = Consumo Nao-Elastico, Interruptivel
    % 3 = Consumo Nao-Elastico, Nao-Interruptivel
    Classe = 1; % Substituir pela classe do dispositivo
    switch Classe
        case 1
            [horarios, consumos] = cons_EI(dispositivo, modo, H); 
        case 2
            [horarios, consumos] = cons_nEI(dispositivo, H);
        case 3
            [horarios, consumos] = cons_nEnI(dispositivo, H);
        otherwise
            horarios = 1:H;
            consumos = zeros(1, H);
    end
    planejamento(horarios) = consumos;
    
    %totalDisps = size(dispositivos,1);

    % Dispositivo d
    %dispositivo = dispositivos(d, :);

%     limiteJanela = abs(dispositivo.Fim - dispositivo.Inicio);
% 
%     % Duracao do consumo planejado
%     duracao = dispositivo.ConsPlanejado/(dispositivo.PotMaxima/1000);
%    
%     horarios = 1:H;    % Horarios factiveis (A tratar)
%     if(dispositivo.ConsPlanejado > 0);
% 
%         % Gerando horarios aleatorios (dentro do intervalo)
%         if(dispositivo.Inicio <= dispositivo.Fim);
%             horarios = horarios(ismember(horarios,dispositivo.Inicio:dispositivo.Fim));
%         else    
%             horarios = horarios(ismember(horarios,[dispositivo.Inicio:24,1:dispositivo.Fim]));    
%         end;
%         if limiteJanela >= duracao;
%             qtdHorarios = randsample(ceil(duracao):limiteJanela,1);%randi(length(horarios));
%         else
%             qtdHorarios = ceil(duracao);
%         end;
%         horarios = horarios(randperm(length(horarios),qtdHorarios));
%         
%          % Gerando consumos aleatorios (dentro do planejado)
%         consumos = randfixedsum(qtdHorarios,1, ...
%                                 dispositivo.ConsPlanejado, ... 
%                                 0, ... %dispositivo.PotMinima/1000, ... 
%                                 dispositivo.PotMaxima/1000);
%                             
%     else
%         consumos = zeros(1, 24);
%     end;
%     consumos = round(consumos, 5);
end

% Classe Dispositivo 1: Consumo Elastico
function [horarios, consumos] = cons_EI(dispositivo, modo, H)
    global tarifa;
    
    limiteJanela = abs(dispositivo.Fim - dispositivo.Inicio);

    % Duracao do consumo planejado
    duracao = dispositivo.ConsPlanejado/(dispositivo.PotMaxima/1000);
   
    horarios = 1:H;    % Horarios factiveis (A tratar)
    if(dispositivo.ConsPlanejado > 0);

        % Gerando horarios aleatorios (dentro do intervalo)
        if(~isequal(duracao, H));
            
            if(dispositivo.Inicio < dispositivo.Fim);
                horarios = horarios(ismember(horarios,dispositivo.Inicio:dispositivo.Fim-1));
            elseif(dispositivo.Inicio > dispositivo.Fim); 
                horarios = horarios(ismember(horarios,[dispositivo.Inicio:24,1:dispositivo.Fim-1]));    
            else
                horarios = dispositivo.Inicio;
            end;
            
        end;
        % Validar duracao vs. janela
        if(limiteJanela > ceil(duracao));
            
            % Analisar o modo de definicao dos slots de acionamento
            if( isequal(modo,'estocastico') );
                %%% Aumentar probabilidade de horarios fora de pico
                dur = length(horarios);
                probs = ones(1, dur)/length(horarios);
                pico = find(tarifa > min(tarifa)); % Horarios com valor elevado

                % Dentro e fora de pico
                dentro = ismember(horarios, pico);
                fora = ~ismember(horarios, pico);

                % Diminuir probabilidade de horarios de pico
                probs(dentro) = probs(dentro) - probs(1)*.9;

                % Aumentar probabilidade de horarios fora de pico
                probs(fora) = probs(fora) + (ones(1, sum(fora))*(1 - sum(probs))/sum(fora));

                % Qtd. de slots contemplados
                [val, ~] = sort(probs, 'descend');
                % Probabilidade de acordo com a qtd de slots
                probsH = [sum(val(1:ceil(duracao))) val(ceil(duracao)+1:end)]; 
                qtdHorarios = randsample(ceil(duracao):limiteJanela, 1, true, probsH);

                % Definir slots contemplados, com base na qtdHorarios
                slots = [];
                while size(slots,1) ~= qtdHorarios
                    % Total random
                    slots = unique([slots; randsample(horarios, 1, true, probs)'],'rows');
                end;
                horarios = slots';
            else
                % Slots definidos aleatoriamente
                qtdHorarios = randsample(ceil(duracao):limiteJanela,1);%randi(length(horarios));
                horarios = horarios(randperm(length(horarios),qtdHorarios));
            end;
        else
            qtdHorarios = length(horarios);%ceil(duracao);
        end;        
        
         % Gerando consumos aleatorios (dentro do planejado)
        consumos = randfixedsum(qtdHorarios,1, ...
                                dispositivo.ConsPlanejado, ... 
                                0, ... %dispositivo.PotMinima/1000, ... 
                                dispositivo.PotMaxima/1000);
                            
    else
        consumos = zeros(1, 24);
    end;
    consumos = round(consumos, 5);
end

% Classe Dispositivo 2: Consumo Nao-Elastico, mas Interruptivel
function [horarios, consumos] = cons_nEI(dispositivo, H)
    horarios = 1:H;
    consumos = zeros(1, H);
    
    if(dispositivo.ConsPlanejado > 0);
        
        % Gerando consumos aleatorios (dentro do planejado)
        consumos = [];
        potKWh = (dispositivo.PotMaxima/1000);
        duracao = dispositivo.ConsPlanejado/potKWh;
        for i = 1:floor(duracao);
            consumos = [consumos; potKWh];
        end;
        resto = (duracao - floor(duracao));
        if(resto>0);
            consumos = [consumos; resto*potKWh];
        end;
        consumos = round(consumos, 5);
        
        % Gerando horarios
        qtdHorarios = length(consumos);
        
        % Gerando horarios aleatorios (dentro do intervalo)
        if(~isequal(duracao,H));
            
            % Gerando horarios aleatorios (dentro do intervalo)
            if(dispositivo.Inicio <= dispositivo.Fim);
                horarios = horarios(ismember(horarios,dispositivo.Inicio:dispositivo.Fim-1));
            else    
                horarios = horarios(ismember(horarios,[dispositivo.Inicio:24,1:dispositivo.Fim-1]));    
            end;
            horarios = horarios(randperm(length(horarios),qtdHorarios));
%             if(dispositivo.Inicio <= dispositivo.Fim);
%                 horarios = horarios(ismember(horarios,dispositivo.Inicio:dispositivo.Fim-1));
%             else
%                 horarios = horarios(ismember(horarios,[dispositivo.Inicio:24,1:dispositivo.Fim-1]));
%             end;
%             inicio = randi(length(horarios)-qtdHorarios+1);
%             horarios = horarios(inicio:inicio+(qtdHorarios-1));
        end;
    end;
%     horarios = 1:H;
%     consumos = zeros(1, H);
%     
%     if(dispositivo.ConsPlanejado > 0);
%         
%         % Gerando consumos aleatorios (dentro do planejado)
%         consumos = [];
%         potKWh = (dispositivo.PotMaxima/1000);
%         duracao = dispositivo.ConsPlanejado/potKWh;
%         for i = 1:floor(duracao);
%             consumos = [consumos; potKWh];
%         end;
%         resto = (duracao - floor(duracao));
%         if(resto>0);
%             consumos = [consumos; resto*potKWh];
%         end;
%         consumos = round(consumos, 5);
% 
%         % Gerando horarios
%         qtdHorarios = length(consumos);
% 
%         % Gerando horarios aleatorios (dentro do intervalo)
%         if(dispositivo.Inicio <= dispositivo.Fim);
%             horarios = horarios(ismember(horarios,dispositivo.Inicio:dispositivo.Fim-1));
%         else    
%             horarios = horarios(ismember(horarios,[dispositivo.Inicio:24,1:dispositivo.Fim-1]));    
%         end;
%         horarios = horarios(randperm(length(horarios),qtdHorarios));
%         
%     end;
    
end

% Classe  3: Consumo Nao-Elastico, Nao-Interruptivel
function [horarios, consumos] = cons_nEnI(dispositivo, H)
    horarios = 1:H;
    consumos = zeros(1, H);
    
    if(dispositivo.ConsPlanejado > 0);
        
        % Gerando consumos aleatorios (dentro do planejado)
        consumos = [];
        potKWh = (dispositivo.PotMaxima/1000);
        duracao = dispositivo.ConsPlanejado/potKWh;
        for i = 1:floor(duracao);
            consumos = [consumos; potKWh];
        end;
        resto = (duracao - floor(duracao));
        if(resto>0);
            consumos = [consumos; resto*potKWh];
        end;
        consumos = round(consumos, 5);
        
        % Gerando horarios
        qtdHorarios = length(consumos);
        
        % Gerando horarios aleatorios (dentro do intervalo)
        if(~isequal(duracao,H));
            if(dispositivo.Inicio <= dispositivo.Fim);
                horarios = horarios(ismember(horarios,dispositivo.Inicio:dispositivo.Fim-1));
            else
                horarios = horarios(ismember(horarios,[dispositivo.Inicio:24,1:dispositivo.Fim-1]));
            end;
            inicio = randi(length(horarios)-qtdHorarios+1);
            horarios = horarios(inicio:inicio+(qtdHorarios-1));
        end;
    end;
end