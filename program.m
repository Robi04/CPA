% Load the input data, SubBytes table, and power consumption traces
inputs = load('inputs.mat').Inputs1; % Replace 'inputs.mat' with your actual input file name
subBytes = load('subBytes.mat').SubBytes; % Replace 'subBytes.mat' with your actual SubBytes file name
traces = load('traces1000x512.mat').traces; % Replace 'traces.mat' with your actual traces file name


% Initialize variables
num_traces = size(traces, 1);
num_time_samples = size(traces, 2);
num_keys = 256; % Possible values for a 1-byte sub-key
P = zeros(num_traces, num_keys); % Hamming weight estimation matrix

% Assuming the key is 1 byte and we're only looking at the least significant byte of each block
for k = 0:num_keys-1
    for i = 1:num_traces
        % Ensure the input is an integer before the XOR operation
        input_byte = uint8(inputs(i));  % Convert to unsigned 8-bit integer
        
        % Perform AddRoundKey (XOR with the key)
        roundKeyOutput = bitxor(input_byte, uint8(k));
        
        % Perform SubBytes operation
        subByteOutput = subBytes(roundKeyOutput+1); % MATLAB uses 1-indexing
        
        % Estimate the Hamming weight of the SubBytes output
        P(i, k+1) = sum(dec2bin(subByteOutput, 8) == '1');  % Ensure 8-bit representation
    end
end


% Calculate correlation
correlation_matrix = zeros(num_keys, num_time_samples);
for k = 1:num_keys
    for t = 1:num_time_samples
        R = corrcoef(P(:, k), traces(:, t));
        correlation_matrix(k, t) = R(1, 2);  % Use the off-diagonal element
    end
end

% Find the key with the maximum correlation
[~, max_key_index] = max(max(correlation_matrix, [], 2));

% Plotting 2D correlation
plot(correlation_matrix(max_key_index, :));
% title('2D Correlation Plot');
% xlabel('Time Sample');
% ylabel('Correlation');

% Plotting 3D correlation
 surf(correlation_matrix);
 title('3D Correlation Surface');
 xlabel('Time Sample');
 ylabel('Key');
 zlabel('Correlation');

% The key with the highest correlation is the most likely correct key byte
likely_key_byte = max_key_index - 1;
likely_key_byte;
