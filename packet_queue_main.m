clear;
clc;
close all;

% Simulation settings
numSlots = 100000;        % total number of time slots
warmupSlots = 10000;      % ignore early transient behaviour
rng(1);                   % keeps random results repeatable

% Base service rate
mu = 5;                   % average service rate in packets per time slot

%% Experiment 1: Effect of traffic load and theory comparison

% Keep service rate fixed
mu = 5;                         % average service rate in packets per slot

% Use only lambda values below mu for stable operation
lambdaValues = 1:0.5:4.8;       % average arrival rates in packets per slot
rhoValues = lambdaValues ./ mu; % router utilisation

% Store simulation and theory results
simDelay = zeros(size(lambdaValues));
simQueueLength = zeros(size(lambdaValues));
theoryDelay = zeros(size(lambdaValues));
littleLawDelay = zeros(size(lambdaValues));

for i = 1:length(lambdaValues)

    lambda = lambdaValues(i);

    % Run single router queue simulation
    result = simulateSingleQueue(lambda, mu, numSlots, warmupSlots, "poisson");

    % Store simulated average delay and queue length
    simDelay(i) = result.averageDelay;
    simQueueLength(i) = result.averageQueueLength;

    % M/M/1 theoretical average time in the system
    theoryDelay(i) = 1 / (mu - lambda);

    % Little's Law estimate of delay
    littleLawDelay(i) = simQueueLength(i) / lambda;
end

% Plot simulated delay and theoretical delay
figure;
plot(rhoValues, simDelay, 'o-');
hold on;
plot(rhoValues, theoryDelay, 'x-');
xlabel('Traffic intensity, \rho = \lambda / \mu');
ylabel('Average packet delay, W');
title('Effect of Traffic Load on Packet Delay');
legend('Simulation', 'M/M/1 theory', 'Location', 'northwest');
grid on;

% Plot average queue length
figure;
plot(rhoValues, simQueueLength, 'o-');
xlabel('Traffic intensity, \rho = \lambda / \mu');
ylabel('Average queue length, L');
title('Effect of Traffic Load on Buffer Fullness');
grid on;

% Plot direct simulated delay and Little's Law estimate
figure;
plot(rhoValues, simDelay, 'o-');
hold on;
plot(rhoValues, littleLawDelay, 'x-');
xlabel('Traffic intensity, \rho = \lambda / \mu');
ylabel('Average packet delay, W');
title('Little''s Law Check');
legend('Direct delay measurement', 'L / \lambda estimate', 'Location', 'northwest');
grid on;

% Create result table for report and checking
experiment1Table = table(lambdaValues', rhoValues', simDelay', theoryDelay', ...
    littleLawDelay', simQueueLength', ...
    'VariableNames', {'lambda', 'rho', 'SimDelay', 'TheoryDelay', ...
    'LittleLawDelay', 'SimQueueLength'});

disp(experiment1Table);
%% Experiment 2: Queue stability over time
lambdaStable = 3.0;       % rho = 0.60
lambdaBorderline = 4.9;   % rho = 0.98
lambdaUnstable = 5.5;     % rho = 1.10

% Simulate three different traffic loads
stableResult = simulateSingleQueue(lambdaStable, mu, numSlots, warmupSlots, "poisson");
borderlineResult = simulateSingleQueue(lambdaBorderline, mu, numSlots, warmupSlots, "poisson");
unstableResult = simulateSingleQueue(lambdaUnstable, mu, numSlots, warmupSlots, "poisson");

% Plot queue length over time
figure;
plot(stableResult.queueLength);
hold on;
plot(borderlineResult.queueLength);
plot(unstableResult.queueLength);
xlabel('Time slot');
ylabel('Queue length');
title('Queue Stability for Different Traffic Loads');
legend('\rho = 0.60', '\rho = 0.98', '\rho = 1.10', 'Location', 'northwest');
grid on;


%% Experiment 3: Service rate required to halve delay

% Choose one arrival rate near high utilisation
lambdaFixed = 4.0;
muBase = 5.0;

% Simulate the base case
baseResult = simulateSingleQueue(lambdaFixed, muBase, numSlots, warmupSlots, "poisson");
baseDelay = baseResult.averageDelay;
targetDelay = baseDelay / 2;

% Test a range of service rates
muValues = 5:0.25:10;
delayValues = zeros(size(muValues));

for i = 1:length(muValues)
    currentMu = muValues(i);

    % Run the queue with the new service rate
    result = simulateSingleQueue(lambdaFixed, currentMu, numSlots, warmupSlots, "poisson");

    % Store average delay
    delayValues(i) = result.averageDelay;
end

% Find the first service rate that gives half the original delay
indexRequired = find(delayValues <= targetDelay, 1);

if isempty(indexRequired)
    muRequired = NaN;
    percentageIncrease = NaN;
else
    muRequired = muValues(indexRequired);
    percentageIncrease = ((muRequired - muBase) / muBase) * 100;
end

% Plot delay against service rate
figure;
plot(muValues, delayValues, 'o-');
hold on;
yline(targetDelay);
xlabel('Average service rate, \mu');
ylabel('Average packet delay, W');
title('Service Rate Required to Halve Delay');
grid on;

% Print key result
fprintf('Base service rate mu = %.2f packets/slot\n', muBase);
fprintf('Base average delay = %.3f time slots\n', baseDelay);
fprintf('Target delay = %.3f time slots\n', targetDelay);

if ~isnan(muRequired)
    fprintf('Required mu = %.2f packets/slot\n', muRequired);
    fprintf('Percentage increase in mu = %.2f%%\n', percentageIncrease);
else
    fprintf('Target delay was not reached in the tested mu range.\n');
end

%% Experiment 4: Shared queue vs independent queues

% Multi-server settings
numServers = 3;
lambdaTotal = 12;        % total packet arrival rate
muPerServer = 5;         % service rate for each server

% Run independent queues
independentResult = simulateIndependentQueues(lambdaTotal, muPerServer, ...
    numServers, numSlots, warmupSlots);

% Run one shared queue with multiple servers
sharedResult = simulateSharedQueue(lambdaTotal, muPerServer, ...
    numServers, numSlots, warmupSlots);

% Store comparison results
systemNames = {'Independent queues'; 'Shared queue'};

averageDelay = [independentResult.averageDelay; sharedResult.averageDelay];
delayVariance = [independentResult.delayVariance; sharedResult.delayVariance];
averageQueueLength = [independentResult.averageQueueLength; sharedResult.averageQueueLength];
utilisation = [independentResult.utilisation; sharedResult.utilisation];

experiment4Table = table(systemNames, averageDelay, delayVariance, ...
    averageQueueLength, utilisation);

disp(experiment4Table);

% Plot average delay comparison
figure;
bar(averageDelay);
set(gca, 'XTickLabel', systemNames);
ylabel('Average packet delay, W');
title('Average Packet Delay Comparison');
grid on;

% Plot delay variance comparison
figure;
bar(delayVariance);
set(gca, 'XTickLabel', systemNames);
ylabel('Delay variance');
title('Delay Variation Comparison');
grid on;