% Test script for OOA algorithm on PlatEMO platform
% This script tests the OOA implementation on benchmark functions

clear; clc;

fprintf('=== Testing OOA Algorithm on PlatEMO Platform ===\n\n');

%% Test 1: Simple Sphere function (unimodal)
fprintf('Test 1: Sphere function (SOP_F1, D=10, N=30, maxFE=10000)\n');
try
    platemo('algorithm',@OOA,'problem',@SOP_F1,'N',30,'maxFE',10000,'D',10);
    fprintf('✓ Sphere test passed\n\n');
catch ME
    fprintf('✗ Sphere test failed: %s\n\n', ME.message);
end

%% Test 2: Rastrigin function (multimodal)
fprintf('Test 2: Rastrigin function (SOP_F9, D=10, N=50, maxFE=20000)\n');
try
    platemo('algorithm',@OOA,'problem',@SOP_F9,'N',50,'maxFE',20000,'D',10);
    fprintf('✓ Rastrigin test passed\n\n');
catch ME
    fprintf('✗ Rastrigin test failed: %s\n\n', ME.message);
end

%% Test 3: Rosenbrock function (valley-shaped)
fprintf('Test 3: Rosenbrock function (SOP_F5, D=10, N=50, maxFE=20000)\n');
try
    platemo('algorithm',@OOA,'problem',@SOP_F5,'N',50,'maxFE',20000,'D',10);
    fprintf('✓ Rosenbrock test passed\n\n');
catch ME
    fprintf('✗ Rosenbrock test failed: %s\n\n', ME.message);
end

%% Test 4: Ackley function (multimodal)
fprintf('Test 4: Ackley function (SOP_F10, D=10, N=50, maxFE=20000)\n');
try
    platemo('algorithm',@OOA,'problem',@SOP_F10,'N',50,'maxFE',20000,'D',10);
    fprintf('✓ Ackley test passed\n\n');
catch ME
    fprintf('✗ Ackley test failed: %s\n\n', ME.message);
end

%% Test 5: High-dimensional problem
fprintf('Test 5: Sphere function (SOP_F1, D=50, N=100, maxFE=50000)\n');
try
    platemo('algorithm',@OOA,'problem',@SOP_F1,'N',100,'maxFE',50000,'D',50);
    fprintf('✓ High-dimensional test passed\n\n');
catch ME
    fprintf('✗ High-dimensional test failed: %s\n\n', ME.message);
end

fprintf('=== All tests completed ===\n');
fprintf('\nTo run OOA manually, use:\n');
fprintf('  platemo(''algorithm'',@OOA,''problem'',@SOP_F1,''N'',30,''maxFE'',10000)\n');
fprintf('\nNote: PlatEMO uses SOP_F1 for Sphere, SOP_F9 for Rastrigin, etc.\n');
