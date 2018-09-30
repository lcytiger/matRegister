function testSuite = test_BSplineTransformModel2D(varargin)
%TEST_BSPLINETRANSFORMMODEL2D  Test case for the file BSplineTransformModel2D
%
%   Test case for the file BSplineTransformModel2D

%   Example
%   test_BSplineTransformModel2D
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2018-09-30,    using Matlab 8.6.0.267246 (R2015b)
% Copyright 2018 INRA - Cepia Software Platform.

testSuite = buildFunctionHandleTestSuite(localfunctions);

function test_Simple %#ok<*DEFNU>
% Test call of function without argument
BSplineTransformModel2D();


function test_ToStruct
% Test call of function without argument

params = [.1 .2  1.1 0.2  0.1 1.2  0.01 0.01 0.01 0.01 0.01 0.01];
transfo = BSplineTransformModel2D(params);
str = toStruct(transfo);
transfo2 = BSplineTransformModel2D.fromStruct(str);

assertTrue(isa(transfo2, 'BSplineTransformModel2D'));
assertElementsAlmostEqual(transfo2.params, transfo.params, 'absolute', .01);


function test_readWrite
% Test call of function without argument

% prepare
fileName = 'BSplineTransformModel2D.transfo';
if exist(fileName, 'file')
    delete(fileName);
end

% arrange
params = [.1 .2  1.1 0.2  0.1 1.2  0.01 0.01 0.01 0.01 0.01 0.01];
transfo = BSplineTransformModel2D(params);

% act
write(transfo, fileName);
transfo2 = Transform.read(fileName);

% assert
assertTrue(isa(transfo2, 'BSplineTransformModel2D'));
assertElementsAlmostEqual(transfo2.params, transfo.params, 'absolute', .01);

% clean up
delete(fileName);



