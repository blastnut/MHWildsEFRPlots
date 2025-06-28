gemcombination = [3 0 3];
slots = [0;0;2];
skills = [5;0;1];

gemcomb = sort(gemcombination);
combidx = 1;
foundidx = 1;

while combidx <= 3
    if(gemcomb(combidx) > 0)
        foundidx = findminslot(slots, gemcomb(combidx));
        if ~isempty(foundidx)
            % Have a slot available for this gem level; now use it to
            % remove it
            gemcomb(combidx) = gemcomb(combidx) - foundidx;
            slots(foundidx) = slots(foundidx) - 1;
        end
    end
    combidx = combidx + 1;
end

bIsCombValid = sum(gemcomb > 0) <= 0
gemcomb

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
                        bValid = true
                        "Valid skills"
                    else
                        "Invalid skills"
                    end
   else
       "Combination invalid"
   end


    function retval = findminslot(v, value)
        for idx = value:length(v)
            if(idx >= value && v(idx) > 0)
                retval = idx;
                return;
            end
        end
        retval = [];
    end
    

    function [bValid] = IsGemConfigValid(slots)
        bValid = false;
    
        G1 = sum(G == 1);
        G2 = sum(G == 2);
        G3 = sum(G == 3);
        S1 = slots(1);
        S2 = slots(2);
        S3 = slots(3);
       
        G1p = max(G1 - S1, 0);
        G1pp = max(G1p - S2, 0);
        G1ppp = max(G1pp - S3, 0);

        if G1ppp ~= 0
            return;
        end

        S2p = S2 - G1p;
        G2p = max(G2 - S2p, 0);
        S3p = S3 - G1pp;
        G2pp = max(g2p - S3p, 0);

        if G2pp ~= 0
            return;
        end

        S3pp = S3p - G2p;
        G3p = max(G3 - S3pp, 0);

        if G3p ~= 0
            return;
        end

        bValid = true;
        end