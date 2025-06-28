[0, 50, 150/(150+120), 120 + 16; % Latent power 5 has a duty cycle of 150/(150 + 120) with 2 pieces of the Rey Dau set

];
clear;
baseattack = 220
baseaffinity = 15;

duration = 8*60 + 10 + 5;

t = 0:1:duration;
 
figure;
SumOfBuffsDat = SumOfBuffs(t, baseaffinity);
plot(t, ActuallyFighting(t)*100, ':');
hold on;

plot(t, 100*MaximumMight(t), ':');
plot(t, (15 * BlackEclipse(t)), '-');
plot(t, (50 * LatentPower(t)), '-');
plot(t, (30 * MaximumMight(t)), '-');
SumOfBuffsDat = SumOfBuffs(t, baseaffinity);
plot(t, SumOfBuffsDat, '-');
fourierresult = abs(fft(BlackEclipse(t) + MaximumMight(t) + LatentPower(t)));
freq = (0:length(fourierresult)-1)*100/length(fourierresult); 

% plot(t, ActuallyFighting(t).*(15 * BlackEclipse(t)), '-');
% plot(t, ActuallyFighting(t).*(50 * LatentPower(t)), '-');
% plot(t, ActuallyFighting(t).*(30 * MaximumMight(t)), '-');
% SumOfBuffsDat = SumOfBuffs(t, baseaffinity);
% plot(t, ActuallyFighting(t).*SumOfBuffsDat, '-');

ylim([0 110]);

% plot(t, 100*UnitStep(t), '--'); %Affinity Cap
hold off;
figure
plot(freq, fourierresult);
% 
% figure;
% plot(t, 100 * SimulatedCombatPeriods(t, t(end)), '-');
% hold on;
% % plot(t, 15*BlackEclipseSim(t + 10));
% % plot(t, 50* LatentPowerSim(t + 142));
% % plot(t, 30 * MaximumMightSim(t), '-');
% plot(t,  SimulatedCombatAffinity(t, t(end), baseaffinity));
% 
% ylim([0 110]);
% hold off;

% 
% EFRs = arrayfun(@(buffedaffinity) EVd([baseattack; buffedaffinity; 25]), ...
%     SumOfBuffs(t, baseaffinity));
% 
% 
% affinity_change_times = ...
%     find(diff(ActuallyFighting(t).*SumOfBuffs(t, baseaffinity)) ~= 0)
% FightOnlyAffinity = @(t) ActuallyFighting(t).*SumOfBuffs(t, baseaffinity);
% 
% affinity_levels = FightOnlyAffinity(affinity_change_times);
% affinity_durations = diff(affinity_change_times);
% 
% fightonlyindices = affinity_levels ~= 0;
% 
% avg_affinity_level = sum(affinity_levels(fightonlyindices) .* ...
%     affinity_durations(fightonlyindices)) / ...
%     sum(affinity_durations(fightonlyindices))

    duration = 8*60 + 10 + 5;
    t = 0:1:duration;
    buffopts = [3 5 3 2];
    simaffdata = HuntProfile.SimulatedCombatAffinityBuff(t, t(end), buffopts);
    simatkdata = HuntProfile.SimulatedCombatAttackBuff(t, t(end), buffopts);
    
    aff_change_times = find(diff(simaffdata)~=0) + 1
    atk_change_times = find(diff(simatkdata)~=0) + 1


    both_change_times = unique(sort([aff_change_times atk_change_times]))

    aff_lvls = simaffdata(both_change_times)
    atk_lvls = simatkdata(both_change_times)

    dur = diff(both_change_times)
    fight_idx = aff_lvls ~= 0
    fight_times = dur(fight_idx) - 1
    aff_fight = min(aff_lvls(fight_idx), 100)
    atk_fight = atk_lvls(fight_idx)
    total_fight_time = sum(fight_times)
    
%     aff_lvls = simaffdata(aff_change_times);
%     affdur = diff(aff_change_times);
%     
%     aff_fight_idx = aff_lvls ~= 0;
%     
%     aff_fight_times = affdur(aff_fight_idx) - 1; % Durations of the aff levels below
%     aff_fight = aff_lvls(aff_fight_idx);
%     aff_total_fight_time = sum(aff_fight_times);
%     
%     
% 
% 
% 
%     
%     atk_lvls = simatkdata(atk_change_times);
%     atkdur = diff(atk_change_times);
%     
%     atk_fight_idx = atk_lvls ~= 0;
%     
%     atk_fight_times = affdur(atk_fight_idx) - 1; % Durations of the aff levels below
%     atk_fight = aff_lvls(atk_fight_idx);
%     atk_total_fight_time = sum(atk_fight_times);



function v = SimulatedCombatAffinity(t, duration, baseaffinity)
%  v = (baseaffinity + (15 * BlackEclipseSim(t + 10) + ...
%     50 * LatentPowerSim(t + 142) + ...
%     30 * MaximumMightSim(t))) .* SimulatedCombatPeriods(t, duration);
 v = (baseaffinity + (15 * BlackEclipse(t + 10) + ...
    50 * LatentPower(t + 142) + ...
    30 * MaximumMight(t))) .* ActuallyFighting(t, duration);
end

function v = MaximumMightSim(t)
    v = ones(size(t));
end

function v = BlackEclipseSim(t)
    v = mod(t, 90) < 60;
end

function v = LatentPowerSim(t)
    v = mod(t, 270) < 150;
end

function v = SimulatedCombatPeriods(t, duration)
movingperiod = (0.3 * duration)/3;
a = (0.7*duration)*(4/7);
v = UnitStep(t - movingperiod) - UnitStep(t - movingperiod - a) + ...
    UnitStep(t - 2*movingperiod - a) - UnitStep(t - 2*movingperiod - a - a/2) + ...
    UnitStep(t - 3*movingperiod - a - a/2) - UnitStep(t - 3*movingperiod - a - a/2 - a/4);

end

function v = UnitStep(t)
    v = (t >= 0);
end

function val = SumOfBuffs(t, baseaffinity)
val = (15 * BlackEclipse(t) + 50 * LatentPower(t) + baseaffinity + ...
    30 * MaximumMight(t));
 
end

function bEnabled = ActuallyFighting(t)
    bEnabled = ...
        UnitStep(t - 51) - UnitStep(t - 260) + ...
        UnitStep(t - 304) - UnitStep(t - 404) + ...
        UnitStep(t - 442) - UnitStep(t - 490);
end

function bEnabled = MaximumMight(t)
    bEnabled = UnitStep(t) - UnitStep(t - 490);
end

function bEnabled = BlackEclipse(t)
% Black Eclipse will proc from curing frenzy, which done by dealing damage.
% Doing enough damage takes me approximately 30-35 seconds from the beginning
% of a combat, which means probably around 1200-1500 damage. The buff lasts
% for 60s
    bEnabled = ...
        (UnitStep(t - 81) - UnitStep(t - 142)) + ...
        (UnitStep(t - 171) - UnitStep(t - 231)) + ...
        (UnitStep(t - 341) - UnitStep(t - 401)) + ...
        (UnitStep(t - 472) - UnitStep(t - 490));
end

function bEnabled = LatentPower(t)
    bEnabled = ...
        UnitStep(t - 128) - UnitStep(t - 278) + ...
        UnitStep(t - 470) - UnitStep(t - 490);
end