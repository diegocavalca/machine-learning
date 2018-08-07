function plotAgendamentoLegendado( planejamento, dispositivos, pico, titulo, lineWidth )
   
    figure;
    fWidth = 24.26 * 37.795276;    % cm to pixel
    fHeight = 13.5 * 37.795276; % cm to pixel
    % Definir tamanho
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) fWidth, fHeight]);

    % Gerar cronograma a partir do planejamento de consumo
    %planejamento = reshape(nuvem(n,:),[24,totalDisps])';
    totalDisps = size(planejamento,1);
    cronograma = zeros(totalDisps, 24);
    for d = 1:totalDisps;        
        for t = 1:24;
            cronograma(d,t) = planejamento(d,t)/(dispositivos.PotMaxima(d)/1000);
        end;
    end;
    
    % Montar grafico
    ps = [];
    nomes = cellstr(dispositivos.Aparelho);
    colors = lines(totalDisps);
    hold on;
    for d = (1:totalDisps);
        
        % Localizar horarios de inicio
        inicio = find(cronograma(d,:)>0);
        
        % Verificar se o disp. eh escalado
        if(~isempty(inicio)); 
            fim = inicio + cronograma(d, inicio); % Ini + Duracao

            execucao = [];

            % Validar horarios
            hIni = [];
            hFim = [];
            for i = 1:length(fim);            
                if fim(i) > 25;
                    hIni = [hIni; inicio(i); 1];
                    hFim = [hFim; 25; (fim(i) - 24)];
                    %execucao = [cronograma(i) 1; 25 (fim(i) - 24)];
                else
                    hIni = [hIni; inicio(i)];
                    hFim = [hFim; fim(i)];
                    %execucao = [cronograma(i); fim(i)];
                end;    
            end;
            execucao = [hIni'; hFim'];
            dim = [d ; d];
            p = plot(execucao, dim, ...
                        'LineWidth', lineWidth, ...
                        'color', colors(d,:));
            ps = [ps; p(1)];
        end;
    end;
    
    xlim([1, 25]);
    set(gca,'XTick', 0:1:24, ...
        'Position', get(gca, 'OuterPosition') - ...
                    get(gca, 'TightInset') * [-9 0 8.3 0; ...
                                              0 -2 0 1.2; ...
                                              0 0 2 0; ...
                                              0 0 0 2]);
    
    ylim([0, totalDisps+1]);
    set(gca,'YTick',0:1:totalDisps+1);
    set(gca,'YTickLabel', [' ',nomes',' ']', 'FontSize', 12);
    
    xlabel('Hora', 'FontSize', 12);
    %title(titulo);
    grid on;
    
    % Delimitar horario de pico
    hold on;
    plot([min(pico) min(pico)],[0 totalDisps+1], '--', 'Color', 'r'); % Inicio 
    plot([max(pico) max(pico)],[0 totalDisps+1], '--', 'Color', 'r'); % Fim 
    hold off;
    %legend(ps, nomes, 'Location', location);

%     %grid on;
%     figure;
%     
%     %duracao = repelem(cell2mat(dispositivos(:,3))', cell2mat(dispositivos(:,4))');
%     %nomes = repelem(dispositivos(:,1), cell2mat(dispositivos(:,4))')';    
%     duracao = dispositivos.Duracao';
%     % Incluindo num. da residencia no nome do aparelho
%     nomes = strcat(cellstr(dispositivos.Aparelho),{' ('},num2str(dispositivos.Residencia),{')'}); 
%     
%     qtdCiclos = length(duracao);
%     ps = [];
%     colors = lines(qtdCiclos);
%     fim = cronograma + (duracao/60);
%     hold on;
%     for i = (1:qtdCiclos);
%         if fim(i) > 25;
%             execucao = [cronograma(i) 1; 25 (fim(i) - 24)];
%             dim = [i; i];
%         else
%             execucao = [cronograma(i); fim(i)];
%             dim = [i; i];
%         end;    
%         p = plot(execucao, dim, ...
%                     'LineWidth', lineWidth, ...
%                     'color', colors(i,:));
% 
%         ps = [ps; p(1)];
%         %legend(nomes(i));
%     end;
%     
%     xlim([1, 25]);
%     set(gca,'XTick',0:1:24);
%     
%     ylim([0, qtdCiclos+1]);
%     set(gca,'YTick',0:1:qtdCiclos+1);
%     set(gca,'YTickLabel', [' ',nomes',' ']');
%     
%     xlabel('Hora');
%     title(titulo);
%     %legend(ps, nomes, 'Location', location);
   
end