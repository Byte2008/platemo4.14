classdef Q_Learning < ALGORITHM
%Q_LEARNING - Q-Learning algorithm for single-objective optimization
%
%   This class implements a Q-Learning algorithm for single-objective optimization.
%   Q-Learning is a model-free reinforcement learning algorithm that learns to
%   make optimal decisions by interacting with an environment.
%
% Q_Learning properties:
%   parameter       <cell>      parameters of the algorithm
%   save            <scalar>    number of populations saved in an execution i.e., execution
%   run             <scalar>    current execution number
%   metName         <string>  	Names of metrics to calculate
%   outputFcn       <function>	function called after each generation
%   pro             <class>     problem solved in current execution
%   result          <cell>      populations saved in current execution
%   metric          <struct>    metric values of current populations
%   starttime       <scalar>	Used for runtime recording
%
% Q_Learning methods:
%   Q_Learning      <public>    the constructor setting all the properties specified by user
%   main            <public>	the main function of the algorithm

%------------------------------- Copyright --------------------------------
% Copyright (c) 2026 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    methods
        function obj = Q_Learning(varargin)
        %Q_Learning - The constructor of Q_Learning.
        %
        %   Alg = Q_Learning('Name',Value,'Name',Value,...) generates an
        %   object with the properties specified by the inputs.
        %
        %   Example:
        %        Algorithm = Q_Learning('parameter',{alpha, gamma, epsilon, n_actions, state_dim},'save',1)

            obj = obj@ALGORITHM(varargin{:});
        end
        
        function main(obj,Problem)
        %main - The main function of the Q-Learning algorithm.
        %
        %   obj.main(Problem) runs the Q-Learning algorithm to solve the given problem.
        %
        %   Input:
        %       Problem - the problem to solve, which is a PROBLEM object
        %
        %   Output:
        %       None
        
            % Get algorithm parameters
            [alpha, gamma, epsilon, n_actions, state_dim] = obj.ParameterSet(0.1, 0.9, 0.1, 10, Problem.D);
            
            % alpha: Learning rate (0-1), controls how much new information overrides old information
            % gamma: Discount factor (0-1), controls the importance of future rewards
            % epsilon: Exploration rate (0-1), probability of taking a random action
            % n_actions: Number of possible actions per state
            % state_dim: Dimensionality of the state space (equal to problem dimension)
            
            % Initialize Q-table (state-action values)
            % Note: For continuous state spaces, we use a discretization approach
            % In practice, you might want to use function approximation (e.g., neural networks)
            n_state_bins = 10; % 将连续的搜索空间转换为离散的状态空间，定义每个维度的状态离散化 bins 数量为10
            state_bins = cell(1, state_dim);%创建一个单元格数组，用于存储每个维度的离散化边界
            for i = 1:state_dim
                %使用 linspace 函数在每个维度的上下界之间生成均匀分布的 bin 边界
                state_bins{i} = linspace(Problem.lower(i), Problem.upper(i), n_state_bins);
            end
            
            % Calculate total number of possible states after discretization
            n_states = n_state_bins ^ state_dim;
            Q_table = zeros(n_states, n_actions); % Initialize Q-table with zeros
            
            % Initialize current state
            current_state = Problem.Initialization();
            current_state_discrete = discretize_state(current_state, state_bins);
            
            % Main Q-Learning loop
            while obj.NotTerminated(current_state)
                % Choose action using epsilon-greedy policy
                if rand < epsilon
                    % Exploration: select random action
                    action = randi(n_actions);
                else
                    % Exploitation: select action with highest Q-value
                    [~, action] = max(Q_table(current_state_discrete, :));
                end
                
                % Apply action to get next state
                next_state = apply_action(current_state, action, Problem.lower, Problem.upper);
                
                % Evaluate the next state
                next_state_fitness = Problem.Evaluation(next_state);
                
                % Discretize next state
                next_state_discrete = discretize_state(next_state, state_bins);
                
                % Calculate reward
                % For single-objective optimization, reward is negative fitness (since we want to minimize)
                reward = -next_state_fitness;
                
                % Update Q-value using Q-learning update rule
                best_next_action_value = max(Q_table(next_state_discrete, :));
                Q_table(current_state_discrete, action) = Q_table(current_state_discrete, action) + ...
                    alpha * (reward + gamma * best_next_action_value - Q_table(current_state_discrete, action));
                
                % Move to next state
                current_state = next_state;
                current_state_discrete = next_state_discrete;
                
                % Update function evaluation count
                Problem.FE = Problem.FE + 1;
            end
        end
    end
end

function discrete_state = discretize_state(state, state_bins)
%discretize_state - Discretize a continuous state into a discrete state index
%
%   discrete_state = discretize_state(state, state_bins)
%   
%   Input:
%       state - Continuous state vector
%       state_bins - Cell array of bin edges for each dimension
%   
%   Output:
%       discrete_state - Discrete state index
    
    n_dim = length(state);
    n_bins = length(state_bins{1});
    discrete_state = 0;
    
    for i = 1:n_dim
        % Find the bin index for each dimension
        [~, bin_idx] = histc(state(i), state_bins{i});
        % Ensure bin index is within valid range
        bin_idx = max(1, min(bin_idx, n_bins - 1));
        % Calculate the discrete state index (row-major order)
        discrete_state = discrete_state + (bin_idx - 1) * (n_bins - 1)^(i - 1);
    end
    
    % Convert to 1-based index
    discrete_state = discrete_state + 1;
end

function next_state = apply_action(state, action, lower, upper)
%apply_action - Apply an action to the current state
%
%   next_state = apply_action(state, action, lower, upper)
%   
%   Input:
%       state - Current state vector
%       action - Action index (1 to n_actions)
%       lower - Lower bounds of the search space
%       upper - Upper bounds of the search space
%   
%   Output:
%       next_state - New state after applying the action
    
    n_dim = length(state);
    step_size = 0.1 * (upper - lower); % Step size for actions
    
    % Define possible actions (directions)
    % For simplicity, we use actions that move in each dimension
    % and a no-op action
    action_directions = zeros(n_dim + 1, n_dim);
    for i = 1:n_dim
        action_directions(i, i) = 1;      % Move positive in dimension i
        action_directions(i + n_dim, i) = -1; % Move negative in dimension i
    end
    
    % Handle case where n_actions is less than 2*n_dim + 1
    if action <= size(action_directions, 1)
        direction = action_directions(action, :);
    else
        % For extra actions, use random directions
        direction = 2 * rand(1, n_dim) - 1;
        direction = direction / norm(direction);
    end
    
    % Apply the action
    next_state = state + step_size .* direction;
    
    % Clip to search space boundaries
    next_state = max(next_state, lower);
    next_state = min(next_state, upper);
end
