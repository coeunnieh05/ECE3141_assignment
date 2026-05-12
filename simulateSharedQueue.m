function result = simulateSharedQueue(lambdaTotal, muPerServer, numServers, numSlots, warmupSlots)
    % One FIFO queue feeds all servers
    arrivalTimes = [];
    % Store queue length at each time slot
    queueLength = zeros(1, numSlots);
    % Store packet delays after warm-up
    packetDelays = [];
    % Count service opportunities for utilisation
    totalServiceCapacity = 0;
    totalDepartures = 0;

    for t = 1:numSlots
        % Generate total arrivals for this time slot
        numArrivals = poissrnd(lambdaTotal);

        % Add new packet arrival times to the shared queue
        if numArrivals > 0
            arrivalTimes = [arrivalTimes, t * ones(1, numArrivals)];
        end

        % Total service capacity from all servers
        serviceCapacity = poissrnd(numServers * muPerServer);
        totalServiceCapacity = totalServiceCapacity + serviceCapacity;

        % Servers cannot remove more packets than the queue has
        numDepartures = min(serviceCapacity, length(arrivalTimes));
        totalDepartures = totalDepartures + numDepartures;

        if numDepartures > 0

            % Get arrival times of departing packets
            departedArrivalTimes = arrivalTimes(1:numDepartures);
            delaysThisSlot = t - departedArrivalTimes;

            % Record delay only after warm-up
            if t > warmupSlots
                packetDelays = [packetDelays, delaysThisSlot];
            end

            % Remove served packets from the FIFO queue
            arrivalTimes(1:numDepartures) = [];
        end

        % Record current shared queue length
        queueLength(t) = length(arrivalTimes);
    end

    % Use steady-state queue length only
    steadyQueueLength = queueLength(warmupSlots + 1:end);

    % Store results
    result.averageDelay = mean(packetDelays);
    result.delayVariance = var(packetDelays);
    result.averageQueueLength = mean(steadyQueueLength);
    result.queueLength = queueLength;
    result.utilisation = totalDepartures / totalServiceCapacity;
end