function test_suite = test_MatrixAffineTransform(varargin) 
%TEST_MATRIXAFFINETRANSFORM  One-line description here, please.
%   output = test_MatrixAffineTransform(input)
%
%   Example
%   test_MatrixAffineTransform
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2010-06-17,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2010 INRA - Cepia Software Platform.

test_suite = buildFunctionHandleTestSuite(localfunctions);

function testCreateFromArray(testCase) %#ok<*DEFNU>

% identity
mat1 = eye(3);
T = MatrixAffineTransform(mat1);
assertTrue(T.isvalid());

% do not specify last line
mat1 = mat1(1:end-1, :);
T = MatrixAffineTransform(mat1);
assertTrue(T.isvalid());

function test_scaling2d(testCase)

mat = [2 0 0;0 2 0;0 0 1];
transfo = MatrixAffineTransform(mat);
res = transformPoint(transfo, [1 2]);
assertElementsAlmostEqual(res, [2 4], 'absolute', .01);