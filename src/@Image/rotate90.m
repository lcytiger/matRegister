function res = rotate90(this, axis, varargin)
%ROTATE90 Rotate an image by 90 degrees around one of the main axes
%
%   ROTATED = rotate90(IMG, NDIR)
%   Rotate the 2D image by 90 degrees:
%   - in counter-clockwise direction in the spatial (O,x,y) basis.
%   - in clockwise direction in the matrix (O,i,j) basis.
%
%   If NDIR is 1, the x-axis becomes the y-axis, and the y-axis is flipped
%       and becomes the new x-axis.
%   If NDIR is 2, both the x-axis and the y-axis are flipped
%   If NDIR is 3, the x-axis is flipped and becomes the y-axis, the y-axis
%       becomes the x-axis.
%
%   ROTATED = rotate90(IMG, AXIS)
%   Rotate the 3D image IMG by 90 degrees around the axis specified by
%   AXIS. AXIS is either the axis index (between 1 and ND), or the axis
%   name 'x', 'y' or 'z'. 
%
%   ROTATED = rotate90(IMG, AXIS, NUMBER)
%   Apply NUMBER rotation around the axis. NUMBER is the number of
%   rotations to apply, between 1 and 3. NUMER can also be negative, in
%   this case the rotation is performed in reverse direction.
%
%
%   Example
%     % show rotated gray-scale image
%     img = Image.read('cameraman.tif');
%     subplot(121);img.show();
%     subplot(122);show(rotate90(img));
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2010-10-13,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRA - Cepia Software Platform.

% extract input arguments (number of rotations and axis)
nd = getDimension(this);
if nd == 2
    % number of rotations
    n = 1;
    if nargin>1
        n = axis;
    end
    
    % consider the 2D image as a 3D image, rotated around the z-axis
    axis = 3;

elseif nd == 3
    % parse axis, and check bounds
    axis = Image.parseAxisIndex(axis);
    
    % positive or negative rotation
    n = 1;
    if ~isempty(varargin)
        n = varargin{1};
    end
    
end

% ensure n is between 0 (no rotation) and 3 (rotation in inverse direction)
n = mod(n, 4);

% default values
imInds = [1 2 3];
permDim = [];

% compute indices for rotation
switch axis
    case 1
        % Rotate around X axis
        if n==1
            imInds = [1 3 2];
            permDim = 2;
        elseif n==2
            permDim = [2 3];
        elseif n==3
            imInds = [1 3 2];
            permDim = 3;
        end
        
    case 2
        % Rotate around Y axis
        if n==1
            imInds = [3 2 1];
            permDim = 3;
        elseif n==2
            permDim = [1 3];
        elseif n==3
            imInds = [3 2 1];
            permDim = 1;
        end
        
    case 3
        % Rotate around Z axis
        if n==1
            imInds = [2 1 3];
            permDim = 1;
        elseif n==2
            permDim = [1 2];
        elseif n==3
            imInds = [2 1 3];
            permDim = 2;
        end        
end

% add non spatial dimensions
imInds = [imInds 4 5];

% apply matrix dimension permutation
newData = permute(this.data, imInds);

% depending on rotation, some dimensions must be fliped
for i=1:length(permDim)
    newData = flipdim(newData, permDim(i));
end

% create the new result image
res = Image(nd, 'data', newData, 'parent', this);

% also permute spacing and origin of image
calib = permute(this.getSpatialCalibration(), imInds(1:nd));
res.setSpatialCalibration(calib);

