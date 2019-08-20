classdef RandomSampler < ImageSampler
%RANDOMPOSITIONSSAMPLER Sample random positions within image.
%
%   Sample random positions within image. Positions correspond to exact
%   positions of elements in physical space.
%
%   Example
%   RandomSampler
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2011-07-20,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.

%% Properties
properties
    % the base image
    Image;
    
    % number of points to generate
    NPoints;
    
    % generated points
    Points;
end


%% Static factory
methods (Static = true)
    function sampler = create(image, n)
        sampler = RandomSampler(image, n);
    end
end


%% Constructor
methods
    function obj = RandomSampler(varargin)
        
        if nargin < 1
            return;
        end
        
        var = varargin{1};
        if isa(var, 'Image')
            % initialisation constructor
            obj.Image = var;
            obj.NPoints = varargin{2};
            updatePoints(obj);
            
        elseif isa(var, 'RandomSampler')
            % copy constructor
            obj.Image   = var.Image;
            obj.NPoints = var.NPoints;
            obj.Points  = var.Points;
            
        end
        
    end
end


%% General methods
methods
    function n = positionNumber(obj)
        % Number of positions generated by obj sampler
        n = obj.NPoints;
    end
    
    function points = positions(obj)
        % Return the array of sampled positions
        
        points = obj.Points;
    end
    
    function updatePoints(obj)
        
        N = obj.NPoints;
        
        dim = size(obj.Image);
        sp = obj.Image.Spacing;
        or = obj.Image.Origin;
        
        % compute point coordinates
        nd = ndims(obj.Image);
        if nd == 2
            % 2D images
            obj.Points = [...
                floor(rand(N, 1)*dim(1)) * sp(1) + or(1) , ...
                floor(rand(N, 1)*dim(2)) * sp(2) + or(2) ];
            
        elseif nd == 3
            % 3D images
            obj.Points = [...
                floor(rand(N, 1)*dim(1)) * sp(1) + or(1) , ...
                floor(rand(N, 1)*dim(2)) * sp(2) + or(2) , ...
                floor(rand(N, 1)*dim(3)) * sp(3) + or(3) , ...
                ];
            
        else
            error(['Not implemented for dimension ' num2str(nd)]);
        end
        
    end
end

end