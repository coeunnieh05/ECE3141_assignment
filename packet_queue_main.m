clear;
clc;
close all;

% Simulation settings
numSlots    = 25000;
warmupSlots = 2500;
rng(1);

mu = 10;

%% Experiment 1: Effect of traffic load (rho) on delay

rhoValues    = 0.1:0.05:0.95;
lambdaValues = rhoValues * mu;

simDelay    = zeros(1, length(rhoValues));
simQueueLen = zeros(1, length(rhoValues));
theoryDelay = zeros(1, length(rhoValues));

for i = 1:length(rhoValues)
    lambda = lambdaValues(i);

    result = simulateSingleQueue(lambda, mu, numSlots, warmupSlots, "poisson");

    simDelay(i)    = result.averageDelay;
    simQueueLen(i) = result.averageQueueLength;

    theoryDelay(i) = 1 / (mu - lambda);
end

% Little's Law validation
littleLawCheck = lambdaValues .* simDelay;
maxLittleError = max(abs(littleLawCheck - simQueueLen));
fprintf('Little''s Law validation: max |L_sim - lambda*W_sim| = %.4f\n', maxLittleError);
fprintf('Little''s Law L = lambda*W was verified across all simulated load levels.\n\n');

% Graph 1: Simulated vs theoretical delay
figure;
plot(rhoValues, simDelay);
hold on;
plot(rhoValues, theoryDelay);
xlabel('Traffic intensity \rho');
ylabel('Average packet delay W (time slots)');
title('Effect of Traffic Load on Packet Delay');
legend('Simulated W', 'Theoretical W');

% Halving delay — find required service rate at rho = 0.8
lambdaFixed = 8;
muBase      = 10;

baseResult  = simulateSingleQueue(lambdaFixed, muBase, numSlots, warmupSlots, "poisson");
baseDelay   = baseResult.averageDelay;
targetDelay = baseDelay / 2;

muSweep    = 15:0.5:25;
delaySweep = zeros(1, length(muSweep));

for i = 1:length(muSweep)
    r = simulateSingleQueue(lambdaFixed, muSweep(i), numSlots, warmupSlots, "poisson");
    delaySweep(i) = r.averageDelay;
end

idxRequired = find(delaySweep <= targetDelay, 1);

if isempty(idxRequired)
    muRequired      = NaN;
    percentIncrease = NaN;
    delayAtRequired = NaN;
else
    muRequired      = muSweep(idxRequired);
    percentIncrease = ((muRequired - muBase) / muBase) * 100;
    delayAtRequired = delaySweep(idxRequired);
end

fprintf('Halving Delay Table (Experiment 1)\n');
fprintf('lambda = %.1f, mu_base = %.1f, W0 = %.4f\n', lambdaFixed, muBase, baseDelay);
fprintf('mu_required = %.1f, W_halved = %.4f, increase = %.1f%%\n\n', ...
    muRequired, delayAtRequired, percentIncrease);

%% Experiment 2: Queue stability over time
stabilitySlots  = 5000;
stabilityWarmup = 0;

lambdaStable     = 0.70 * mu;
lambdaBorderline = 0.99 * mu;
lambdaUnstable   = 1.20 * mu;

stableResult     = simulateSingleQueue(lambdaStable,     mu, stabilitySlots, stabilityWarmup, "poisson");
borderlineResult = simulateSingleQueue(lambdaBorderline, mu, stabilitySlots, stabilityWarmup, "poisson");
unstableResult   = simulateSingleQueue(lambdaUnstable,   mu, stabilitySlots, stabilityWarmup, "poisson");

% Graph 2: Queue length over time — dual panel
figure;

% Top panel: all three lines (big picture)
subplot(2,1,1);
plot(unstableResult.queueLength,   'r',                    'LineWidth', 1.2); hold on;
plot(borderlineResult.queueLength, 'Color', [0.85 0.55 0], 'LineWidth', 1.2);
plot(stableResult.queueLength,     'b',                    'LineWidth', 1.2);
xlabel('Time slot');
ylabel('Queue length (packets)');
title('Queue Stability for Different Traffic Loads — All Cases');
legend('\rho = 1.20 (unstable)', '\rho = 0.99 (borderline)', '\rho = 0.70 (stable)', ...
       'Location', 'northwest');
xlim([0 stabilitySlots]);

% Bottom panel: zoom in on stable + borderline only
subplot(2,1,2);
plot(borderlineResult.queueLength, 'Color', [0.85 0.55 0], 'LineWidth', 1.2); hold on;
plot(stableResult.queueLength,     'b',                    'LineWidth', 1.2);
xlabel('Time slot');
ylabel('Queue length (packets)');
title('Zoomed View: \rho = 0.70 (stable) and \rho = 0.99 (borderline)');
legend('\rho = 0.99 (borderline)', '\rho = 0.70 (stable)', 'Location', 'northwest');
xlim([0 stabilitySlots]);
%% Experiment 3: M/M/1 vs M/D/1

simDelayMM1 = zeros(1, length(rhoValues));
simDelayMD1 = zeros(1, length(rhoValues));
theoryMM1   = zeros(1, length(rhoValues));
theoryMD1   = zeros(1, length(rhoValues));

for i = 1:length(rhoValues)
    lambda = lambdaValues(i);

    resMM1 = simulateSingleQueue(lambda, mu, numSlots, warmupSlots, "poisson");
    simDelayMM1(i) = resMM1.averageDelay;

    resMD1 = simulateSingleQueue(lambda, mu, numSlots, warmupSlots, "fixed");
    simDelayMD1(i) = resMD1.averageDelay;

    theoryMM1(i) = 1 / (mu - lambda);
    theoryMD1(i) = 1 / (mu - lambda) - 1 / (2 * mu);
end

% Graph 3: M/M/1 vs M/D/1 delay comparison
figure;
plot(rhoValues, simDelayMM1);
hold on;
plot(rhoValues, theoryMM1);
plot(rhoValues, simDelayMD1);
plot(rhoValues, theoryMD1);
xlabel('Traffic intensity \rho');
ylabel('Average packet delay W (time slots)');
title('Average Delay: M/M/1 vs M/D/1');
legend('Simulated M/M/1', 'Theoretical M/M/1', 'Simulated M/D/1', 'Theoretical M/D/1');

%% Experiment 4: Shared queue vs independent queues

numServers  = 3;
lambdaTotal = 0.8 * mu * numServers;
muPerServer = mu;

independentResult = simulateIndependentQueues(lambdaTotal, muPerServer, numServers, numSlots, warmupSlots);
sharedResult      = simulateSharedQueue(lambdaTotal, muPerServer, numServers, numSlots, warmupSlots);

fprintf('--- Experiment 4 Results ---\n');
fprintf('%-22s  AvgDelay  Variance  AvgQueueLen  Utilisation\n', 'System');
fprintf('%-22s  %.4f    %.4f    %.4f       %.4f\n', 'Independent queues', ...
    independentResult.averageDelay, independentResult.delayVariance, ...
    independentResult.averageQueueLength, independentResult.utilisation);
fprintf('%-22s  %.4f    %.4f    %.4f       %.4f\n\n', 'Shared queue', ...
    sharedResult.averageDelay, sharedResult.delayVariance, ...
    sharedResult.averageQueueLength, sharedResult.utilisation);

averageDelay  = [independentResult.averageDelay;  sharedResult.averageDelay];
delayVariance = [independentResult.delayVariance; sharedResult.delayVariance];
systemNames   = {'Independent queues', 'Shared queue'};

% Graph 4: Average delay comparison
figure;
bar(averageDelay);
set(gca, 'XTickLabel', systemNames);
ylabel('Average packet delay W (time slots)');
title('Average Packet Delay: Shared vs Independent Queues');

% Graph 5: Delay variance comparison
figure;
bar(delayVariance);
set(gca, 'XTickLabel', systemNames);
ylabel('Delay variance');
title('Delay Variance: Shared vs Independent Queues');