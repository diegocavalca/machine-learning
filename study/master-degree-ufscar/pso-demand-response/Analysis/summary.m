close all;

% % Grafico 0 - Tarifa
% figure;
% stairs(tarifa);
% xlim([1, 25]);
% set(gca,'XTick',0:1:24);
% ylim([0.3, 0.55]);
% set(gca,'YTick',0.3:0.05:0.55);
% %title('Tarifa (Time Of Use - TOU)')
% xlabel('Hora');
% ylabel('Valor (R$)');
% grid on;

% Convergencia dos algoritmos
figure;
plot(alg0_histBest,'DisplayName','PSO');
hold on;
plot(alg1_histBest,'DisplayName','LDW-PSO');
hold on;
plot(alg3_histBest,'DisplayName','SPM-PSO');
hold on;
ylim([23, 35]);
set(gca,'YTick',23:1:35);
%title('Convergência dos algoritmos')
xlabel('Iteration');
ylabel('Fitness');
grid on;
leg = legend('show');%,'Orientation','horizontal', 'Location','southoutside');
fontsize = 12;
set(gca,'FontSize', fontsize);
set(leg, 'FontSize', fontsize);
% File -> Export...
%print(gcf,'foo.png','-dpng','-r300')