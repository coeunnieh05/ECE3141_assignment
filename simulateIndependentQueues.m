function result = simulateIndependentQueues(lambdaTotal, muPerServer, numServers, numSlots, warmupSlots)

    % Each server has its own FIFO queue
    arrivalTimes = cell(1, numServers);
    % Store total queue length across all queues
    totalQueueLength = zeros(1, numSlots);
    % Store packet delays after warm-up
    packetDelays = [];
    % Count service opportunities for utilisation
    totalServiceCapacity = 0;
    totalDepartures = 0;

    for t = 1:numSlots
        % Generate total arrivals for this time slot
        numArrivals = poissrnd(lambdaTotal);

        % Randomly assign each packet to one queue
        for p = 1:numArrivals
            queueIndex = randi(numServers);
            arrivalTimes{queueIndex} = [arrivalTimes{queueIndex}, t];
        end

        % Serve packets from each independent queue
        for s = 1:numServers

            % Each server has random service capacity
            serviceCapacity = poissrnd(muPerServer);
            totalServiceCapacity = totalServiceCapacity + serviceCapacity;

            % Server cannot remove more packets than its queue has
            numDepartures = min(serviceCapacity, length(arrivalTimes{s}));
            totalDepartures = totalDepartures + numDepartures;

            if numDepartures > 0

                % Get arrival times of departing packets
                departedArrivalTimes = arrivalTimes{s}(1:numDepartures);
                delaysThisSlot = t - departedArrivalTimes + 1;

                % Record delay only after warm-up
                if t > warmupSlots
                    packetDelays = [packetDelays, delaysThisSlot];
                end

                % Remove served packets from the FIFO queue
                arrivalTimes{s}(1:numDepartures) = [];
            end
        end

        % Record total packets waiting in all queues
        currentTotal = 0;
        for s = 1:numServers
            currentTotal = currentTotal + length(arrivalTimes{s});
        end

        totalQueueLength(t) = currentTotal;
    end

    % Use steady-state queue length only
    steadyQueueLength = totalQueueLength(warmupSlots + 1:end);

    % Store results
    result.averageDelay = mean(packetDelays);
    result.delayVariance = var(packetDelays);
    result.averageQueueLength = mean(steadyQueueLength);
    result.queueLength = totalQueueLength;
    result.utilisation = totalDepartures / totalServiceCapacity;
end
