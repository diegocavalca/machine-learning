function resultados( agendamentoOtimo, dadosAgendOtimo, agendamentoRef, ...
                    tarifa, dispositivos, histBest)

%     % Caso de referencia
%     [cDiarioRef, perfilRef, consPotenciaRef, consValorRef, consBrutoRef, ...
%         eGerRef, PARRef] = custo(agendamentoRef, dispositivos, tarifa);
    
    % Melhor caso (otimizado)
%     [cDiario, perfil, consPotencia, consValor, consBruto, eGer, PAR] = ... 
%         custo(agendamentoOtimo, dispositivos, tarifa);

%{ cDiario, consPotencia, consValor, consPotBruto, vrTotal, PAR }
    global pico;
    
    cDiario = dadosAgendOtimo{1};
    %perfil = dadosAgendOtimo{2};
    %fitness, consPotLiquido, consPotBruto, consValor, ...
            %vrTotal, consMaximo, consMedio, consPico, PAR
    consPotencia= dadosAgendOtimo{2};
    consBruto = dadosAgendOtimo{3};
    consValor = dadosAgendOtimo{4};    
    %eGer = dadosAgendOtimo{6};
    vrTotal = dadosAgendOtimo{5};
    consMaximo = dadosAgendOtimo{6};
    consMedio  = dadosAgendOtimo{7}; 
    consPico   = dadosAgendOtimo{8};
    PAR = dadosAgendOtimo{9};
    
    % RESULTADOS COMPARATIVOS
    fprintf('\n########### RESULTADOS ###########\n\n');
    %disp(strcat('Fitness Ref: ', num2str(cDiarioRef)));
    fprintf('Fitness Otimizado: %.4f\n', cDiario);
    fprintf('Valor Otimizado: %.4f\n', vrTotal);
    fprintf('Cons. Maximo Otimizado: %.4f\n', consMaximo);
    fprintf('Cons. Medio Otimizado: %.4f\n', consMedio);
    fprintf('Cons. Pico Otimizado: %.4f\n', consPico);
    fprintf('PAR Otimizado: %.4f\n', PAR);
    
    % Grafico 1 - Convergencia da otimizacao
    figure;
    plot(histBest);
    title('Convergencia do Algoritmo de Otimizacao');
    grid on;

    % Grafico 2 - Tarifa
    figure;
    stairs(tarifa);
    xlim([1, 25]);
    set(gca,'XTick',0:1:24, 'FontSize', 12);
    ylim([0.3, 0.55]);
    set(gca,'YTick',0.3:0.05:0.55);
    set(gca, 'Position', get(gca, 'OuterPosition') - ...
                        get(gca, 'TightInset') * [-1 0 1 0; 0 -1 0 1; 0 0 1 0; 0 0 0 1]);
    xlabel('Hora','FontSize', 14);
    ylabel('Valor (R$)','FontSize', 14);
    grid on;
    %     figure;
    %     stairs(tarifa);
    %     xlim([1, 25]);
    %     set(gca,'XTick',0:1:24);
    %     ylim([0, 0.8]);
    %     set(gca,'YTick',0:0.1:0.8);
    %     title('Tarifa (Time Of Use - TOU)')
    %     xlabel('Hora');
    %     ylabel('Valor (R$)');
    %     grid on;

%     % Grafico 3 - Consumo POTENCIA
%     figure;
%     plot(consPotenciaRef); % Agendamento inicial
%     hold on;
%     p1 = plot(sum(consBrutoRef, 1)); % Agendamento inicial
%     hold on;
%     p2 = plot(consPotencia); % Agendamento otimizado
%     xlim([1, 24]);
%     set(gca,'XTick',0:1:24);
%     title('Consumo Diario em Potencia')
%     xlabel('Hora');
%     ylabel('Potencia consumida (kWh)');
%     legend([p1 p2], 'Referencia', 'Proposto', 'Location', 'best');
%     grid on;
    
%     % Residencias contempladas no estudo
     residencias = unique(dispositivos.Residencia)'; 
%     
    % Grafico 4 - Planejamentos
    planejamento = reshape(agendamentoOtimo,[24,size(dispositivos,1)])';
    for i = residencias; % Para cada residencia
        disps = i * 40;
        % Otimizado
        plotAgendamento(planejamento(disps-39:disps,:), dispositivos(disps-39:disps,:), ...
            pico, sprintf('Agendamento Otimizado - Residência %i',i), 5);
        grid on;
    end;
    
    % GRAFICO 5 - Consumo bruto por residencia (Pot/H)
    fWidth = 14.7 * 37.795276;    % cm to pixel
    fHeight = 3.9333 * 37.795276; % cm to pixel
    for i = residencias; % Para cada residencia
        figure;
        % Definir tamanho
        pos = get(gcf, 'Position');
        set(gcf, 'Position', [pos(1) pos(2) fWidth, fHeight]);
        disps = i * 40;
        %subplot(max(residencias),1,i);
        bar(sum(consBruto(disps-39:disps,:),1));
        xlim([1, 24]);
        set(gca,'XTick', 0:1:24, ...
                'Position', get(gca, 'OuterPosition') - ...
                            get(gca, 'TightInset') * [-2.5 0 2 0; ...
                                                      0 -2 0 2.5; ...
                                                      0 0 2 0; ...
                                                      0 0 0 2]);
        ylim([0, 8]);
        set(gca,'YTick',0:2:8);
        xlabel('Hora');
        ylabel('Consumo (kWh)');
        title(sprintf('Residência %i',i));
        grid on;
            % Delimitar horario de pico
            hold on;
            plot([min(pico) min(pico)],[0 40], '--', 'Color', 'r'); % Inicio 
            plot([max(pico) max(pico)],[0 40], '--', 'Color', 'r'); % Fim 
            hold off;
    end;
    
    % GRAFICO 6 - Detalhes de consumo do grupo (microgrid)
    figure;
    fWidth = 16 * 37.795276;    % cm to pixel
    fHeight = 5.35 * 37.795276; % cm to pixel
    % Definir tamanho
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) fWidth, fHeight]);
    bar(consPotencia); % plot
    xlim([1, 24]);
    set(gca,'XTick', 0:1:24, ...
            'Position', get(gca, 'OuterPosition') - ...
                        get(gca, 'TightInset') * [-2 0 2 0; ...
                                                  0 -2 0 2.5; ...
                                                  0 0 2 0; ...
                                                  0 0 0 2]);
    xlabel('Hora', 'FontSize', 12);
    ylabel('Consumo (kWh)', 'FontSize', 12);
    title('Planejamento otimizado para o grupo de consumidores', 'FontSize', 12);
    grid on;
        % Delimitar horario de pico
        hold on;
        plot([min(pico) min(pico)], get(gca,'ylim'), '--','Color', 'r'); % Inicio 
        plot([max(pico) max(pico)], get(gca,'ylim'), '--', 'Color', 'r'); % Fim 
        hold off;
    %subplot(2,1,2);
    figure;
    % Definir tamanho
    pos = get(gcf, 'Position');
    set(gcf, 'Position', [pos(1) pos(2) fWidth, fHeight]);
    plot(consValor,'-s', 'Color', [1 0.6 0], 'MarkerFaceColor', [1 0.6 0]);
    ylim([0, 4]);
    set(gca,'YTick',0:0.5:4);
    xlim([1, 24]);
    set(gca,'XTick', 0:1:24, ...
            'Position', get(gca, 'OuterPosition') - ...
                        get(gca, 'TightInset') * [-2 0 2 0; ...
                                                  0 -2 0 2.5; ...
                                                  0 0 2 0; ...
                                                  0 0 0 2]);
    xlabel('Hora', 'FontSize', 12);
    ylabel('Valor (R$)', 'FontSize', 12);
    title('Tarifa de consumo resultante', 'FontSize', 12);
    grid on;
        % Delimitar horario de pico
        hold on;
        plot([min(pico) min(pico)], get(gca,'ylim'), '--', 'Color', 'r'); % Inicio 
        plot([max(pico) max(pico)], get(gca,'ylim'), '--', 'Color', 'r'); % Fim 
        hold off;
    
%    %%%% Gráfico 7 - Comparar PSO's
%     figure;
%     fWidth  = 14.3 * 37.795276; % cm to pixel
%     fHeight = 11.2 * 37.795276; % cm to pixel
%     % Definir tamanho
%     pos = get(gcf, 'Position');
%     set(gcf, 'Position', [pos(1) pos(2) fWidth, fHeight]);
% 
%     hold on;
%     plot(histBest);
%     plot(histBestLDWPSO);
%     plot(histBestPSO);
%     hold off;
%     
%     ylim([23, 35]);
%     set(gca,'YTick', 23:1:35);
%     xlim([0, 1000]);
%     set(gca,'XTick', 0:100:1000, ...
%             'Position', get(gca, 'OuterPosition') - ...
%                         get(gca, 'TightInset') * [-2 0 1.5 0; ...
%                                                   0 -2 0 2; ...
%                                                   0 0 2 0; ...
%                                                   0 0 0 2]);
%     xlabel('Iteração', 'FontSize', 12);
%     ylabel('Fitness', 'FontSize', 12);
%     grid on;
%     
%     ax = gca; % Get handle to current axes.
%     ax.GridAlpha = 0.05;  % Make grid lines less transparent.
%     legend({'SPM-PSO','LDW-PSO','PSO'}, 'FontSize', 12);
end

function plotAgendamento( planejamento, dispositivos, pico, titulo, lineWidth )
   
     figure;

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
    nomes = strcat(cellstr(dispositivos.Aparelho),{' ('},num2str(dispositivos.Residencia),{')'}); 
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
    set(gca,'XTick',0:1:24);
    
    ylim([0, totalDisps+1]);
    set(gca,'YTick',0:1:totalDisps+1);
    set(gca,'YTickLabel', [' ',nomes',' ']');
    
    xlabel('Hora');
    title(titulo);
    grid on;
    
    % Delimitar horario de pico
    hold on;
    plot([min(pico) min(pico)],[0 totalDisps+1], 'Color', 'r'); % Inicio 
    plot([max(pico) max(pico)],[0 totalDisps+1], 'Color', 'r'); % Fim 
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