% Single queue simulation function
function result = simulateSingleQueue(lambda, mu, numSlots, warmupSlots, serviceMode)

    % Stores queue length at each time slot
    queueLength = zeros(1, numSlots);

    % Stores packet arrival times for packets waiting in the queue
    arrivalTimes = [];

    % Stores delay values for completed packets
    packetDelays = [];

    % Counts packets entering and leaving the system
    totalArrivals = 0;
    totalDepartures = 0;

    for t = 1:numSlots
        % Generate number of new packets arriving in this time slot
        numArrivals = poissrnd(lambda);
        totalArrivals = totalArrivals + numArrivals;
        % Add arrival time for each new packet
        if numArrivals > 0
            arrivalTimes = [arrivalTimes, t * ones(1, numArrivals)];
        end

        % Generate service capacity for this time slot
        if serviceMode == "poisson"
            serviceCapacity = poissrnd(mu);
        elseif serviceMode == "fixed"
            serviceCapacity = floor(mu);
        else
            error("Invalid service mode. Use 'poisson' or 'fixed'.");
        end

        % The server cannot remove more packets than currently exist
        numDepartures = min(serviceCapacity, length(arrivalTimes));
        totalDepartures = totalDepartures + numDepartures;

        % Record delay for departed packets
        if numDepartures > 0
            departedArrivalTimes = arrivalTimes(1:numDepartures);
            delaysThisSlot = t - departedArrivalTimes;

            % Only record delay after warm-up period
            if t > warmupSlots
                packetDelays = [packetDelays, delaysThisSlot];
            end

            % Remove departed packets from the front of the FIFO queue
            arrivalTimes(1:numDepartures) = [];
        end

        % Record queue length after arrivals and service
        queueLength(t) = length(arrivalTimes);
    end

    % Calculate steady-state average queue length
    steadyQueueLength = queueLength(warmupSlots + 1:end);
    averageQueueLength = mean(steadyQueueLength);

    % Calculate average delay of completed packets
    averageDelay = mean(packetDelays);

    % Store results in one structure
    result.queueLength = queueLength;
    result.packetDelays = packetDelays;
    result.averageDelay = averageDelay;
    result.averageQueueLength = averageQueueLength;
    result.totalArrivals = totalArrivals;
    result.totalDepartures = totalDepartures;
end