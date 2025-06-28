
t = 1:1:540;

combat = SimulatedCombatPeriods(t, t(end));
combatedges = find(diff(combat)~=0)

if mod(length(combatedges), 2) == 1
    %If there are an odd number of combat transitions, the end of
    %the entire duration will be the ending transition
    % of the last combat period
    combatedges(end + 1) = t(end);
end

diff(combatedges)

plot(t, 5*SimulatedCombatPeriods(t, t(end)));
hold on;

for idx = 1:2:length(combatedges)
    fprintf("%d - %d\n\n", combatedges(idx), combatedges(idx+1));
    pulses = pulses + BlackEclipseSim(t, combatedges(idx), combatedges(idx+1));
end

%pulses = BlackEclipseSim(t, 53, 269) + BlackEclipseSim(t, 323, 431)  + BlackEclipseSim(t, 485, 539) ;
plot(t, pulses); 
ylim([0 5]);
hold off;

function v = SimulatedCombatPeriods(t, duration)
% 240, 120, 60
movingperiod = (0.3 * duration)/3;
a = (0.7*duration)*(4/7);
v = UnitStep(t - movingperiod) - UnitStep(t - movingperiod - a) + ...
    UnitStep(t - 2*movingperiod - a) - UnitStep(t - 2*movingperiod - a - a/2) + ...
    UnitStep(t - 3*movingperiod - a - a/2) - UnitStep(t - 3*movingperiod - a - a/2 - a/4);

end

function v = BlackEclipseSim(t, start, stop)
    v = (mod(t - start - 30, 90) < (60)) & t < stop & t >= start;
end


% function v = BlackEclipseSim(t, combat)
%     combatedges = find(diff(combat) ~= 0);
%     combatdurations = diff(combatedges);
%     combatstarts = combatedges(1:2:end)
%     combatends = combatedges(2:2:end)
%     
%     idx = intersect(find(combatstarts <= t), find(combatends > t));
%     if ~isempty(idx)
%         
%     else
% 
%     end
% 
%     
%     v = combat .* (mod(t - laststart, 90) < 60);
% end


function y = delayed_pulse_response(t, pulse)
    y = zeros(size(t));
    size(t)
    size(y)

    dt = t(2) - t(1);

    rising_edges = find(diff(pulse) > 0) +1;
    last_end_time = -Inf;
    for idx = 1:length(rising_edges)
        pulse_time = rising_edges(idx)

        if pulse_time >= last_end_time
            on_time  = pulse_time + 30;
            off_time = min(length(t), pulse_time + 90);
            y = y | (t >= on_time & t < off_time);
            %y(on_time:dt:off_time) = 1;
            last_end_time = off_time;
        end
    end
end