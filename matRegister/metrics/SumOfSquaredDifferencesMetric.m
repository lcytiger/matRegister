classdef SumOfSquaredDifferencesMetric < ImageToImageMetric
%SumOfSquaredDifferencesMetric Compute sum of squared differences metric
%
%   output = SumOfSquaredDifferencesMetric(input)
%
%   Example
%   SumOfSquaredDifferencesMetric
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2010-08-12,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRA - Cepia Software Platform.

%% Some properties specific to the SSD metric
properties
    % the transform model (necessary to compute the metric gradient)
    Transform;
    
    % The gradient image of the moving image (necessary to compute the metric gradient)
    GradientImage;
end

%% Constructor
methods
    function obj = SumOfSquaredDifferencesMetric(varargin)
        % calls the parent constructor
        obj = obj@ImageToImageMetric(varargin{:});
        
    end % constructor
    
end % methods

%% Accessors and modifiers
methods
    function transform = getTransform(obj)
        transform = obj.Transform;
    end
    
    function setTransform(obj, transform)
        obj.Transform = transform;
    end
    
    function gradient = getGradientImage(obj)
        gradient = obj.GradientImage;
    end
    
    function setGradientImage(obj, gradient)
        obj.GradientImage = gradient ;
    end 
        
end % methods

methods
    function [res, isInside] = computeValue(obj)
        % Compute metric value.
        %
        % [VALUE, INSIDE] = computeValue(METRIC);
        % Computes and return the value. Returns also a flag that indicates
        % which test points belong to both images.
        %
        
        % compute values in image 1
        [values1, inside1] = evaluate(obj.Img1, obj.Points);
        
        % compute values in image 2
        [values2, inside2] = evaluate(obj.Img2, obj.Points);
        
        % keep only valid values
        isInside = inside1 & inside2;
        
        % compute result
        % diff = (values1(isInside) - values2(isInside)).^2;
        % res = sum(diff);
        diff = (values1 - values2).^2;
        res = sum(diff);
    end
    
    function [res, grad, isInside] = computeValueAndGradient(obj, varargin)
        % Compute metric value and gradient.
        %
        %   [RES, DERIV] = computeValueAndGradient(METRIC);
        %   This syntax requires that both fields 'Transform' and 'GradientImage'
        %   have been initialized.
        %
        %   [RES, DERIV] = obj.computeValueAndGradient(TRANSFO, GRADX, GRADY);
        %   [RES, DERIV] = obj.computeValueAndGradient(TRANSFO, GRADX, GRADY, GRADZ);
        %   This (deprecated) syntax passes transform model and gradient components
        %   as input arguments.
        %
        % Example:
        %   transfo = Translation2DModel([1.2 2.3]);
        %   metric = SumOfSquaredDifferencesMetric(img1, img2, points);
        %   metric.Transform = transfo;
        %   metric.GradientImage = gradient(img2);
        %   ssd = metric.computeValueAndGradient();
        %
        
        if ~isempty(obj.Transform) && ~isempty(obj.GradientImage)
            nd = ndims(obj.Img1);
            if nd == 2
                [res, grad, isInside] = computeValueAndGradientLocal2d(obj);
            elseif nd == 3
                [res, grad, isInside] = computeValueAndGradientLocal3d(obj);
            else
                [res, grad, isInside] = computeValueAndGradientLocal(obj);
            end
        else
            % deprecation warning
            warning('matRegister:deprecated', ...
                'Deprecated syntax. Please initialize metric "transform" and "gradientImage" fields instead');
            
            % assumes transform and gradient components are given as arguments
            nd = ndims(obj.Img1);
            if nd == 2
                [res, grad, isInside] = computeValueAndGradient2d(obj, varargin{:});
            else
                [res, grad, isInside] = computeValueAndGradient3d(obj, varargin{:});
            end
        end
        
        % end of main function
        
        
        function [res, grad, isInside] = computeValueAndGradientLocal(obj)
            % Compute metric value and gradient in general case, using inner gradient
            % image
            
            % error checking
            if isempty(obj.Transform)
                error('Gradient computation requires transform');
            end
            if isempty(obj.GradientImage)
                error('Gradient computation requires a gradient image');
            end
            
            % compute values in image 1
            [values1, inside1] = evaluate(obj.Img1, obj.Points);
            
            % compute values in image 2
            [values2, inside2] = evaluate(obj.Img2, obj.Points);
            
            % keep only valid values
            isInside = inside1 & inside2;
            
            % compute result
            % diff = values2(isInside) - values1(isInside);
            diff = (values1 - values2);
            res = sum(diff.^2);
            
            %fprintf('Initial SSD: %f\n', res);
            
            % convert to indices
            inds = find(isInside);
            nbInds = length(inds);
            
            transfo = obj.Transform;
            nParams = length(getParameters(transfo));
            g = zeros(nbInds, nParams);
            
            % convert from physical coordinates to index coordinates
            points2 = transformPoint(transfo, obj.Points);
            points2 = pointToIndex(obj.GradientImage, points2);
            indices = round(points2(inds, :));
            
            for i = 1:length(inds)
                iInd = inds(i);
                
                % calcule jacobien pour points valides (repere image fixe)
                jac = parametricJacobian(transfo, obj.Points(iInd, :));
                
                % local gradient in moving image
                subs = num2cell(indices(i, :));
                grad = getPixel(obj.GradientImage, subs{:});
                
                % local contribution to metric gradient
                g(iInd,:) = grad * jac;
            end
            
            % compute gradient vector weighted by local difference between image values
            gd = g(inds,:) .* diff(inds, ones(1, nParams));
            
            % compute the sum of gradient vectors
            grad = sum(gd, 1);
        end
        
        
        function [res, grad, isInside] = computeValueAndGradientLocal2d(obj)
            % Compute metric value and gradient in 2D, using inner gradient image
            %
            % Assumes that gradient is a 2D image.
            
            % error checking
            if isempty(obj.Transform)
                error('Gradient computation requires transform');
            end
            if isempty(obj.GradientImage)
                error('Gradient computation requires a gradient image');
            end
            
            % compute values in image 1
            [values1, inside1] = evaluate(obj.Img1, obj.Points);
            
            % compute values in image 2
            [values2, inside2] = evaluate(obj.Img2, obj.Points);
            
            % keep only valid values
            isInside = inside1 & inside2;
            
            % compute result
            diff = (values2 - values1);
            res = sum(diff.^2);
            
            %fprintf('Initial SSD: %f\n', res);
            
            % convert to indices
            inds = find(isInside);
            nbInds = length(inds);
            
            transfo = obj.Transform;
            nParams = length(getParameters(transfo));
            g = zeros(nbInds, nParams);
            
            % compute transformed coordinates
            points2 = transformPoint(transfo, obj.Points);
            
            % convert from physical coordinates to index coordinates
            points2 = pointToIndex(obj.GradientImage, points2);
            indices = round(points2(inds, :));
            % (assumes spacing is 1 and origin is 0)
            % indices = round(points2(inds, :)) + 1;
            
            % gradImg = squeeze(obj.GradientImage.Data);
            gradImg = obj.GradientImage;
            
            for i = 1:length(inds)
                iInd = inds(i);
                
                % calcule jacobien pour points valides (repere image fixe)
                p0 = obj.Points(iInd, :);
                jac = parametricJacobian(transfo, p0);
                
                % local gradient in moving image
                ind1 = indices(i,1);
                ind2 = indices(i,2);
                
                grad = [gradImg(ind1, ind2, 1, 1) gradImg(ind1, ind2, 1, 2)];
                
                % local contribution to metric gradient
                g(iInd,:) = grad * jac;
            end
            
            % compute gradient vector weighted by local difference between image values
            gd = bsxfun(@times, g(inds,:), diff(inds));
            
            % compute the sum of valid gradient vectors
            grad = sum(gd, 1);
        end
        
        function [res, grad, isInside] = computeValueAndGradientLocal3d(obj)
            % Compute metric value and gradient in 3D, using inner gradient image
            %
            % Assumes that gradient is a 3D image.
            
            % error checking
            if isempty(obj.Transform)
                error('Gradient computation requires transform');
            end
            if isempty(obj.GradientImage)
                error('Gradient computation requires a gradient image');
            end
            
            % compute values in image 1
            [values1, inside1] = evaluate(obj.Img1, obj.Points);
            
            % compute values in image 2
            [values2, inside2] = evaluate(obj.Img2, obj.Points);
            
            % keep only valid values
            isInside = inside1 & inside2;
            
            % compute result
            % diff = values2(isInside) - values1(isInside);
            diff = (values2 - values1);
            res = sum(diff.^2);
            
            %fprintf('Initial SSD: %f\n', res);
            
            % convert to indices
            inds = find(isInside);
            nbInds = length(inds);
            
            transfo = obj.Transform;
            nParams = length(transfo.getParameters());
            g = zeros(nbInds, nParams);
            
            % compute transformed coordinates
            points2 = transformPoint(transfo, obj.Points);
            
            % convert from physical coordinates to index coordinates
            points2 = pointToIndex(obj.GradientImage, points2);
            indices = round(points2(inds, :));
            % (assumes spacing is 1 and origin is 0)
            % indices = round(points2(inds, :)) + 1;
            
            gradImg = obj.GradientImage.Data;
            
            for i = 1:length(inds)
                iInd = inds(i);
                
                % calcule jacobien pour points valides (repere image fixe)
                p0 = obj.Points(iInd, :);
                jac = parametricJacobian(transfo, p0);
                
                % local gradient in moving image
                ind1 = indices(i,1);
                ind2 = indices(i,2);
                ind3 = indices(i,3);
                
                grad = [...
                    gradImg(ind1, ind2, ind3, 1) ...
                    gradImg(ind1, ind2, ind3, 2) ...
                    gradImg(ind1, ind2, ind3, 3)];
                
                % local contribution to metric gradient
                g(iInd,:) = grad * jac;
            end
            
            % compute gradient vector weighted by local difference between image values
            gd = g(inds,:) .* diff(inds, ones(1, nParams));
            
            % compute the sum of gradient vectors
            grad = sum(gd, 1);
        end
        
        function [res, grad, isInside] = computeValueAndGradient2d(obj, transfo, gx, gy)
            % Compute metric value and gradient in 2D, using gradient image as parameter
            % (deprecated syntax)
            %
            
            
            % compute values in image 1
            [values1, inside1] = evaluate(obj.Img1, obj.Points);
            
            % compute values in image 2
            [values2, inside2] = evaluate(obj.Img2, obj.Points);
            
            % keep only valid values
            isInside = inside1 & inside2;
            
            % compute result
            % diff = values2(isInside) - values1(isInside);
            diff = (values1 - values2);
            res = sum(diff .^ 2);
            
            %fprintf('Initial SSD: %f\n', res);
            
            
            %% Compute gradient direction
            
            % convert to indices
            inds = find(isInside);
            nbInds = length(inds);
            
            %nPoints = size(points, 1);
            nParams = length(getParameters(transfo));
            g = zeros(nbInds, nParams);
            
            % convert from physical coordinates to index coordinates
            % (assumes spacing is 1 and origin is 0)
            % also converts from (x,y) to (i,j)
            points2 = transformPoint(transfo, obj.Points);
            index = round(points2(inds, [2 1]))+1;
            
            for i = 1:length(inds)
                % calcule jacobien pour points valides (repere image fixe)
                jac = parametricJacobian(transfo, obj.Points(inds(i),:));
                
                % local gradient in moving image
                i1 = index(i, 1);
                i2 = index(i, 2);
                grad = [gx(i1,i2) gy(i1,i2)];
                
                % local contribution to metric gradient
                g(inds(i),:) = grad*jac;
            end
            
            % compute gradient vector weighted by local difference between image values
            gd = g(inds,:) .* diff(inds, ones(1, nParams));
            
            % compute the sum of gradient vectors
            grad = sum(gd, 1);
        end
        
        function [res, grad, isInside] = computeValueAndGradient3d(obj, transfo, gx, gy, gz)
            % Compute metric value and gradient in 3D, using gradient image as parameter
            % (deprecated syntax)
            %
            
            %% Compute metric value
            
            % compute values in image 1
            [values1, inside1] = evaluate(obj.Img1, obj.Points);
            
            % compute values in image 2
            [values2, inside2] = evaluate(obj.Img2, obj.Points);
            
            % keep only valid values
            isInside = inside1 & inside2;
            
            % compute result
            % diff = values2(isInside) - values1(isInside);
            diff = (values1 - values2);
            res = sum(diff.^2);
            
            
            %% Compute gradient direction
            
            % convert to indices
            inds = find(isInside);
            nbInds = length(inds);
            
            %nPoints = size(points, 1);
            nParams = length(getParameters(transfo));
            g = zeros(nbInds, nParams);
            
            % convert from physical coordinates to index coordinates
            % (assumes spacing is 1 and origin is 0)
            % also converts from (x,y) to (i,j)
            points2 = transformPoint(transfo,obj.Points);
            index = round(points2(inds, [2 1 3]))+1;
            
            for i = 1:length(inds)
                % calcule jacobien pour points valides (repere image fixe)
                jac = parametricJacobian(transfo, obj.Points(inds(i),:));
                
                % local gradient in moving image
                i1 = index(i, 1);
                i2 = index(i, 2);
                i3 = index(i, 3);
                grad = [gx(i1,i2,i3) gy(i1,i2,i3) gz(i1,i2,i3)];
                
                % local contribution to metric gradient
                g(inds(i),:) = grad * jac;
            end
            
            % compute gradient vector weighted by local difference between image values
            gd = g(inds,:) .* diff(inds, ones(1, nParams));
            
            % compute the sum of gradient vectors
            grad = sum(gd, 1);
        end
    end
end

end % classdef
