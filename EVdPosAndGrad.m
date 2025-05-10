function [f, grad] = EVdPosAndGrad(v)
%EVDPOSANDGRAD Summary of this function goes here
%   Detailed explanation goes here
R = v(1);
A = v(2);
C = v(3);

f = EVdPos(v);
grad = [(C*R)/10000;
(A*R)/10000;
(A*C)/10000 + 1];
end

