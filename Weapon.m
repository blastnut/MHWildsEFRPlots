classdef Weapon
    properties
        m_baseattack;
        m_baseaffinity;
        m_basecrit;
        m_nSlots;
    end
    
    methods
        function obj = Weapon(baseattack, baseaffinity, nSlots)
            obj.m_baseattack = baseattack;
            obj.m_baseaffinity = baseaffinity;
            obj.m_nSlots = nSlots;
            obj.m_basecrit = 25;
        end

        function [stats] = WeaponStats(obj, v)
            attacklevel = v(1);
            explevel = v(2);
            critlevel = v(3);
            buffatkboost = v(4); % Boosts off the weapon come after gems
            buffaffboost = v(5);
            
            validmultiple = obj.IsSkillComboPossible(obj.m_nSlots, v(1:3));
            
            atkboost = AttackBoost(attacklevel, obj.m_baseattack);
            affinityboost = AffinityBoost(explevel);
            critboost = CritBoost(critlevel);
            
            stats = validmultiple * ...
                [atkboost + obj.m_baseattack + buffatkboost; ...
                min(100, obj.m_baseaffinity + affinityboost + buffaffboost);...
                critboost + obj.m_basecrit];
        
        end
    
        function [bValid] = IsSkillComboPossible(obj, weapon_gem_slots, skills)
            % weapon_slots = [lvl1 lvl2 lvl3]
            % skills = [Attack Lvl, Expert Lvl, Crit Boost Lvl];
            
            % Brute force. Short explanation for why this function is even necessary:
            % By using skill levels rather than gems, it reduces the dimension from 9 to 3
            % which makes the information easier to plot; however, this complicates
            % detecting whether or not a combination of skills is possible in a
            % particular slot configuration
            
            bValid = false;
            
            persistent A B C combos dim
            
            if isempty(dim)
                dim = [3;3;3]; %Because of how we do this, only 3 total gems are ever allowed
                [A, B, C] = ndgrid(0:dim(1), 0:dim(2), 0:dim(3));
                combos = [A(:), B(:), C(:)];
            end
            
            for idx = 1:length(combos)
                % Copy the weapon gem combination to subtract from
                % By subtracting the available weapon slot levels, we
                % can figure out if the weapon has enough to fit
    
                %  This can be replaced later by something more efficient
    
                gemcombination = combos(idx,:);
                combsum = sum(gemcombination);
                weapslotsum = sum(weapon_gem_slots .* [1;2;3]);
                if combsum <= weapslotsum
            
                    gemcomb = gemcombination;
                    slots = weapon_gem_slots;
                    combidx = 1;
            
                    gemcomb = sort(gemcomb);
            
                    while combidx <= 3
                        if(gemcomb(combidx) > 0)
                            foundidx = obj.findminslot(slots, gemcomb(combidx));
                            if ~isempty(foundidx)
                                % Have a slot available for this gem level; now use it to
                                % remove it
                                gemcomb(combidx) = gemcomb(combidx) - foundidx;
                                slots(foundidx) = slots(foundidx) - 1;
                            end
                        end
                        combidx = combidx + 1;
                    end
            
                    bIsCombValid = sum(gemcomb > 0) <= 0;
            
                    if bIsCombValid
                        % A gem combination which meets the above condition could
                        % fit in the weapon's available gem slots
            
                        % We need to check if the combination can meet or
                        % exceed the skill levels requested while requiring
                        % that each gem of the combination only be used for one
                        % skill
                        skcopy = skills;
                        skidx = 1;
                        combidx = 1;
                        while skidx <= 3 && combidx <= 3
                            if skcopy(skidx) == 0
                                skidx = skidx + 1;
                                continue;
                            end
                            skcopy(skidx) = skcopy(skidx) - gemcombination(combidx);
                            combidx = combidx + 1;
                            if(skcopy(skidx) <= 0)
                                skidx = skidx + 1;
                            end
                        end
            
                        if sum(skcopy > 0) == 0
                            bValid = true;
                            return;
                        end
            
                    end
            
                end
            end
        end
        
        function retval = findminslot(obj, v, value)
            for idx = value:length(v)
                if(idx >= value && v(idx) > 0)
                    retval = idx;
                    return;
                end
            end
            retval = [];
        end
        
        function [result] = UnitStep(x)
            % Matlab defines heaviside(0) to be 0.5, which is a perfectly sensible
            % perversion. It can be changed globally but I'd rather not screw around
            % with a user's settings
            result = (x >= 0);
        end
        
        function [boost] = AttackBoost(lvl, attack)
            nLvl = floor(lvl);
            atk = floor(attack);
            boost = ...
                (9+  0.04*atk)*UnitStep(nLvl - 5) + ...
                (8 + 0.02*atk)*(UnitStep(nLvl - 4) - UnitStep(nLvl - 5)) + ...
                7*(UnitStep(nLvl - 3) - UnitStep(nLvl - 4)) + ...
                5*(UnitStep(nLvl - 2) - UnitStep(nLvl - 3)) + ...
                3*(UnitStep(nLvl - 1) - UnitStep(nLvl - 2));
        end
        
        function [critboost] = CritBoost(lvl)
            nLvl = floor(lvl);
            critboost = ((nLvl) * 3) * (UnitStep(nLvl - 1) - UnitStep(nLvl - 6)) ...
                + 15*UnitStep(nLvl - 6);
        end
        
        function [affboost] = AffinityBoost(lvl)
            nLvl = floor(lvl);
            affboost = (nLvl * 4) * (UnitStep(nLvl - 1) - UnitStep(nLvl - 6)) ...
                + 20*UnitStep(nLvl - 6);
        end
    
    end %%% End method definitions %%%

end %%% End class definition%%%

