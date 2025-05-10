function [stats] = WeaponStats(v)
% #Atk + #Expert + #Crit <= 3
baseattack = v(1);
baseaffinity = v(2);
basecrit = 25;
nSlots = v(3:5);

attacklevel = v(6);
explevel = v(7);
critlevel = v(8);
% nAttackGems = v(6:8);%[0;1;1];
% nExpertGems =v(9:11); %[0;1;1];
% nCritGems = v(12:14);%[0;1;1];

validmultiple = IsSkillComboPossible(nSlots, v(6:8));

atkboost = AttackBoost(attacklevel, baseattack);
affinityboost = AffinityBoost(explevel);
critboost = CritBoost(critlevel);

stats = validmultiple * [atkboost + baseattack;min(100,baseaffinity + affinityboost);critboost + basecrit];

end


function [valid] = IsSkillComboPossible(weapon_gem_slots, skills)
    % weapon_slots = [lvl1 lvl2 lvl3]
    % skills = [Attack Lvl, Expert Lvl, Crit Boost Lvl];
    % Brute force. Short explanation for why this function is even necessary:
    % By using skill levels rather than gems, it reduces the dimension from 9 to 3
    valid = false;
    
    persistent A B C combos dim
    
    if isempty(dim)
        dim = [3;3;3];
        [A, B, C] = ndgrid(0:dim(1), 0:dim(2), 0:dim(3));
        combos = [A(:), B(:), C(:)];
    end
    
    for idx = 1:length(combos)
        gemcombination = combos(idx,:);
        combsum = sum(gemcombination);
        if combsum <= sum(weapon_gem_slots .* [1;2;3])
        
            if sum(gemcombination == 3) <= weapon_gem_slots(3) && ...
                sum(gemcombination == 2) <= weapon_gem_slots(2) + weapon_gem_slots(3) && ...
                sum(gemcombination == 1) <= sum(weapon_gem_slots)
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
                        valid = true;
                        return;
                    end

            end
        
        end
    end
end