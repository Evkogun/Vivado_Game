% COE Superimposition Script with Debugging
% File paths
map_coe_file = 'New_Background.coe'; % Map COE file (radix=16)
collision_coe_file = 'collision_data_cropped.coe'; % Collision COE file (radix=2)
output_image = 'map_with_collision_overlay_1.png'; % Output file

% Step 1: Load Map COE File
fprintf('Loading Map COE file: %s\n', map_coe_file);
map_data = load_coe_file(map_coe_file, 16);

% Define map dimensions
map_width = 720; % Map width in pixels
map_height = length(map_data) / map_width;

if mod(length(map_data), map_width) ~= 0
    error('Map data dimensions do not align with specified map width.');
end

fprintf('Map Dimensions: %dx%d\n', map_width, map_height);

% Reshape map data
map_image = reshape(map_data, [map_width, map_height])';
map_image_normalized = uint8(255 * mat2gray(map_image)); % Normalize for grayscale

% Convert map to 3-channel RGB
map_image_rgb = cat(3, map_image_normalized, map_image_normalized, map_image_normalized);

% Step 2: Load Collision COE File
fprintf('Loading Collision COE file: %s\n', collision_coe_file);
collision_data = load_coe_file(collision_coe_file, 2);

% Define collision map dimensions
collision_width = 45; % Collision grid width
collision_height = length(collision_data) / collision_width;

if mod(length(collision_data), collision_width) ~= 0
    error('Collision data dimensions do not align with specified width.');
end

fprintf('Collision Map Dimensions: %dx%d\n', collision_width, collision_height);

% Reshape collision data
collision_map = reshape(collision_data, [collision_width, collision_height])';

% Step 3: Resize Collision Map
fprintf('Resizing collision map to match map dimensions...\n');
collision_resized = imresize(collision_map, [map_height, map_width], 'nearest');

% Validate size of resized collision map
[resized_height, resized_width] = size(collision_resized);
fprintf('Resized Collision Map Dimensions: %dx%d\n', resized_width, resized_height);

if resized_height ~= map_height || resized_width ~= map_width
    warning('Resized collision map dimensions do not exactly match map dimensions. Adjusting...');
    collision_resized = collision_resized(1:min(map_height, resized_height), 1:min(map_width, resized_width));
    collision_resized(map_height, map_width) = 0; % Pad with zeros if smaller
end

% Step 4: Superimpose Collision Data
fprintf('Superimposing collision data on the map...\n');

% Create an overlay where unwalkable areas are highlighted in red
overlay_red = map_image_rgb; % Start with the original map
overlay_red(repmat(collision_resized == 1, [1, 1, 3])) = 0; % Set red channel to 0
overlay_red(:, :, 1) = overlay_red(:, :, 1) + uint8(collision_resized) * 255; % Add red highlights

% Step 5: Save and Display the Image
imshow(overlay_red);
title('Map with Collision Overlay');
imwrite(overlay_red, output_image);
fprintf('Overlay image saved to: %s\n', output_image);

%% Function to Load COE File
function data = load_coe_file(filename, radix)
    fileID = fopen(filename, 'r');
    if fileID == -1
        error('Could not open the COE file.');
    end

    % Parse COE file
    data_section = false;
    data = [];
    while ~feof(fileID)
        line = strtrim(fgetl(fileID));
        if contains(line, 'memory_initialization_vector')
            data_section = true;
            continue;
        end
        if data_section
            line = erase(line, ';');
            line = strrep(line, ',', ' ');
            if radix == 2
                values = sscanf(line, '%1d');
            elseif radix == 16
                values = sscanf(line, '%x');
            end
            data = [data; values];
        end
    end
    fclose(fileID);
end
