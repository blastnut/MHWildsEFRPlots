classdef HuntProfile < handle
    properties

    end

    methods
        function avgefr = ComputeAverageEFRforWeapon(obj, skills, weapon, buffopts)

            if(sum(buffopts) == 0 || isempty(buffopts))
                avgefr = Weapon.EVd(weapon.WeaponStats([skills;0;0]));
            else
                duration = 8*60 + 10 + 5;
                t = 0:1:duration;

                simaffdata = HuntProfile.SimulatedCombatAffinityBuff(t, t(end), buffopts);
                simatkdata = HuntProfile.SimulatedCombatAttackBuff(t, t(end), buffopts);
                
                aff_change_times = find(diff(simaffdata)~=0) + 1;
                atk_change_times = find(diff(simatkdata)~=0) + 1;
            
            
                both_change_times = unique(sort([aff_change_times atk_change_times]));
            
                aff_lvls = simaffdata(both_change_times);
                atk_lvls = simatkdata(both_change_times);
            
                dur = diff(both_change_times);
                fight_idx = aff_lvls ~= 0;
                fight_times = dur(fight_idx) - 1;
                aff_fight = min(aff_lvls(fight_idx), 100);
                atk_fight = atk_lvls(fight_idx);
                total_fight_time = sum(fight_times);

                efr = 0;
                for idx = 1:length(fight_times)
                    stats = weapon.WeaponStats([skills;atk_fight(idx);aff_fight(idx)]);
                    efr = efr + Weapon.EVd(stats) * (fight_times(idx)/total_fight_time);
                end
                avgefr = efr;
    
                fracs = [];
                for idx = 1:length(fight_times)
                    fracs(idx) = (fight_times(idx)/total_fight_time);
                end
                if(abs(sum(fracs) - 1) >= 0.1)
                    fprintf("Sum of EFR fractions was %f, not 1\n", sum(fracs));
                    assert(abs(sum(fracs) - 1) >= 0.1, "ERROR, fight time fractions wrong");
                end
                
            end

%             if avgefr > 0
%             fprintf("Lvl %d Atk, Lvl %d Exp, Lvl %d Crit, %d base aff, %d baseatk -- EFR: %.2f; norm EFR: %.2f\n",...
%                 skills(1), skills(2), skills(3), weapon.m_baseaffinity, weapon.m_baseattack, avgefr, ...
%                 Weapon.EVd(weapon.WeaponStats([skills;0;0])));
%             end
        end
    end %%% End Method definitions

    methods(Static)
        function v = SimulatedCombatAttackBuff(t, duration, buffopts)
            % [Max Might bool; Latent Power 5 bool; Black Eclipse 1 bool]
            % You also get a small raw boost during frenzy that is replaced
            % by Black Eclipse proccing but I have not profiled that yet
            beclipsebuffp1 = [0 0 10];
            beclipsebuffp2 = [0 0 15];
            buffopts = buffopts + 1;
%             v = max(beclipsebuffp2(buffopts(4)) * HuntProfile.BlackEclipseSim(t + 10), ...
%                 beclipsebuffp1(buffopts(4))) ...
%               .* HuntProfile.SimulatedCombatPeriods(t, duration);
            v = max(beclipsebuffp2(buffopts(4)) * HuntProfile.BlackEclipse(t + 10), ...
                beclipsebuffp1(buffopts(4))) ...
              .* HuntProfile.ActuallyFighting(t);
        end

        function v = SimulatedCombatAffinityBuff(t, duration, buffopts)
        % [Max Might Level; Latent Power Level; AntiVirus Level; Black Eclipse Level]
            maxmightbuff = [0, 10, 20, 30];
            latentpowerbuff = [0, 10, 20, 30, 40, 50];
            antivirusbuff = [0, 3, 6, 10];
            beclipsebuff = [0, 15, 15];

            buffopts = buffopts + 1;
%          v = ((antivirusbuff(buffopts(3)) * HuntProfile.BlackEclipseSim(t + 10) + ...
%             latentpowerbuff(buffopts(2)) * HuntProfile.LatentPowerSim(t + 142) + ...
%             beclipsebuff(buffopts(4)) * HuntProfile.BlackEclipseSim(t + 10) + ...
%             maxmightbuff(buffopts(1)) * HuntProfile.MaximumMightSim(t))) .* HuntProfile.SimulatedCombatPeriods(t, duration);
         v = ((antivirusbuff(buffopts(3)) * HuntProfile.BlackEclipse(t + 10) + ...
            latentpowerbuff(buffopts(2)) * HuntProfile.LatentPower(t + 142) + ...
            beclipsebuff(buffopts(4)) * HuntProfile.BlackEclipse(t + 10) + ...
            maxmightbuff(buffopts(1)) * HuntProfile.MaximumMight(t))) .* HuntProfile.ActuallyFighting(t);
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
        
        function val = ProfiledCombatAffinityBuff(t)
            % Data taken from an Arkveld fight of mine lasting 490 s
        val = (15 * HuntProfile.BlackEclipse(t) + ...
            50 * HuntProfile.LatentPower(t) + ...
            30 * HuntProfile.MaximumMight(t)).*HuntProfile.ActuallyFighting(t);
         
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
    end %%% End Method definitions %%%
end %%% End class definition %%%